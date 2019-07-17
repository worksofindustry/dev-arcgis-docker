#!/bin/bash
#
#  Run this in an ArcGIS container to start the server
#  and configure it with the default admin/password and site
#
# Required ENV settings:
# HOSTNAME HOME ESRI_VERSION , these should be set in the Dockerfile

cd $HOME

if [ "$AGS_USERNAME" = "" -o "$AGS_PASSWORD" = "" ]
then
    echo "Define AGS_USERNAME and AGS_PASSWORD in the environment to override defaults."
    #exit 1
fi

# Our hostname is different than when we built this container image,
# fix up the name of our properties file
echo My hostname is $HOSTNAME
NEWPROPERTIES=".ESRI.properties.${HOSTNAME}.${ESRI_VERSION}"
PROPERTIES=".ESRI.properties.*.${ESRI_VERSION}"
if ! [ -f "$NEWPROPERTIES" ] && [ -f "$PROPERTIES" ]; then
    echo "Linked $PROPERTIES."
    ln -s $PROPERTIES $NEWPROPERTIES
fi

# Do that brute force thing, remove the directory contents.
CONFIGDIR="./server/usr/config-store"
if [ -e ${CONFIGDIR}/.site ]; then
    echo "Removing previous site configuration files."
    rm -rf ${CONFIGDIR}/* ${CONFIGDIR}/.site
fi

# This would be a good place to authorize a
# license file if you have not done that already
# Check status first
#./server/tools/authorizeSoftware -s

echo "Starting ArcGIS Server"
cd /home/gisowner/arcgis/server
./startserver.sh

# Pause for server to start
sleep 15

echo "Waiting for ArcGIS Server to start..."
#curl --retry 20 -sS --insecure "https://$HOSTNAME:6443/arcgis/manager" > /tmp/apphttp
#if [ $? != 0 ]; then
#    echo "ArcGIS did not start. $?"
#    exit 1
#fi

sleep 2

echo "Yes; configuring default site." 
cd $HOME

python create_new_site.py

exit 0

