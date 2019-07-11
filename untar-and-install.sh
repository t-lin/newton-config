#!/bin/bash

echo "Installing apt and pip packages..."
sudo apt-get install ipset conntrack libvirt-dev pkg-config libmysqlclient-dev libffi-dev libssl-dev
sudo pip install -U pip
sudo pip install setuptools==38.7.0 cffi==1.5.2 cryptography==1.2.3 gevent==1.0.2 pymysql mysqlclient python-neutronclient==5.1.0
echo

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "WARNING: This script and tar files assumes nova and neutron directories are located in /opt/stack/"
echo "         If this is not the case, have to resort back to manually editing paths of virtualenvs..."
echo
read -p "Press ENTER to continue..." ASDFASDF

echo
echo "Renaming old nova and neutron directories..."
mv /opt/stack/nova /opt/stack/nova.havana
mv /opt/stack/neutron /opt/stack/neutron.havana

echo
echo "Untar'ing new directories..."
tar -xvf ${SCRIPT_DIR}/nova-newton.tar.gz -C /opt/stack/
tar -xvf ${SCRIPT_DIR}/neutron-newton.tar.gz -C /opt/stack/
tar -xvf ${SCRIPT_DIR}/oslo-projects.tar.gz -C /opt/stack/
tar -xvf ${SCRIPT_DIR}/janus-ovsdb.tar.gz -C /opt/stack/

echo
echo "Installing nova binaries..."
cd /opt/stack/nova && sudo python setup.py install

echo
echo "Installing neutron binaries..."
cd /opt/stack/neutron && sudo python setup.py install

echo "Re-writing nova-* and neutron-* binary shebangs..."
cd /usr/local/bin
NOVABINS=`ls nova-*`
for i in $NOVABINS ; do
    sudo sed -i '1s/^/#!\/opt\/stack\/nova\/bin\/python\n/g' $i;
done

NEUTRONBINS=`ls neutron-*`
for i in $NEUTRONBINS ; do
    sudo sed -i '1s/^/#!\/opt\/stack\/neutron\/bin\/python\n/g' $i;
done

echo "Installing OSLO privsep-helper and re-writing its shebang to use nova's virtualenv..."
echo "    - Only needed for compute agents... but whatever"
cd /opt/stack/oslo.privsep && sudo python setup.py install
sudo sed -i '1s/^/#!\/opt\/stack\/nova\/bin\/python\n/g' /usr/local/bin/privsep-helper

echo
read -p "What is this region's name? => " REGION_NAME
read -p "What is the controller's internal management IP? => " CTRL_IP

echo
echo "Re-writing region name and controller IP for ovsdb.py..."
sed -i "s/REGION_NAME/${REGION_NAME}/g" /opt/stack/janus-ovsdb/ovsdb.py
sed -i "s/CTRL_IP/${CTRL_IP}/g" /opt/stack/janus-ovsdb/ovsdb.py

echo
echo "Done!"
echo
echo "Depending on whether this is a controller or agent, run the relevant copy config script"
