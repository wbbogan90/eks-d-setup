from setup import Setup, SSH_HOME, SSH_KEY_NAME
import os, unittest
from unittest import TestCase
from os.path import exists

REGION = 'us-east-2'
KMS_ARN = 'arn:aws:kms:us-east-2:691666183092:key/93238f20-5758-4198-a657-538b5f56ef9b'

class TestSetup(TestCase):

    def test_set_host_key(self):
        os.environ['AWS_PROFILE'] = 'deo'
        util = Setup(region=REGION, kms_key_arn=KMS_ARN)
        ssh_key_filepath = f"{SSH_HOME}/{SSH_KEY_NAME}"
        util.set_host_key()
        self.assertTrue(exists(ssh_key_filepath))

if __name__ == '__main__':
    unittest.main()