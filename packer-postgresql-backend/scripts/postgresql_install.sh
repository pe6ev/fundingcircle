#!/bin/bash -e

echo -e "Stop local iptables service.."

sudo systemctl stop iptables  
sudo systemctl disable iptables

echo -e "Install  postgresql server ..."

sudo yum clean all
sudo yum install postgresql-server postgresql-contrib -y

echo -e "Initialize Postgres database and start PostgreSQL."

sudo postgresql-setup initdb
sudo systemctl start postgresql

echo -e "Configure PostgreSQL to start on boot"

sudo systemctl enable postgresql












