#!/bin/bash

USERNAME=rundeck
HOME=/home/rundeck

adduser --home $HOME --disabled-password --gecos "rundeck" $USERNAME

mkdir $HOME/.ssh
chmod 755 $HOME/.ssh
chown -R $USERNAME $HOME/.ssh
echo "rundeck:$NODE_USER_PASSWORD"|chpasswd
echo 'rundeck ALL=(ALL:ALL) ALL' >> /etc/sudoers

# authorize SSH connection with root account
sed -i "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config

# authorize SSH connection with rundeck account
mkdir -p /home/rundeck/.ssh
mkdir -p /home/rundeck/.ansible
mkdir -p /home/rundeck/.ansible/tmp

mkdir -p /root/.ssh

chown -R "$USERNAME" $HOME/.ssh
chown -R "$USERNAME:$USERNAME" $HOME/.ansible
chown -R "$USERNAME:$USERNAME" $HOME/.ansible/tmp

cat /configuration/id_rsa.pub > /home/rundeck/.ssh/authorized_keys
cat /configuration/id_rsa_passphrase.pub >> /home/rundeck/.ssh/authorized_keys

cat /configuration/id_rsa.pub > /root/.ssh/authorized_keys
cat /configuration/id_rsa_passphrase.pub >> /root/.ssh/authorized_keys
