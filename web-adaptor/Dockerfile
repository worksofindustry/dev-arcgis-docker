From husadevops/tomcat:latest
LABEL maintainer="matt.linker@hydromaxusa.com"
ENV ESRI_VERSION=10.6 WA_NAME=web-adaptor.esri PORTAL_NAME=portal.esri

EXPOSE 80 443

# Prerequisites: Before doing a "docker build", 
# Put a downloaded copy of the web adaptor installer
# in the same folder as this Dockerfile

ENV HOME=/home/tomcat CATALINA_APPS=/CATALINA_APPS AGS_USER=siteadmin AGS_PASSWORD=Sleepyhollow

RUN apt-get update && apt-get install python3 -y && apt-get update && \
	apt-get install python-pip -y && apt-get install curl -y && pip install requests && \
	apt-get install libglib2.0 -y && apt-get install net-tools -y && \
	apt-get install authbind -y
	
RUN cd / && mkdir CATALINA_APPS && chmod 0777 -R /CATALINA_APPS

# NOTE that CATALINA_BASE is where the app server's files live (owned by root)
# and that the unprivileged user (tomcat) has its own HOME (owned by tomcat).
# This is done to accomodate running the installation as an unprivileged user
# and giving ESRI a place to stash the .ESRI properties file.

# "ADD" knows how to unpack the tar file directly into the Docker image.
ADD Web_Adaptor_Java_Linux_*.tar.gz ${HOME}

# Installation should be done as an unprivileged user.
USER ${TOMCAT}

# Run the ESRI installer script with these options:
#   -m silent         silent mode: don't pop up windows, we don't have a screen
#   -l yes            Agree to the License Agreement
#   -d target dir     ESRI default puts the files in wrong place
#
RUN cd ${HOME}/WebAdaptor && ./Setup -m silent --verbose -l yes -d ${HOME}

# Deploy the WAR file; requires ROOT. CATALINA_APPS is defined in /CATALINA_APPS
USER root
RUN cp ${HOME}/arcgis/webadaptor*/java/arcgis.war ${CATALINA_APPS}

# Once we're done with the installer files, we can delete them.
#RUN rm -rf ${HOME}/WebAdaptor

RUN chown -R ${TOMCAT}:${TOMCAT} /var/log/${TOMCAT} ${HOME}

WORKDIR ${HOME}

# Drop privileges, no need to run as root.
USER ${TOMCAT}

# Change command line prompt
ADD bashrc .bashrc

# The hostname will be changed in the final run command so we need to fix up the name
# of the properties file to match.
RUN mv /home/tomcat/.ESRI.properties* .ESRI.properties.$WA_NAME.$ESRI_VERSION

# Add a script that can start web adaptor and configure it
ADD start.sh .

# Add a script that can test the connection to the portal.
ADD check_portal.py .

RUN chmod 0777 start.sh && chmod 0777 check_portal.py

# FIXME There is a web adaptor health URL, I should wedge that in here
# HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -sS 127.0.0.1 || exit 1

CMD ./start.sh 
# && tail -f /var/log/${TOMCAT}/catalina.out
