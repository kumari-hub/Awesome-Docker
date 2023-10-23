FROM ubuntu:20.04
CMD echo "Hello, World!"
# This is in accordance to : https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-get-on-ubuntu-16-04
RUN apt-get update && \ 
apt-get install apt-utils && \
apt-get install -y openjdk-8-jdk && \ 
apt-get install -y ant && \ 
apt-get install -y curl && \ 
apt-get install -y sudo && \ 
apt-get clean && \ 
rm -rf /var/lib/apt/lists/* && \ 
rm -rf /var/cache/oracle-jdk8-installer; 

# Fix certificate issues, found as of 
# https://bugs.launchpad.net/ubuntu/+source/ca-certificates-java/+bug/983302
RUN apt-get update && \ 
apt-get install -y ca-certificates-java && \ 
apt-get clean && \ 
update-ca-certificates -f && \ 
rm -rf /var/lib/apt/lists/* && \ 
rm -rf /var/cache/oracle-jdk8-installer;  

#Setup JAVA_HOME, this is useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/ 
RUN export JAVA_HOME
# ENV INSTALL4J_JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
# RUN export INSTALL4J_JAVA_HOME
# RUN echo "This is a diagnostic message"
RUN echo "JAVA_HOME is set to: $JAVA_HOME"
# Create a shell script to print the Java version during container runtime
RUN echo '#!/bin/sh' > /print-java-version.sh && \
    echo 'java -version' >> /print-java-version.sh && \
    chmod +x /print-java-version.sh

# Print the Java version using the shell script
CMD ["/print-java-version.sh"]

WORKDIR /opt/
#Create a new dedicated user for the Nexus with the name 'nexus'

RUN groupadd --gid 200 -r <GROUP_NAME>
RUN useradd --uid 200 -r <USER_NAME> -g <GROUP_NAME>
RUN echo '<USER_NAME>':'<PASSWORD>' | chpasswd
RUN usermod -aG sudo <USER_NAME>


# Download and install Nexus Repository Manager
RUN curl -L -o /tmp/nexus.tar.gz https://download.sonatype.com/nexus/3/nexus-3.61.0-02-unix.tar.gz && \
    tar -xzf /tmp/nexus.tar.gz -C /opt && \
    mv /opt/nexus-* /opt/nexus && \
    rm /tmp/nexus.tar.gz 

RUN chown -R <USER_NAME>:<GROUP_NAME> /opt/nexus /opt/sonatype-work
RUN chown -R <USER_NAME>:<GROUP_NAME> /opt/sonatype-work/nexus3
RUN echo 'run_as_user="<USER_NAME>"'  > /opt/nexus/bin/nexus.rc

COPY nexus.service /etc/systemd/system/
COPY nexus.vmoptions /etc/nexus/bin/

RUN echo "#!/bin/bash" >> /opt/start-nexus-repository-manager.sh \
   && echo "cd /opt/nexus" >> /opt/start-nexus-repository-manager.sh \
   && echo "exec ./bin/nexus run" >> /opt/start-nexus-repository-manager.sh \
   && chmod a+x /opt/start-nexus-repository-manager.sh
 #  && sed -e '/^nexus-context/ s:$:'':' -i /opt/nexus/nexus/etc/nexus-default.properties

# Expose Nexus port
EXPOSE 8081
RUN sleep 30
USER <USER_NAME>
ENV INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m -Djava.util.prefs.userRoot=/nexus-data/javaprefs"
CMD ["/opt/nexus/bin/nexus", "run"]


