ARG BASE=${BASE:-ubuntu:20.04}
FROM ${BASE}

MAINTAINER DrSnowbird "DrSnowbird@openkbs.org"

ENV DEBIAN_FRONTEND noninteractive

ENV JAVA_VERSION=11

##################################
#### ---- Tools: setup   ---- ####
##################################
ENV LANG C.UTF-8

ARG LIB_DEV_LIST="apt-utils" # automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev
ARG LIB_BASIC_LIST="curl wget unzip ca-certificates" # iputils-ping nmap net-tools build-essential software-properties-common apt-transport-https
ARG LIB_COMMON_LIST="sudo bzip2 git xz-utils vim xz-utils net-tools"
ARG LIB_TOOL_LIST="graphviz libsqlite3-dev sqlite3"

RUN set -eux; \
    apt-get update -y && \
    apt-get install -y --no-install-recommends ${LIB_DEV_LIST} && \
    apt-get install -y --no-install-recommends ${LIB_BASIC_LIST} && \
    apt-get install -y --no-install-recommends ${LIB_COMMON_LIST} && \
    apt-get install -y --no-install-recommends ${LIB_TOOL_LIST} && \
    apt-get install -y sudo && \
    apt-get clean -y && apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf

##############################################
#### ---- Installation Directories   ---- ####
##############################################
ENV INSTALL_DIR=${INSTALL_DIR:-/usr}
ENV SCRIPT_DIR=${SCRIPT_DIR:-$INSTALL_DIR/scripts}


########################################
#### ------- OpenJDK Installation ------
########################################
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
#ENV LANG en_US.utf8

# A few reasons for installing distribution-provided OpenJDK:
#
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#     really hairy.
#
#     For some sample build times, see Debian's buildd logs:
#       https://buildd.debian.org/status/logs.php?pkg=openjdk-8

#RUN apt-get update && apt-get install -y --no-install-recommends \
#		bzip2 \
#		unzip \
#		xz-utils \
#	&& rm -rf /var/lib/apt/lists/*

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# ------------------
# OpenJDK Java:
# ------------------
ARG OPENJDK_PACKAGE=${OPENJDK_PACKAGE:-openjdk-${JAVA_VERSION}-jdk}

# -- To install JDK Source (src.zip), uncomment the line below: --
#ARG OPENJDK_SRC=${OPENJDK_SRC:-openjdk-${JAVA_VERSION}-source}

ARG OPENJDK_INSTALL_LIST="${OPENJDK_PACKAGE} ${OPENJDK_SRC}"

RUN apt-get update -y && \
    apt-get install -y ${OPENJDK_INSTALL_LIST} && \
    ls -al ${INSTALL_DIR} ${JAVA_HOME} && \
    export PATH=$PATH ; echo "PATH=${PATH}" ; export JAVA_HOME=${JAVA_HOME} ; echo "java=`which java`" && \
    rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------------------------------------------
# update-alternatives so that future installs of other OpenJDK versions don't change /usr/bin/java
# ... and verify that it actually worked for one of the alternatives we care about
# ------------------------------------------------------------------------------------------------
RUN update-alternatives --get-selections | awk -v home="$(readlink -f "$JAVA_HOME")" 'index($3, home) == 1 { $2 = "manual"; print | "update-alternatives --set-selections" }'; \
	update-alternatives --query java | grep -q 'Status: manual'

############################################
##### ---- System: certificates : ---- #####
##### ---- Corporate Proxy      : ---- #####
############################################
COPY ./scripts ${SCRIPT_DIR}
COPY certificates /certificates
RUN ${SCRIPT_DIR}/setup_system_certificates.sh
RUN ${SCRIPT_DIR}/setup_system_proxy.sh

###################################
#### ---- Install Maven 3 ---- ####
###################################
ENV MAVEN_VERSION=${MAVEN_VERSION:-3.8.5}
ENV MAVEN_HOME=/usr/apache-maven-${MAVEN_VERSION}
ARG MAVEN_PACKAGE=apache-maven-${MAVEN_VERSION}-bin.tar.gz
ENV PATH=${PATH}:${MAVEN_HOME}/bin
# https://dlcdn.apache.org/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz
RUN export MAVEN_PACKAGE_URL=$(curl -s https://maven.apache.org/download.cgi | grep -e "apache-maven.*bin.tar.gz" | head -1|cut -d'"' -f2) && \
    export MAVEN_VERSION=$(echo ${MAVEN_PACKAGE_URL}| cut -d'/' -f6) && \
    export MAVEN_HOME=/usr/apache-maven-${MAVEN_VERSION} && \
    export MAVEN_PACKAGE=apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    export PATH=${PATH}:${MAVEN_HOME}/bin && \
    curl -k -sL ${MAVEN_PACKAGE_URL} | gunzip | tar x -C /usr/ && \
    ln -s ${MAVEN_HOME}/bin/mvn /usr/bin/mvn && \
    ${MAVEN_HOME}/bin/mvn -v && \
    rm -f ${MAVEN_PACKAGE}

###################################
#### ---- Install Gradle ---- #####
###################################
# Ref: https://gradle.org/releases/

ENV GRADLE_INSTALL_BASE=${GRADLE_INSTALL_BASE:-/opt/gradle}
ENV GRADLE_VERSION=${GRADLE_VERSION:-7.4.1}
ENV GRADLE_HOME=${GRADLE_INSTALL_BASE}/gradle-${GRADLE_VERSION}
ENV GRADLE_PACKAGE=gradle-${GRADLE_VERSION}-bin.zip
ENV GRADLE_PACKAGE_URL=https://services.gradle.org/distributions/${GRADLE_PACKAGE}

RUN mkdir -p ${GRADLE_INSTALL_BASE} && \
    cd ${GRADLE_INSTALL_BASE} && \
    export GRADLE_PACKAGE_URL=$(curl -k -s https://gradle.org/releases/ | grep "Download: " | head -1 | cut -d'"' -f4) && \
    export GRADLE_VERSION=$(curl -k -s https://gradle.org/releases/ | grep "Download: " | head -1 | cut -d'-' -f2) && \
    export GRADLE_HOME=${GRADLE_INSTALL_BASE}/gradle-${GRADLE_VERSION} && \
    export GRADLE_PACKAGE=gradle-${GRADLE_VERSION}-bin.zip && \
    wget -q --no-check-certificate -c ${GRADLE_PACKAGE_URL} && \
    unzip -d ${GRADLE_INSTALL_BASE} ${GRADLE_PACKAGE} && \
    find ${GRADLE_INSTALL_BASE} && \
    ln -s ${GRADLE_HOME}/bin/gradle /usr/bin/gradle && \
    ${GRADLE_HOME}/bin/gradle -v && \
    rm -f ${GRADLE_PACKAGE}

###################################
#### ---- user: developer ---- ####
###################################
ENV USER_ID=${USER_ID:-1000}
ENV GROUP_ID=${GROUP_ID:-1000}

ENV USER=${USER:-developer}
ENV HOME=/home/${USER}

ENV APP_HOME=${APP_HOME:-$HOME/app}
ENV APP_MAIN=${APP_MAIN:-setup.sh}


## -- setup NodeJS user profile
RUN groupadd ${USER} && useradd ${USER} -m -d ${HOME} -s /bin/bash -g ${USER} && \
    ## -- Ubuntu -- \
    usermod -aG sudo ${USER} && \
    ## -- Centos -- \
    #usermod -aG wheel ${USER} && \
    echo "${USER} ALL=NOPASSWD:ALL" | tee -a /etc/sudoers && \
    echo "USER =======> ${USER}" && ls -al ${HOME}

##############################################
#### ---- USER as Owner for /scripts ---- ####
##############################################
RUN chown ${USER}:${USER} -R ${INSTALL_DIR}/scripts

#########################
#### ---- App:  ---- ####
#########################
COPY --chown=$USER:$USER ./app $HOME/app

#########################################
##### ---- Setup: Entry Files  ---- #####
#########################################
COPY --chown=${USER}:${USER} docker-entrypoint.sh /
COPY --chown=${USER}:${USER} ${APP_MAIN} ${APP_HOME}/setup.sh
RUN sudo chmod +x /docker-entrypoint.sh ${APP_HOME}/setup.sh 

#########################################
##### ---- Docker Entrypoint : ---- #####
#########################################
ENTRYPOINT ["/docker-entrypoint.sh"]

#####################################
##### ---- user: developer ---- #####
#####################################
WORKDIR ${APP_HOME}
USER ${USER}

######################
#### (Test only) #####
######################
#CMD ["/bin/bash"]
######################
#### (RUN setup) #####
######################
CMD ["setup.sh"]

