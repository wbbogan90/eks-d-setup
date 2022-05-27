import os, sys, json, boto3
from typing import Tuple

USER_HOME = str(os.environ['HOME'])
AWS_PROFILE = str(os.environ['AWS_PROFILE'])
TF_BACKEND_FILE = f"{USER_HOME}/terraform/backend.tf"
SSH_HOME = f"{USER_HOME}/.ssh"
SSH_KEY_NAME = 'ec2-user-ssh'
SSH_SECRET_NAME = 'deo-eks-d-ssh'
TF_BUCKET_NAME = 'deo-eks-d-tf'
TF_TABLE_NAME = 'deo-eks-d-state-locking'
PRIVATE_KEY = 'private'
PUBLIC_KEY = 'public'

BACKEND_SETTINGS = '''
provider "aws" [
    region = "{}"
    profile = "{}"
]

terraform [
    backend "s3" [
        bucket = "{}"
        key = "terraform.tfstate"
        region = "{}"
        dynamodb_table = "{}"
    ]
]
'''

class Setup:
  def __init__(self, region:str, kms_key_arn:str):
    self.region = region
    self.secretsmgr = boto3.client('secretsmanager', region_name=region)
    self.s3 = boto3.client('s3', region_name=region)
    self.dynamo = boto3.client('dynamodb', region_name=region)
    self.kms_key_arn = kms_key_arn
    
  def _remove_file(self, filename:str) -> None:
    try:
      os.remove(filename)
    except FileNotFoundError:
      pass
  
  def _parse_private_key(self, private_key:str) -> str:
    parsed_key = private_key.replace(' ', '\n')
    parsed_key = parsed_key.replace('BEGIN\nOPENSSH\nPRIVATE\nKEY','BEGIN OPENSSH PRIVATE KEY')
    parsed_key = parsed_key.replace('END\nOPENSSH\nPRIVATE\nKEY','END OPENSSH PRIVATE KEY')
    return parsed_key

  def _get_ssh_secret(self) -> Tuple[str, str]:
    response = self.secretsmgr.get_secret_value(SecretId=SSH_SECRET_NAME)
    secret_json = json.loads(response['SecretString'])
    private = self._parse_private_key(secret_json[PRIVATE_KEY])
    public = secret_json[PUBLIC_KEY]
    return (private, public)
  
  def _store_ssh_secret(self, private_key:str, public_key:str) -> None:
    ssh_secret = {
      PRIVATE_KEY: private_key,
      PUBLIC_KEY: public_key
    }
    self.secretsmgr.create_secret(
      Name=SSH_SECRET_NAME,
      Description='Host SSH Key for provisioning EKS-D cluster via KubeOne',
      KmsKeyId=self.kms_key_arn,
      SecretString=json.dumps(ssh_secret, separators=(',',':'))
    )
  
  def _secret_exists(self) -> bool:
    response = self.secretsmgr.list_secrets(
      MaxResults = 100,
      Filters=[
        {
          'Key':'name',
          'Values':[SSH_SECRET_NAME]
        }
      ]
    )
    return len(response['SecretList']) == 1

  def _bucket_exists(self) -> bool:
    response = self.s3.list_buckets()
    for bucket in response['Buckets']:
      if bucket['Name'] == TF_BUCKET_NAME:
        return True
    return False

  def _create_bucket(self) -> None:
    if not self._bucket_exists():
      self.s3.create_bucket(
        ACL='private',
        Bucket=TF_BUCKET_NAME,
        CreateBucketConfiguration={
          'LocationConstraint':self.region
        }
      )
      self._set_bucket_encryption()
      self._block_public_access()
      self._enable_bucket_versioning()

  def _set_bucket_encryption(self) -> None:
    self.s3.put_bucket_encryption(
      Bucket=TF_BUCKET_NAME,
      ServerSideEncryptionConfiguration={
        'Rules':[
          {
            'ApplyServerSideEncryptionByDefault':{
              'SSEAlgorithm':'aws:kms',
              'KMSMasterKeyID':self.kms_key_arn
            },
            'BucketKeyEnabled':True
          }
        ]
      }
    )

  def _block_public_access(self) -> None:
    self.s3.put_public_access_block(
      Bucket=TF_BUCKET_NAME,
      PublicAccessBlockConfiguration={
        'BlockPublicAcls':True,
        'IgnorePublicAcls':True,
        'BlockPublicPolicy':True,
        'RestrictPublicBuckets':True
      }
    )

  def _enable_bucket_versioning(self) -> None:
    self.s3.put_bucket_versioning(
      Bucket=TF_BUCKET_NAME,
      VersioningConfiguration={
        'Status':'Enabled'
      }
    )

  def _table_exists(self) -> bool:
    response = self.dynamo.list_tables()
    for table_name in response['TableNames']:
      if table_name == TF_TABLE_NAME:
        return True
    return False

  def _create_table(self) -> None:
    if not self._table_exists():
      self.dynamo.create_table(
        TableName=TF_TABLE_NAME,
        AttributeDefinitions=[
          {
            'AttributeName':'LockID',
            'AttributeType':'S'
          }
        ],
        KeySchema=[
          {
            'AttributeName':'LockID',
            'KeyType':'HASH'
          }
        ],
        BillingMode='PROVISIONED',
        ProvisionedThroughput={
          'ReadCapacityUnits':1,
          'WriteCapacityUnits':1
        }
      )

  def set_host_key(self) -> None:
    already_exists = self._secret_exists()
    ssh_key_filepath = f"{SSH_HOME}/{SSH_KEY_NAME}"
    self._remove_file(ssh_key_filepath)
    self._remove_file(f"{ssh_key_filepath}.pub")
    private_key = ''
    public_key = ''
    if already_exists:
      private_key, public_key = self._get_ssh_secret()
      with open(ssh_key_filepath, "w") as priv_key_file:
        priv_key_file.write(private_key)
      with open(f"{ssh_key_filepath}.pub", "w") as pub_key_file:
        pub_key_file.write(public_key)
    else:
      command = f"ssh-keygen -b 4096 -f {ssh_key_filepath} -t RSA -N \"\""
      os.system(command)
      with open(ssh_key_filepath, "r") as priv_key_file:
        private_key = priv_key_file.read()
      with open(f"{ssh_key_filepath}.pub", "r") as pub_key_file:
        public_key = pub_key_file.read()
      self._store_ssh_secret(private_key, public_key)
    
  def set_terraform_backend(self) -> None:
    self._create_bucket()
    self._create_table()

if __name__ == '__main__':
  aws_region = sys.argv[1]
  kms_key_arn = sys.argv[2]
  backend_settings = BACKEND_SETTINGS.format(aws_region, AWS_PROFILE, TF_BUCKET_NAME, aws_region, TF_TABLE_NAME).replace('[','{').replace(']','}')
  setup = Setup(region=aws_region, kms_key_arn=kms_key_arn)
  setup.set_terraform_backend()
  setup.set_host_key()
  with open(TF_BACKEND_FILE, "w") as backend:
    backend.write(backend_settings)
  
