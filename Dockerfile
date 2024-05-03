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
RUN echo "JAVA_HOME=/opt/java/openjdk" >> /etc/environment
RUN echo "PATH=/opt/java/openjdk/bin:$PATH" >> /etc/environment

# install powershell
RUN apt-get install -y apt-transport-https software-properties-common
RUN source /etc/os-release
RUN wget -q https://packages.microsoft.com/config/ubuntu/$UBUNTU_VERSION/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN rm packages-microsoft-prod.deb
RUN apt-get update
RUN apt-get install -y powershell

# install vagrant
RUN \
  wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpgecho "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | tee /etc/apt/sources.list.d/hashicorp.listsudo apt update \
  && apt install -y vagrant

# install vmware workstation
RUN mkdir -p /opt/vmware/datastore
COPY ./assets/vmware-installer.bundle /vmware-installer.bundle
RUN chmod +x /vmware-installer.bundle
RUN \
  yes '' | /vmware-installer.bundle \
  -s vmware-player-app softwareUpdateEnabled no \
  -s vmware-player-app dataCollectionEnabled no \
  -s vmware-workstation-server hostdUser ${USERNAME} \
  -s vmware-workstation-server datastore /opt/vmware/datastore \
  -s vmware-workstation-server httpsPort 443 \
  -s vmware-workstation serialNumber ${VMWARE_SERIAL_NUMBER}

# install vagrant vmware utility
RUN apt install -y linux-headers-`uname -r`
RUN apt-get install -y build-essential
RUN vmware-modconfig --install-all --console
RUN curl https://releases.hashicorp.com/vagrant-vmware-utility/1.0.22/vagrant-vmware-utility_1.0.22-1_amd64.deb -o vagrant-vmware-utility.deb
RUN dpkg -i vagrant-vmware-utility.deb
RUN rm vagrant-vmware-utility.deb
RUN /opt/vagrant-vmware-desktop/bin/vagrant-vmware-utility certificate generate

# install vagrant vmware plugin
RUN vagrant plugin install vagrant-vmware-desktop

CMD ["/usr/sbin/sshd", "-D"]