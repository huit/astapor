#!/bin/bash 

echo "############################################################"
echo "Warning: uninstalling Foreman and realted services"
echo "  This will uninstall thiungs like mysql, httpd and puppet. "
echo "  Use at your own risk. "
echo "############################################################"

read -p "Press [Enter] to continue"

echo "Cleaning up a Foreman install ... "

RPMS="foreman foreman-installer foreman-proxy foreman-mysql foreman-mysql2 foreman-selinux \
      openstack-foreman-installer puppet-server puppet httpd mysql-server "

for r in ${RPMS}; do
	yum -y remove ${RPMS}
done

DIRS="/var/lib/mysql /var/lib/puppet /var/lib/foreman /var/lib/foreman-proxy \
      /etc/puppet /etc/foreman /etc/foreman-proxy /etc/mysql /etc/my.cnf "

for d in ${DIRS}; do

	[ -d ${d} ] && rm -rf ${d}
done      