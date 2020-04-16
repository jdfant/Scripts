#!/bin/bash
###########
#  AGENT  #
###########

OSSEC_SERVER=xxx.xxx.xxx.xxx
RID=$(ls /var/ossec/queue/rids/*[0-9]*|awk -F/ '{print $6}')
OLD_IP=$(awk '{print $3}' /root/client.keys)
AGENT_IP=$(curl -s https://ifconfig.me)


if [[ "${OLD_IP}" == "${AGENT_IP}" ]];then
    exit 0
else
    sed -i.bk "/${RID}/s/${OLD_IP}/${AGENT_IP}/" /root/client.keys

    /usr/bin/ssh -t -o "StrictHostKeyChecking no" -i oss_man.key oss_man@${OSSEC_SERVER}\
     "sudo /root/ossec_scaling-server.sh ${RID} ${OLD_IP} ${AGENT_IP}"

    logger -t OSSEC_AGENT "Ossec Agent IP has changed from ${OLD_IP} to ${AGENT_IP}"
fi

=============================================================================================

#!/bin/bash
############
#  SERVER  #
############

RID=$1
OLD_IP=$2
AGENT_IP=$3

rm -f /usr/local/ossec-hids/queue/rids/"${RID}"
sed -i.bk "/${RID}/s/${OLD_IP}/${AGENT_IP}/" /usr/local/ossec-hids/etc/client.keys
/usr/local/etc/rc.d/ossec-hids restart
