#!/bin/bash
if [[ $# -ne 1 ]]; then
    echo "Need one parameter: path to location of new (Newton) nova and neutron directories"
    echo "     e.g. If they're both within /home/ubuntu then specify that"
    exit 0
else
    BASE_DIR=$1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Ensure correct permissions first
sudo chown -R `whoami`:`whoami` /etc/nova /etc/neutron /opt/stack

echo "Renaming old nova configurations..."
mv /etc/nova/nova.conf /etc/nova/nova.conf.havana
mv /etc/nova/rootwrap.conf /etc/nova/rootwrap.conf.havana
mv /etc/nova/rootwrap.d /etc/nova/rootwrap.d.havana
mv /etc/nova/api-paste.ini /etc/nova/api-paste.ini.havana

echo "Renaming old neutron configurations..."
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.havana
mv /etc/neutron/rootwrap.conf /etc/neutron/rootwrap.conf.havana
mv /etc/neutron/rootwrap.d /etc/neutron/rootwrap.d.havana
mv /etc/neutron/api-paste.ini /etc/neutron/api-paste.ini.havana

echo "Copying over new nova configurations..."
cp ${BASE_DIR}/nova/etc/nova/api-paste.ini /etc/nova/
cp -r ${BASE_DIR}/nova/etc/nova/rootwrap.* /etc/nova/
cp ${SCRIPT_DIR}/controller/nova.conf /etc/nova/

echo "Copying over new neutron cnofigurations..."
cp ${BASE_DIR}/neutron/etc/api-paste.ini /etc/neutron/
cp -r ${BASE_DIR}/neutron/etc/neutron/rootwrap.d /etc/neutron/
cp ${BASE_DIR}/neutron/etc/rootwrap.conf /etc/neutron/
mkdir -p /etc/neutron/plugins/ml2
cp ${SCRIPT_DIR}/controller/neutron.conf /etc/neutron/
cp ${SCRIPT_DIR}/controller/*_agent.ini /etc/neutron/
cp ${SCRIPT_DIR}/controller/ml2_conf* /etc/neutron/plugins/ml2/

echo
read -p "What is the controller's internal management IP? => " CTRL_IP
echo

echo "Re-writing IPs..."
sed -i "s/CTRL_IP/${CTRL_IP}/g" /etc/neutron/neutron.conf
sed -i "s/CTRL_IP/${CTRL_IP}/g" /etc/neutron/metadata_agent.ini
sed -i "s/CTRL_IP/${CTRL_IP}/g" /etc/neutron/plugins/ml2/ml2_conf.ini
sed -i "s/CTRL_IP/${CTRL_IP}/g" /etc/neutron/plugins/ml2/ml2_conf_no_rules.ini
sed -i "s/CTRL_IP/${CTRL_IP}/g" /etc/nova/nova.conf

echo
read -p "What is this region's name? => " REGION_NAME
echo

echo "Re-writing region name..."
sed -i "s/REGION_NAME/${REGION_NAME}/g" /etc/nova/nova.conf
sed -i "s/REGION_NAME/${REGION_NAME}/g" /etc/neutron/neutron.conf
sed -i "s/REGION_NAME/${REGION_NAME}/g" /etc/neutron/metadata_agent.ini

echo
echo "Replacing stack-screenrc..."
mv ~/devstack/stack-screenrc ~/devstack/stack-screenrc.havana
cp ${SCRIPT_DIR}/controller/stack-screenrc ~/devstack/
ROUTERID=`mysql -sN -e "USE neutron; SELECT id FROM routers;"`
if [[ `echo ${ROUTERID} | wc -l` -ne 1 || -z ${ROUTERID} ]]; then
    echo "ERROR: Something went wrong trying to find the Neutron router's ID..."
    echo "       Must manually figure out which one should be QR and edit stack-screenrc's arp_handler line"
    exit 0
fi
sed -i "s/QR_NS/${ROUTERID}/g" ~/devstack/stack-screenrc

echo
echo "Done!"

