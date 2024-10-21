# Use the official Apache Tomcat 9.0 image as the base
FROM tomcat:9.0

# Remove the default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Mount the XProc-Z codebase into the location "/source" in the image-building container,
# install the Ant build tool and use it to build the XProc-Z web app (war) file, 
# copy the web application to /usr/local/xproc-z.war as specified in Tomcat's 'ROOT.xml' file,
# then clean up by uninstalling Ant and clearing the apt package cache.
WORKDIR /source
RUN \
    --mount=type=bind,target=/source,readwrite \
	apt-get update &&  \
	apt-get install ant -y && \
	ant && \
    cp /source/dist/xproc-z.war /usr/local/xproc-z.war && \
	apt-get remove ant -y && \
	rm -rf /var/lib/apt/lists/*
WORKDIR /

# Copy the Tomcat context file
COPY docker/ROOT.xml /usr/local/tomcat/conf/Catalina/localhost/

# Copy the default main xproc pipeline
COPY docker/xproc-z.xpl /var/lib/xproc-z/xproc/

# Expose the default Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
