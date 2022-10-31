#!/bin/bash
##########################################################################
#
# Add / Remove UFW rules based on a given hostname+port+protocol
#
# add this to your cron.d/xxxx :
#   # re-create dyndns based UFW rule 
#   */5 * * * * root /root/ufw-dyndns-updater.sh
##########################################################################
VERSION="1.1"
DEBUG=0
##############

HOSTNAME=<DYNDNS-NAME>
PORT=8000
PROTO=tcp

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

new_ip=$(host $HOSTNAME | grep "has addr" | head -n1 | cut -f4 -d ' ')
old_ip=$(/usr/sbin/ufw status | grep $HOSTNAME | head -n1 | tr -s ' ' | cut -f3 -d ' ')

if [ "$new_ip" = "$old_ip" ] ; then
    [ $DEBUG -eq 1 ] && echo IP address has not changed or new_ip empty
    true
else
    if [ -n "$old_ip" ] ; then
        /usr/sbin/ufw delete allow from $old_ip to any port $PORT proto $PROTO 1> /dev/null
    fi
    if [ ! -z "$new_ip" ];then
        [ $DEBUG -eq 1 ] && echo iptables will be updated
        /usr/sbin/ufw allow from $new_ip to any port $PORT proto $PROTO comment $HOSTNAME 1> /dev/null
    else
        echo "new_ip empty.. not updating ufw - BUT old_ip entry has been removed - so no rule active atm.."
    fi
fi
