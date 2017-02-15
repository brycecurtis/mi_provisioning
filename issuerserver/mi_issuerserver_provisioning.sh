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
curl -sSL https://get.docker.com/ | sh

# Install the startup script
git clone https://github.com/asherjohnsonibm/mi_provisioning/ /usr/share/mi_startup
mv /usr/share/mi_startup/issuerserver/mi_issuerserver_startup.sh /usr/bin/
rm -rf /etc/rc.local
mv /usr/share/mi_startup/issuerserver/rc.local /etc/
rm -rf /usr/share/mi_startup/

# Startup the etcd container
docker run -d -v /usr/share/ca-certificates/:/etc/ssl/certs -p 4001:4001 -p 2380:2380 -p 2379:2379 --name MI_ETCD quay.io/coreos/etcd:v2.0.8 -name etcd0 -advertise-client-urls http://127.0.0.1:2379,http://127.0.0.1:4001 -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 -initial-advertise-peer-urls http://127.0.0.1:2380 -listen-peer-urls http://127.0.0.1:2380 -initial-cluster-token etcd-cluster-1 -initial-cluster etcd0=http://127.0.0.1:2380 -initial-cluster-state new

