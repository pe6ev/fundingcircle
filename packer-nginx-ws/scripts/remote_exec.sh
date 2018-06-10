#!/bin/bash -e

echo -e "Checking the kernel version..."
grub2-editenv -v /boot/grub2/grubenv list

echo "Updating kernel.."
sudo yum -y update kernel
grub2-editenv -v /boot/grub2/grubenv list

echo "Yum updates..."
sudo yum update -y

echo "Copying CIS.conf to /etc/modprobe.d/CIS.conf ..."
cp /tmp/etc_modprobe.d_CIS.conf /etc/modprobe.d/CIS.conf

echo "Copying sysctl.conf to /etc/sysctl.conf ..."
cp /tmp/etc_sysctl.conf /etc/sysctl.conf

echo "Updating limits.conf..."
cat /tmp/etc_security_limits.conf >> /etc/security/limits.conf

echo "Updating /etc/fstab..."
cat /tmp/etc_fstab >> /etc/fstab

echo "Updating /etc/hosts..."
cat /tmp/etc_hosts >> /etc/hosts
