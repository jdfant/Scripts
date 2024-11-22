#!/bin/bash

#
# Cheap and effective MFA shell script for AWS
#

# Default File Names
MFA_DEVICE_FILE="${HOME}/.aws/.mfa_device"
MFA_TOKEN_FILE="${HOME}/.aws/.mfa_token"
AWS_CREDS="${HOME}/.aws/credentials"
AWS_CREDS_ORIG="${HOME}/.aws/credentials.orig"
DURATION_SECONDS=43200 # 12 hour timeout, adjust accordingly.

# Copy existing credentials file
if [ -s "${AWS_CREDS_ORIG}" ]; then
  echo -n
else
  cp "${AWS_CREDS}" "${AWS_CREDS_ORIG}"
fi

mfaDevice() {
   aws iam list-mfa-devices --output text|awk '{print $3}' > "${MFA_DEVICE_FILE}"
   echo "Your MFA Serial has been saved"
}

if [ ! -s "${MFA_DEVICE_FILE}" ]; then
  mfaDevice
fi

getCredentials(){
  cp "${AWS_CREDS_ORIG}" "${AWS_CREDS}"
  while true; do
    read -rp "Please enter your 6 digit MFA token: " token
      case $token in
          [0-9][0-9][0-9][0-9][0-9][0-9] ) MFA_TOKEN=$token; break;;
          * ) echo "Please enter a valid 6 digit pin." ;;
      esac
  done

  SESSION_AUTH=$(aws sts get-session-token \
        --serial-number "$(cat "${MFA_DEVICE_FILE}")" \
        --token-code "${MFA_TOKEN}" \
        --duration-seconds ${DURATION_SECONDS} \
        --output text)

    if [ -n "${SESSION_AUTH}" ]; then
        echo "${SESSION_AUTH}" > "${MFA_TOKEN_FILE}"
        AWS_ACCESS_KEY_ID="$(awk '{print $2}' "${MFA_TOKEN_FILE}")"
        AWS_SECRET_ACCESS_KEY="$(awk '{print $4}' "${MFA_TOKEN_FILE}")"
        AWS_SESSION_TOKEN="$(awk '{print $5}' "${MFA_TOKEN_FILE}")"

        setCredentials
    fi
}

setCredentials(){
  aws configure set aws_access_key_id "${AWS_ACCESS_KEY_ID}"
  aws configure set aws_secret_access_key "${AWS_SECRET_ACCESS_KEY}"
  aws configure set aws_session_token "${AWS_SESSION_TOKEN}"
}

if [ -e "${MFA_TOKEN_FILE}" ]; then
  SESSION_AUTH=$(cat "${MFA_TOKEN_FILE}")
  SESSION_EXPIRE=$(awk '{print $3}' "${MFA_TOKEN_FILE}")
  CURRENT_TIME=$(date -u +'%FT%T+:00:00')

  if [ "${SESSION_EXPIRE}" \< "${CURRENT_TIME}" ]; then
    echo "Your last token has expired"
    cp "${AWS_CREDS_ORIG}" "${AWS_CREDS}"
    getCredentials
  else
    echo -e "\nYour MFA Session has not expired yet\n"
    while true; do
        read -rp "Do you still wish to reset session token? (y/n)" yn
        case $yn in
            [Yy]* ) rm -f "${MFA_TOKEN_FILE}"
                    getCredentials
                    setCredentials
                    break;;
            [Nn]* ) exit;;
            * ) echo "Please answer (Y)es or (N)o.";;
        esac
    done
  fi
else
  getCredentials
fi
