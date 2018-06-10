#!/bin/bash -e

echo -e "Stop local iptables service.."

sudo systemctl stop iptables  
sudo systemctl disable iptables

echo -e "Install epel repo and  nginx ..."

sudo yum install epel-release -y
sudo yum clean all
sudo yum install nginx -y

echo -e "Enable nginx on startup."

sudo chkconfig nginx on 

echo -e "Copy nginx configuration file ..."

sudo yes | cp /tmp/nginx.conf /etc/nginx/nginx.conf
sudo yes | cp /tmp/index.html /usr/share/nginx/html/

echo -e "Create health check file ..."

sudo mkdir /usr/share/nginx/html/_internal

sudo touch /usr/share/nginx/html/_internal/health && sudo echo "OK" >> /usr/share/nginx/html/_internal/health

echo -e "Change dir permessions to nginx..."

sudo chown -R nginx. /usr/share/nginx/

echo -e "Starting Nginx service..."

sudo systemctl start nginx









