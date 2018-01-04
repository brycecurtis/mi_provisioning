#!/bin/bash
# Update System 
sudo apt-get -y update
# Install Build Tools
sudo apt-get -y -f install vim make git curl

# Prevent root login via SSH
sed -i -e "s/PermitRootLogin [y|Y]es/PermitRootLogin without-password/g" /etc/ssh/sshd_config 
sed -i -e "s/PasswordAuthentication [y|Y]es/PasswordAuthentication no/g" /etc/ssh/sshd_config
service ssh restart 

# Install Latest Ubuntu Trusty Docker Package
#curl -sSL https://get.docker.com/ | sh

# Install Docker 17.03.2 with aufs
apt-get -y update
apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get -y update
apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get -y install docker-ce=17.03.2~ce-0~ubuntu-trusty

# Install the startup script
git clone https://github.com/brycecurtis/mi_provisioning/ /usr/share/mi_startup
mv /usr/share/mi_startup/centralserver/mi_centralserver_startup.sh /usr/bin/
rm -rf /etc/rc.local
mv /usr/share/mi_startup/centralserver/rc.local /etc/
rm -rf /usr/share/mi_startup/

# Startup the etcd container
docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 4001:4001 -p 2380:2380 -p 2379:2379 --name MI_ETCD quay.io/coreos/etcd:v2.0.8 -name etcd0 -advertise-client-urls http://127.0.0.1:2379,http://127.0.0.1:4001 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 -initial-advertise-peer-urls http://127.0.0.1:2380 -listen-peer-urls http://127.0.0.1:2380 -initial-cluster-token etcd-cluster-1 -initial-cluster etcd0=http://127.0.0.1:2380 -initial-cluster-state new

