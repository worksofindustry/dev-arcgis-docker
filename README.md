# docker-arcgis-enterprise
Contains separate repos for for deploying ESRI Arcgis Enterprise on Docker. *Note this is for development purposes only. ERSI software, version 10.6, still uses Java which is not compatible with containerization. JVM on these deployments will ignore container namespaces and cgroups. Producing inconsistent results and over usage of host resources. ERSI has not release a timeline for a rollout to OpenJKD9 or newer, but mentions at ERSI UC Conference 2019 could be anywhere from 2020
to 2022. Sub repositories forked from https://github.com/Wildsong/docker-arcgis-enterprise

Each of these folders contains files to build a separate Docker image:

* arcgis-server/
* portal-for-arcgis/
* web-adaptor/
* datastore/

## Create a network

To connect the separate dockers together and enable the use of hostnames
requires creating a custom network.

Use this command:

    docker network create ersi

Each of the provided scripts in this repo assumes you use
"ersi" as the network name for the user defined bridge network so the
different containers can find each other without having to manually link them.

You only have to do this once, it hangs around in your docker engine.

Append these addresses to /etc/hosts file so that name lookups work so you don't 
have to fiddle with locating the container IPs. For example,

    cat >> /etc/hosts
    127.0.0.1 portal portal.ersi 
    127.0.0.1 server server.ersi
    127.0.0.1 web-adaptor web-adaptor.ersi
    127.0.0.1 datastore datastore.ersi

You don't have to use "ersi", but if you change that then change AGS_DOMAIN too, see below.

## Build everything

* Download archives from ESRI. Put each tar.gz file in the appropriate folder.
* Authorize the software with either an .prvc or .ecp file. Use .ecp to enable UI display.
* Create provisioning files for ArcGIS Server and Portal for ArcGIS and put them in their folders.


### Build the containers using Docker Compose

````bash
  docker-compose build
````

When you are done you should be able to see each image with the command "docker images"; 
on my machine I see this:

   REPOSITORY                 	TAG                 IMAGE ID           	 CREATED             SIZE
   husadevops/datastore            latest              1ba423bs3s223   1 minutes ago       1.935 GB
   husadevops/web-adaptor       latest              resdab34fd0cd        2 minutes ago       1.056 GB
   husadevops/portal-for-arcgis latest              2fb2f74507dd        5 minutes ago       8.252 GB
   husadevops/gisserver       latest              d016e14c33d2        4 minutes ago      11.29 GB

## Set environment variables

You have to define three things somewhere in your environment.  I put
them in .bash_profile, and it gets used in each startup
script. Remember to refresh your environment before going on so the
.bash_profile takes effect. (Normally this means starting a new
shell.)

    export AGS_USER="siteadmin"
    export AGS_PASSWORD="yourpasswordhere"
    export AGS_DOMAIN="ersi"

## Run everything

As you run each component, you will get instructions on what to do and
a command prompt. For example, to start arcgis-server from the command
prompt you will be instructed to run the start script, ./start.sh The
session would look something like this:

    $ cd arcgis-server
    $ ./runags 
    Docker is starting in interactive mode.
    Management URL is http://laysan:6080/arcgis/manager
    Start AGS and configure it with  ./start.sh
    ArcGIS Server$ ./start.sh 
    My hostname is server.ersi
    Removing previous site configuration files.
    Starting ArcGIS Server
    Attempting to start ArcGIS Server... Hostname change detected, updating properties...
    
    
    Waiting for ArcGIS Server to start...
    Yes; configuring default site.
    Error: HTTPSConnectionPool(host='server', port=6443): Read timed out. (read timeout=30)
    A timeout here might not mean anything. Try accessing your server.

At this point you should be able to bring up the server in a browser
(use the URL printed by the script) and log into it. Default username
is 'siteadmin' and the password is 'changeit'. As stated above you can override these
by defining AGS_USER and AGS_PASSWORD in the environment before
you run the start.sh script. (Note, start.sh calls the script "create_new_site.py".)

Then continue to open additional (shell terminal) windows and start
the other components in this order: portal-for-arcgis, web-adaptor,
datastore.

## Resources

You can learn a lot about how ESRI thinks provisioning should be done by reading the source
code from their [Github Chef](https://github.com/Esri/arcgis-cookbook) repository. For example, here is
the code that creates a site by using REST. This is ruby code from
arcgis-cookbook/cookbooks/arcgis-enterprise/libraries/server_admin_client.rb
that is pretty easy to read, basically it's filling in a form and sending it.

      log_settings = {
        'logLevel' => log_level,
        'logDir' => log_dir,
        'maxErrorReportsCount' => 10,
        'maxLogFileAge' => max_log_file_age }

      request = Net::HTTP::Post.new(URI.parse(
        @server_url + '/admin/createNewSite').request_uri)

      request.set_form_data('username' => @admin_username,
                            'password' => @admin_password,
                            'configStoreConnection' => config_store_connection.to_json,
                            'directories' => directories.to_json,
                            'settings' => log_settings.to_json,
                            'cluster' => '',
                            'f' => 'json')

      response = send_request(request, @server_url)

      validate_response(response)
