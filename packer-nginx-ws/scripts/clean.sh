#!/bin/bash -e

echo -e "Checking the kernel version..."
grub2-editenv -v /boot/grub2/grubenv list
