From husadevops/ubuntu:1.0
LABEL maintainer="matt.linker@hydromaxusa.com"
ENV ESRI_VERSION=10.6
USER root

# Port information:https://enterprise.arcgis.com/en/portal/10.6/install/linux/ports-used-by-portal-for-arcgis.htm
EXPOSE 7080 7443

# Default limits are too high and software will not install, set to spec as outlined by ESRI
ADD limits.conf /etc/security/limits.conf

RUN apt-get update && apt-get install python3 -y && apt-get update && \
	apt-get install python-pip -y && apt-get install curl -y && pip install requests && \
	apt-get install libglib2.0 -y && apt-get install net-tools -y

ENV HOME=/home/arcgis HOSTNAME=10.0.100.51 AGS_DOMAIN=esri AGS_USER=siteadmin AGS_PASSWORD=Sleepyhollow

# Put your license file and a downloaded copy of the server software
# in the same folder as this Dockerfile
ADD *.prvc /home/arcgis
# "ADD" knows how to unpack the tar file directly into the docker image.
ADD Portal_for_ArcGIS_Linux_10*.tar.gz /home/arcgis

# Add the script that can create the initial admin user and site
# I can't actually run the create_new_site.py here because it will have
# the usual problems (server must be running already)
ADD create_new_site.py ${HOME}/
# Instead this script will run create_new_site.py..
ADD start.sh ${HOME}
RUN chmod 0777 ${HOME}/start.sh

# Script that changes a string to uppercase, because of HOSTNAME in logfiles
ADD UPPER.py ${HOME}/

# Change owner so that user "arcgis" can remove installer later.
RUN chown -R arcgis:arcgis $HOME

# Start in the arcgis user's home directory.
WORKDIR ${HOME}
USER arcgis
# ESRI uses LOGNAME
ENV LOGNAME arcgis

# Create a spot where the volatile content can live
RUN mkdir -p portal/usr/arcgisportal

# Change command line prompt
ADD bashrc ./.bashrc


# It's okay to use the random Docker hostname at this point, but
# we have to fix up the properties filename and we have to use
# a proper FQDN when we configure the host. That means config has
# to wait until we run the container.
#
# Run the ESRI installer script as user 'arcgis' with these options:
#   -m silent         silent mode: don't pop up windows, we don't have a screen anyway
#   -l yes            You agree to the License Agreement
#   -a license_file   Use "license_file" to add your license. It can be a .ecp or .prvc file.
#   -d dest_dir       Default is /home/arcgis/arcgis/portal
RUN cd PortalForArcGIS && ./Setup -m silent --verbose -l yes -a $HOME/*.prvc -d $HOME

# We are done with the installer, get rid of it now.
RUN rm -rf PortalForArcGIS

# Set path so we can run psql from bash shell
# Note that it's listening on port 7654, so try
# psql -h localhost -p 7654 -U siteadmin gwdb
ENV PATH $PATH:${HOME}/portal/framework/runtime/pgsql/bin

# I will need to clean out some of this folder before starting configuration
# so that it does not fire up the "automatic migration" mode which then fails.
VOLUME [ "$HOME/portal/usr/arcgisportal" ]

HEALTHCHECK --interval=60s --timeout=10s --retries=3 CMD curl -sS 127.0.0.1:7080 || exit 1

CMD cd /home/arcgis 
# && ./start.sh && tail -f portal/usr/arcgisportal/logs/service.log
