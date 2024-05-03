# Description: Dockerfile for jenkins agent
# Installed Packages:
#   Powershell
#   Vagrant
#   VMware Workstation
#   JDK 17.0.10+7

FROM eclipse-temurin:17.0.10_7-jdk-jammy
ARG JENKINS_PUBLIC_KEY
ARG JENKINS_SSH_PORT
ARG UBUNTU_VERSION
ARG VMWARE_SERIAL_NUMBER

EXPOSE ${JENKINS_SSH_PORT}
SHELL ["/bin/bash", "-c"]

# install dependencies
RUN apt-get update 
RUN apt-get install -y wget
# install open ssh server and configure it
RUN apt-get install -y openssh-server
RUN mkdir -p /run/sshd
# install jenkins public key
RUN mkdir -p /jenkins
RUN mkdir -p ~/.ssh
RUN echo $JENKINS_PUBLIC_KEY > ~/.ssh/authorized_keys
RUN chmod 600 ~/.ssh/authorized_keys
RUN chmod 700 ~/.ssh
# configure ssh
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i '/^UseDNS /c\UseDNS no' /etc/ssh/sshd_config || echo 'UseDNS no' >> /etc/ssh/sshd_config
RUN sed -i "s/#Port 22/Port $JENKINS_SSH_PORT/" /etc/ssh/sshd_config
RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config
# add java to path
ENV JAVA_HOME=/opt/java/openjdk
RUN echo "JAVA_HOME=${JAVA_HOME}" >> /etc/environment
RUN sed -i "/^PATH=/c\\PATH=${JAVA_HOME}/bin:$PATH" /etc/environment

# install powershell
RUN apt-get install -y apt-transport-https software-properties-common
RUN source /etc/os-release
RUN wget -q https://packages.microsoft.com/config/ubuntu/$UBUNTU_VERSION/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update
RUN apt-get install -y powershell

CMD ["/usr/sbin/sshd", "-D"]