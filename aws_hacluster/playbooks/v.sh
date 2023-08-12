#!/bin/bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# Check if the targetcli package is installed
if ! command -v targetcli &> /dev/null; then
    echo "targetcli is not installed. Please install it before running this script."
    exit 1
fi

# Define the name of the target and the iSCSI LUN
TARGET_NAME="iqn.2023-07.com.example:server"
CLIENT_NAME="iqn.2023-07.com.example:client"
ISCSI_LUN="disk"
TARGET_PRIVATE_IP="192.168.0.3"
# Define the name of the Logical Volume (LV)
LV_NAME="my_lv"


# Run targetcli commands to set up the iSCSI target and LUN with the LV as a backstore
targetcli <<EOF
/backstores/block create $ISCSI_LUN /dev/$iscsi_group_lvm/$iscsi_target_lvm
/iscsi create $TARGET_NAME
/iscsi/$TARGET_NAME/tpg1/acl create $CLIENT_NAME
/iscsi/$TARGET_NAME/tpg1/luns create /backstores/block/$ISCSI_LUN
/iscsi/$TARGET_NAME/tpg1/portals delete ip_address=0.0.0.0 ip_port=3260
/iscsi/$TARGET_NAME/tpg1/portals create $TARGET_PRIVATE_IP
/saveconfig
/exit
EOF 

# Start and enable targetcli
systemctl enable target
systemctl start target

#start and enable firewalld
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-port=3260/tcp
firewall-cmd --reload
