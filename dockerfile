# IBM Spectrum LSF Community Edition 10.1

FROM centos:7.9.2009

# Install required Packages
RUN yum -q clean all \
    && yum install -y \
        ed \
        initscripts \
        lsof \
        sysstat \
        gettext \
        which \
    && rm -rf /var/cache/yum

# create lsfadmin user and set password to lsfadmin
RUN useradd -s /bin/bash -m lsfadmin \
    && echo "lsfadmin:lsfadmin" | chpasswd


# Set Package name
ENV LSF=lsfsce10.2.0.12-x86_64.tar.gz

# Copy LSF Package
RUN mkdir -p /var/lsfce
COPY $LSF /var/lsfce/
COPY "start_lsf_ce.sh" /

# Uncompress Package
RUN cd /var/lsfce \
    && tar xzf $LSF \
    && tar xzf lsfsce10.2.0.12-x86_64/lsf/lsf10.1_lsfinstall_linux_x86_64.tar.Z -C /var/lsfce/lsfsce10.2.0.12-x86_64/lsf

# prepare LSF install configuration file
RUN cd /var/lsfce/lsfsce10.2.0.12-x86_64/lsf/lsf10.1_lsfinstall \
    && echo "LSF_TOP=/opt/ibm/lsf" >> install.config \
    && echo "LSF_ADMINS=lsfadmin" >> install.config \
    && echo "LSF_CLUSTER_NAME=cluster1" >> install.config \
    && echo "LSF_MASTER_LIST=lsfdocker" >> install.config \
    && echo "LSF_TARDIR=/var/lsfce/lsfsce10.2.0.12-x86_64/lsf" >> install.config \
    && echo "ENABLE_STREAM=Y" >> install.config \  
    && echo "SILENT_INSTALL=Y" >> install.config \
    && echo "LSF_SILENT_INSTALL_TARLIST=ALL" >> install.config \
    && echo "ACCEPT_LICENSE=Y" >> install.config \
    && echo "ENABLE_DYNAMIC_HOSTS=Y" >> install.config \
    && echo "LSF_DYNAMIC_HOST_WAIT_TIME=1" >> install.config

# install LSF
RUN echo "start install LSF..." \
    && cd /var/lsfce/lsfsce10.2.0.12-x86_64/lsf/lsf10.1_lsfinstall \
    && ./lsfinstall -f install.config \
    && source /opt/ibm/lsf/conf/profile.lsf \
    && lsadmin limstartup \
    && lsadmin resstartup \
    && badmin hstartup \
    && echo "LSF installation has successfully completed."

# cleanup residual package files
RUN chmod +x /start_lsf_ce.sh \
    && rm -rf /var/lsfce \
    && rm -rf /opt/ibm/lsf/10.1/install \
    && rm -rf /opt/ibm/lsf/log/* \
    && rm -rf /tmp/*

ENTRYPOINT ["/start_lsf_ce.sh"]
