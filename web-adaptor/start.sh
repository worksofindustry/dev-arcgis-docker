#!/bin/bash
#
#  Script to run inside the container to start the web adapter.
#  It starts Tomcat, (which deploys the Web Adaptor WAR file,)
#  then runs the script to connect this Web Adaptor to a Portal.
#
#  This is clumsy because it means starting Tomcat as a daemon,
#  then waiting for it to start, then running the ESRI script,
#  and then (in the Dockerfile CMD) sleeping. It would be
#  tidier to start Tomcat in foreground mode instead but that
#  leaves the WebAdaptor unconfigured.
#
#  This script needs to build URLs for both the WebAdaptor
#  and the Portal. I suspect that I could run the configuration
#  over REST from outside the container since the use of
#  URLs implies it could be run from anywhere that has 
#  access to the URLs and the user credentials.

if [ "$AGS_USER" = "" -o "$AGS_PASSWORD" = "" ]
then
    echo "Define AGS_USER and AGS_PASSWORD in the environment and try again."
    exit 1
fi

# I need WA_NAME and PORTAL_NAME from the environment (in the
# Dockerfile) and due to the miracle of inconsistency if they
# are FQDN's they won't work. Portal has to be a simple hostname

echo "Is Tomcat running?"
curl --retry 3 -sS "http://127.0.0.1/arcgis/webadaptor" > /tmp/apphttp 2>&1
if [ $? == 7 ]; then
    echo "No Tomcat! Launching.."
    authbind --deep -c ${CATALINA_HOME}/bin/catalina.sh start
    sleep 3
else
    echo "Tomcat is running!"
fi

echo -n "Testing HTTP on ${PORTAL_NAME}.. "
curl --retry 3 -sS "http://${PORTAL_NAME}:7080/arcgis/home" > /tmp/portalhttp 2>&1
if [ $? != 0 ]; then
    echo "HTTP Portal not reachable, start portal and re-run this."
    exit 1
else
    echo "ok!"
fi

echo -n "Testing HTTPS on ${PORTAL_NAME}.. "
curl --retry 3 -sS --insecure "https://${PORTAL_NAME}:7443/arcgis/home" > /tmp/portalhttps 2>&1
if [ $? != 0 ]; then
    echo "HTTPS Portal is not reachable, start portal and re-run this."
    exit 1
else
    echo "ok!"
fi

echo -n "Testing HTTPS on ${WA_NAME}.. "
# Retry a few times in case tomcat is slow starting up
curl --retry 5 -sS --insecure "https://${WA_NAME}/arcgis/webadaptor" > /tmp/apphttps 2>&1
if [ $? != 0 ]; then
    echo "HTTPS Web Adaptor service is not running!"
    echo "Did the WAR file deploy? Look in /var/lib/${TOMCAT}/webapps for arcgis."
    exit 1;
else
    echo "ok!"
fi

# Now that we know both Tomcat and Portal are running, we can
# test the registration and configure Web Adaptor if it's needed.

# Portal server will respond through WA if WA is already configured.
echo -n "Checking portal registration with Web Adaptor.."
curl --retry 3 -sS --insecure "https://${WA_NAME}/arcgis/home" > /tmp/waconfigtest 2>&1
if [ $? == 0 ]; then
    grep -q "Could not access any Portal machines" /tmp/waconfigtest
    if [ $? == 0 ]; then 
        echo "Attempting to register Portal ${PORTAL_NAME}..."
        cd arcgis/webadapt*/java/tools
        ./configurewebadaptor.sh -m portal -u ${AGS_USER} -p ${AGS_PASSWORD} -w https://${WA_NAME}/arcgis/webadaptor -g https://${PORTAL_NAME}:7443
    else
        echo "Portal is already registered!"
    fi
    echo "Now try https://127.0.0.1/arcgis/home in a browser."
else
    echo "Could not reach Web Adaptor at ${WA_NAME}."
fi

tail -f /var/log/tomcat8/catalina.out

