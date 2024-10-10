# Use the official Apache Tomcat 9.0 image as the base
FROM tomcat:9.0

# Remove the default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR file to the location referred to in the ROOT context file
COPY dist/xproc-z.war /usr/local/xproc-z.war

# Copy the Tomcat context file
COPY docker/ROOT.xml /usr/local/tomcat/conf/Catalina/localhost/

# Copy the default main xproc pipeline
COPY docker/xproc-z.xpl /var/lib/xproc-z/xproc/

# Expose the default Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
