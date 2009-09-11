#!/bin/sh
#
# $Id: flavor.sh,v f54f2b62373a 2009/09/11 16:26:33 nieves $
#
if [ -f /etc/fedora-release ]
then
   flavor=fedoracore
elif [ -f /etc/SuSE-release ]
then
   flavor=opensuse
elif [ -f /etc/redhat-release ]
then
    flavor=centos
elif [ -f /etc/debian_version ] 
then
   flavor=debian
else
   flavor=unknown
fi

echo $flavor
