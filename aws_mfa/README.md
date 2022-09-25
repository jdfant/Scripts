<!-- BEGIN_AWS_MFA_DOC -->
# AWS MFA Setup and Usage Instructions

## Description
This page addresses using a script to setup MFA for AWS command line functions, including:
- AWS CLI commands
- Terraform jobs

This script authenticates the AWS user via the Assigned MFA device created by the user.

## Enable MFA Device
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html?icmpid=docs_iam_console#enable-virt-mfa-for-own-iam-user

### **MFA Enforcement (AWS Admins)**
Enforces MFA for command line functions.
- User must be added to the "MFA-Admin" IAM group.
- User must then be removed from the existing "AWSAdministrators" IAM group.

    Policies attached to the MFA-Admin group:
    - IAMSelfService
    - MFAAdmin

## Preparation
The script is located at https://github.com/jdfant/Scripts/blob/master/aws_mfa/aws-cli-mfa.sh

Download the script and copy or move it to **/usr/local/bin/**

Make sure that the script is executable:
```
chmod +x /usr/local/bin/aws-cli-mfa.sh
```
The AWS Command Line Interface tool must be installed for this script to function. It is irrelevant what version is used.

Please follow one of the links below for AWS Command Line Interface installation instructions:

- Version 1:
https://docs.aws.amazon.com/cli/v1/userguide/cli-chap-install.html

- Version 2:
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

The only configuration file necessary for this script to function is your AWS credentials file:
- ~/.aws/credentials


## Script Execution
- This script accepts a profile name as an argument using the syntax, "–profile profile_name". If no arguments are
passed, the "Default" account is used.

*The profile_name corresponds with the profile entries in the ~/.aws/credentials file. See **NOTES**, below.*

- Executing the script, as the user to be authenticated, is all that is required:
```
/usr/local/bin/aws-cli-mfa.sh --profile profile_name
```
Omit flags/arguments If acquiring or renewing session tokens for the "Default" account.
```
/usr/local/bin/aws-cli-mfa.sh
```

This script also accepts "-h" or "–help" arguments for usage instructions.

**NOTES**:

- *If adding new profile entries to the aws credentials, please add them to ~/.aws/credentials.orig as this file is persistent and ~/.aws/credentials will be overwritten.*

- *Default Session Token Timeout is hard coded to 12 Hours.*

- *If a long running job is necessary, it will be recommended to execute the script beforehand.*

- *Script can be executed even if the session token has not expired. It will only renew the session token and reset the
timeout to 12 hours.*

## Functions
- Script first prompts the user for the "TOTP Code" unless the session token has not expired.

- If session token has not expired, user will be shown which MFA Device is active, the session expiration time (UTC),
and an option to renew token.

- Copies the user's ~/.aws/credentials file to ~/.aws/credentials.orig for preservation and to request new session
token.

- Creates the ~/.aws/.mfa_device file containing the ID (arn) of the "Assigned MFA device" for the account.

- Creates the ~/.aws/.mfa_token file containing the output from the 'aws sts get-session-token' command for the
account.

- Leverages the 'aws configure' command to populate the new ~/.aws/credentials file, setting new variables for:
   - aws_access_key_id
   - aws_secret_access_key
   - aws_session_token

## Troubleshooting
- **Running an 'aws cli' command using a --profile argument, but passing the same --profile argument to
/usr/local/bin/aws-cli-mfa.sh --profile profile_name
/usr/local/bin/aws-cli-mfa.sh the aws-cli-mfa.sh script fails:**
   - In most cases, you will not need to use the --profile argument and can just add a
```'source_profile=default'``` line in each ```'[profile]'``` block of your ~/.aws/config file.  
   Then after executing the script with no arguments, the 'aws cli' command should function correctly when passing the ```--profile account_name``` argument.

   - If the profile name matches a unique user in an account, pointing the ```--profile``` argument to that name (for the
aws-cli-mfa.sh script) should function, fine.

- **Terraform runs fail when accessing resources using '[primary]' accounts.**
   - You may run into this scenario when accessing resources like Route53 or root level IAM resources.  
    In many cases, the ```'[primary]'``` account contains a ```'source_profile=default'``` entry.  
    If this is the case, duplicating the ```'[default]'``` block contents **AFTER MFA authentication** into the ```'[primary]'```
block will remedy the related issues.  
   This is an easy fix, but you must format your ```~/.aws/credentials.orig``` file and edit the aws-cli-mfa.sh script in order to make it work:

For the ```~/.aws/credentials.orig``` file, the only entries necessary are (Use the official AWS key credentials for your account):
```
[default]
aws_access_key_id = xxxxxxxxxxxxxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxx
aws_session_token = xxxxxxxxxxxxxxxxxxxxxxxx
```
For the aws-cli-mfa.sh script, go to the **setCredentials()** function and add the following after the 3rd ```'aws
configure set'``` line within that function:
```
# Some use cases require a "[primary]" account in the ~/.aws/credentials file.
# This file MUST match the "[default]" block credentials.
echo -e "\n[primary]" >> "${AWS_CREDS}" | grep -A3 '\[default\]' "${AWS_CREDS}" |grep -v 'default' >> "${AWS_CREDS}"
```
The entire **setCredentials()** function should look like:
```
setCredentials(){
aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}"
aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"
aws configure set aws_session_token "${AWS_SESSION_TOKEN}"

# Some use cases require a "[primary]" account
# in the ~/.aws/credentials file.
# This file MUST match the "[default]" block credentials.
echo -e "\n[primary]" >> "${AWS_CREDS}" | grep -A3 '\[default\]' "${AWS_CREDS}" |grep -v 'default' >> "${AWS_CREDS}"
``` 
With the above script changes, after executing aws-cli-mfa.sh script, your ~/.aws/credentials file will look like:
```
[default]
aws_access_key_id = xxxxxxxxxxxxxxxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxx
aws_session_token = xxxxxxxxxxxxxxxxxxxxxxxx

[primary]
aws_access_key_id = xxxxxxxxxxxxxxxxxxxxxxxx
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxx
aws_session_token = xxxxxxxxxxxxxxxxxxxxxxxx
```

*All key entries are exactly the same for both accounts.*

IF the ```'[primary]'``` account has a ```'source_profile='``` entry for another account (other than default), pointing ```--profile``` at the 'sourced' account to the ```aws-mfa-cli.sh``` script will authenticate for the 'primary' account.
<!-- END_AWS_MFA_DOC -->
