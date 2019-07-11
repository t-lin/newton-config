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

echo "Copying over new nova configurations..."
cp -r ${BASE_DIR}/nova/etc/nova/rootwrap.* /etc/nova/
cp ${SCRIPT_DIR}/agent/nova.conf /etc/nova/

echo "Renaming old neutron configurations..."
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.havana
mv /etc/neutron/rootwrap.conf /etc/neutron/rootwrap.conf.havana
mv /etc/neutron/rootwrap.d /etc/neutron/rootwrap.d.havana

echo "Copying over new neutron configurations..."
cp -r ${BASE_DIR}/neutron/etc/neutron/rootwrap.d /etc/neutron/
cp ${BASE_DIR}/neutron/etc/rootwrap.conf /etc/neutron/
mkdir -p /etc/neutron/plugins/ml2
cp ${SCRIPT_DIR}/agent/neutron.conf /etc/neutron/
cp ${SCRIPT_DIR}/agent/ml2_conf.ini /etc/neutron/plugins/ml2/

echo
read -p "What is the controller's internal management IP? => " CTRL_IP
read -p "What is this agent's internal management IP? => " AGENT_IP
echo

echo "Re-writing IPs..."
sed -i "s/CTRL_IP/${CTRL_IP}/g" /etc/neutron/neutron.conf
sed -i "s/CTRL_IP/${CTRL_IP}/g" /etc/nova/nova.conf
sed -i "s/AGENT_IP/${AGENT_IP}/g" /etc/nova/nova.conf
sed -i "s/AGENT_IP/${AGENT_IP}/g" /etc/neutron/plugins/ml2/ml2_conf.ini

echo
read -p "What is this region's name? => " REGION_NAME
echo

echo "Re-writing region name..."
sed -i "s/REGION_NAME/${REGION_NAME}/g" /etc/nova/nova.conf
sed -i "s/REGION_NAME/${REGION_NAME}/g" /etc/neutron/neutron.conf

echo
echo "Replacing stack-screenrc..."
mv ~/devstack/stack-screenrc ~/devstack/stack-screenrc.havana
cp ${SCRIPT_DIR}/agent/stack-screenrc ~/devstack/

echo
echo "Done!"
