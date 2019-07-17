From husadevops/ubuntu:1.0
LABEL maintainer="matt.linker@hydromaxusa.com"
ENV ESRI_VERSION 10.6


EXPOSE 6080 6443 6445 6450
# If you are not using a Docker network to connect containers
# you might want to expose these ports, too.
# EXPOSE 1098 4000 4001 4002 4003 4004 6006 6099

# Refer to ESRI docs; this expands limits for user gisowner.
ADD limits.conf /etc/security/limits.conf

# Setting necessary environment variables
ENV HOME=/home/gisowner/ HOSTNAME=server ESRI_VERSION=10.6 AGS_USERNAME=gisowner AGS_PASSWORD=Sleepyhollow

# COPY <all> <the> <things> <last-arg-is-destination>
COPY *.prvc start.sh create_new_site.py ${HOME}

# ADD will automatically extract .tar
ADD ArcGIS_Server_Linux_106*.tar.gz ${HOME}

# create_new_site.py can create the initial admin user and site
# start.sh will run create_new_site.py
# Place the provisioning file or authorization file '.ecp' in the same folder as this Dockerfile. 

# This step is necessary for cleaning up installation files
RUN chown -R gisowner.gisowner ${HOME} && chmod 0777 ${HOME}start.sh

RUN apt-get install curl -y  &&  apt-get install -y net-tools && \
	apt-get install python3 -y && apt-get update && apt-get install python-pip -y && \
	pip install requests && apt-get install libglib2.0 -y && apt-get install net-tools -y

# Start in gisowner user's home directory.
WORKDIR ${HOME}
USER gisowner
# ESRI uses this in some scripts (including 'backup')
ENV LOGNAME gisowner

# Run the ESRI installer script as user 'gisowner' with these options:
#   -m silent         silent mode: don't pop up windows, we don't have a screen
#   -l yes            Agree to the License Agreement
# RUN cd ArcGISServer && ./Setup -m silent --verbose -l yes
# appears the software is already installed with shipped image
RUN cd ArcGISServer && ./Setup -m silent --verbose -l yes -a ${HOME}*.prvc

# After Setup is complete, delete installer to free up space.  
# If you are a developer you might want to leave it to get access to diagnostics, see
# http://server.arcgis.com/en/server/latest/administer/linux/checking-server-diagnostics-using-the-diagnostics-tool.htm
RUN rm -rf ${HOME}/ArcGISServer

# Create these volumes to make it possible to persist ArcGIS Server's data
VOLUME ["${HOME}server/usr/config-store", \
        "${HOME}server/usr/directories", \
        "${HOME}server/usr/logs"]

# Change command line prompt
ADD bashrc ./.bashrcdo

# Check the HTTP service
# HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -sS 127.0.0.1:6080 || exit 1


# Strating up the service once the container, comes online. 
# Note, if running in Kuberntes, comment out below, and place the 
# command inside of the pod spec,  spec.containers.command
ENTRYPOINT ["/home/gisowner/start.sh"]

CMD ["echo $HOSTNAME is now running"]