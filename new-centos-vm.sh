#!/usr/bin/env bash

set -e

host_name=$1
ip_address=$2
memory=$3
processors=$4
disk_name=$host_name.qcow2
ks_file=$host_name.ks



create_ksfile()
{
	cat << EOF > /export/$ks_file
url --url=http://kvm01/centos7/
text
firstboot --enable
ignoredisk --only-use=vda
keyboard --vckeymap=us --xlayouts=''
lang en_US.UTF-8
network  --bootproto=static --device=eth0 --gateway=192.168.2.1 --ip=$ip_address --nameserver=192.168.2.4,192.168.2.1 --netmask=255.255.255.0 --ipv6=auto --activate
network  --hostname=$host_name
rootpw "_PASSWORD_"
selinux --permissive
services --enabled="chronyd"
logging --level=debug
skipx
user --groups=wheel --name=_USERNAME --password="_PASSWORD_"
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=vda
autopart --type=lvm
clearpart --linux --initlabel --drives=vda
timezone America/New_York
eula --agreed
reboot

%packages
@base
@core
@system-admin-tools
@security-tools
@console-internet
@development
@compat-libraries
@perl-runtime
%end


%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=50 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=50 --notstrict --nochanges --notempty
pwpolicy luks --minlen=6 --minquality=50 --notstrict --nochanges --notempty
%end

%post
# Create ssh authorized keys
# Make the directory
mkdir /root/.ssh

# Create the keys file
cat  << xxEOFxx >> /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaCfdsfdsfdsfdsfdsfdsfdsfc2EAAAADAQABAAABAQDfMjDfTS51g3QIOo2gaQmYCroU50bxq0zoP/z9b8jlghV4KNRvcdCyRKTl7GZtVyHDWu3wU1Wp2unT9ckygrvlHnaPecvuwV2wZjipQBAztVJ6eUH0UIgR94GN5UEGqQ4d+NhmAAh84oKeJfGbkrfO+NV+4wjX+DCemTvn9oRm1gu78zrkASRetddvByYLuZhDDIRgHvb7Lp5sbmMmcabhEeEOAS5Pcax35m7Z4TtUqRIMYtTFl7Dzil7fnzKEPr2wdKak+U/N89+DdUy76AAqTZBp111111111111111111111111bJljF9IZMr/PEvo++adJroGe8Xs2wvBuyWD1pbn root@xxxxxx.home.lan
xxEOFxx
%end
EOF
}

create_vm()
{
	virt-install --connect=qemu:///system \
	--name=$host_name \
	--ram=$memory \
	--vcpus=$processors \
	--network=bridge:bridge0 \
	--graphics none \
	--os-type linux \
	--os-variant rhel7 \
	--location=http://kvm01/centos7/ \
	--initrd-inject=/export/$ks_file \
	--extra-args="ks=file:/$ks_file text console=tty0 utf8 console=ttyS0,115200" \
	--disk path=/var/lib/libvirt/images/$disk_name,size=30,bus=virtio,format=qcow2 \
	--force
}

#main
{
	# check if min no. of arguments are 4
    #
    if [ "$#" != 4 ]; then
    	echo -e "\n"
        echo -e "Usage: \t\t$0 vm-name ipaddress ram cpus\n"
        echo -e "vmname: \tvmXX (check if hostname is available (01 - 12)"
        echo -e "ipaddress:  \t192.168.2.XX (check if the ip is available (.41 - .49)"
        echo -e "memory: \t1096 2048 4096"
        echo -e "cpus: \t\t1 2\n"
        echo -e "e.g. ./`basename $0` vmX 192.168.2.4X 1096 2"


        exit 255
    fi

    create_ksfile
    
    echo -e "VM is being created ......\n"
    create_vm

    exit 0
}
