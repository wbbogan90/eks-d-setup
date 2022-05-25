import os, sys, json, boto3
from pathlib import Path
from typing import Tuple

ROOT = str(Path(__file__).resolve())
SSH_HOME = f"{str(os.environ['HOME'])}/.ssh"
SSH_KEY_NAME = 'ec2-user-ssh'
SSH_SECRET_NAME = 'deo-eks-d-ssh'
PRIVATE_KEY = 'private'
PUBLIC_KEY = 'public'

class Util:
  def __init__(self, region:str, kms_key_arn:str):
    self.secretsmgr = boto3.client('secretsmanager', region_name=region)
    self.kms_key_arn = kms_key_arn
    
  def remove_file(filename):
    try:
      os.remove(f"{ROOT}/{filename}"
    except FileNotFoundError:
      pass
  
  def _get_ssh_secret(self) -> Tuple[str, str]:
    response = self.secretsmgr.get_secret_value(SecretId=SSH_SECRET_NAME)
    secret_json = json.loads(response['SecretString'])
    return secret_json[PRIVATE_KEY], secret_json[PUBLIC_KEY]
  
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
           
  def set_host_key(self) -> None:
    already_exists = self._secret_exists()
    ssh_key_filepath = f"{SSH_HOME}/{SSH_KEY_NAME}"
    if already_exists:
      private_key, public_key = self._get_ssh_secret()
      with open(ssh_key_filepath, "w") as priv_key_file:
        priv_key_file.write(private_key)
      with open(f"{ssh_key_filepath}.pub", "w") as pub_key_file:
        pub_key_file.write(public_key)
    else:
      
    
  
