# OpenJDK Java 11 + Maven 3 + Gradle 7

[![](https://images.microbadger.com/badges/image/openkbs/jdk-maven-gradle-docker.svg)](https://microbadger.com/images/openkbs/jdk-maven-gradle-docker "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/openkbs/jdk-maven-gradle-docker.svg)](https://microbadger.com/images/openkbs/jdk-maven-gradle-docker "Get your own version badge on microbadger.com")

# ** This build is based upon Ubuntu 20.04 + OpenJDK Java 11 (default - changeable by you) **

# ** Currently Docker Hub not allowing for free hosting for Docker images: Please run ./build.sh first by yourself locally **

# NOTICE: ''Change to use Non-Root implementation''
This new release is designed to support the deployment for Non-Root child images implementations and deployments to platform such as OpenShift or RedHat host operating system which requiring special policy to deploy. And, for better security practice, we decided to migrate (eventaully) our Docker containers to use Non-Root implementation. 
Here are some of the things you can do if your images requiring "Root" acccess - you `really` want to do it:
1. For Docker build: Use "sudo" or "sudo -H" prefix to your Dockerfile's command which requiring "sudo" access to install packages.
2. For Docker container (access via shell): Use "sudo" command when you need to access root privilges to install packages or change configurations.
3. Or, you can use older version of this kind of base images which use "root" in Dockerfile.
4. Yet, you can also modify the Dockerfile at the very bottom to remove/comment out the "USER ${USER}" line so that your child images can have root as USER.
5. Finally, you can also, add a new line at the very top of your child Docker image's Dockerfile to include "USER root" so that your Docker images built will be using "root".

We like to promote the use of "Non-Root" images as better Docker security practice. And, whenever possible, you also want to further confine the use of "root" privilges in your Docker implementation so that it can prevent the "rooting hacking into your Host system". To lock down your docker images and/or this base image, you will add the following line at the very end to remove sudo: `(Notice that this might break some of your run-time code if you use sudo during run-time)`
```
sudo agt-get remove -y sudo
```
After that, combining with other Docker security practice (see below references), you just re-build your local images and re-deploy it as non-development quality of docker container. However, there are many other practices to secure your Docker containes. See below:

* [Docker security | Docker Documentation](https://docs.docker.com/engine/security/security/)
* [5 tips for securing your Docker containers - TechRepublic](https://www.techrepublic.com/article/5-tips-for-securing-your-docker-containers/)
* [Docker Security - 6 Ways to Secure Your Docker Containers](https://www.sumologic.com/blog/security/securing-docker-containers/)
* [Five Docker Security Best Practices - The New Stack](https://thenewstack.io/5-docker-security-best-practices/)

# Components
* Ubuntu 20.04 LTS now as LTS Docker base image.

* openjdk version "11.0.13" 2021-10-19
  OpenJDK Runtime Environment (build 11.0.13+8-Ubuntu-0ubuntu1.20.04)
  OpenJDK 64-Bit Server VM (build 11.0.13+8-Ubuntu-0ubuntu1.20.04, mixed mode, sharing)
* Apache Maven 3.8+
* Gradle 7.4+
* Other tools: git wget unzip vim python python-setuptools python-dev python-numpy, ..., etc.
* [See Releases Information](https://github.com/DrSnowbird/jdk-maven-gradle-docker/blob/master/README.md#Releases-information)

# Quick commands
* build.sh - build local image
* logs.sh - see logs of container
* run.sh - run the container
* shell.sh - shell into the container
* stop.sh - stop the container
* tryJava.sh : test Java

# How to use and quick start running?
1. git clone https://github.com/DrSnowbird/jdk-maven-gradle-docker.git
2. cd jdk-maven-gradle-docker
3. ./run.sh

# Default Run (test) - Just entering Container
```
./build.sh or 'make build'
./run.sh
```

# Test Java, NodeJS, and Python3 Runs
```
./tryJava.sh

```
# Default Build (locally)
```
./build.sh
```
# Pull the image from Docker Repository

```bash
docker pull openkbs/jdk-maven-gradle-docker
```

# Base the image to build add-on components

```Dockerfile
FROM openkbs/jdk-maven-gradle-docker
... (then your customization Dockerfile code here)
```

# Manually setup to Run the image

Then, you're ready to run:
- make sure you create your work directory, e.g., ./data

```bash
mkdir ./data
docker run -d --name my-jdk-maven-gradle-docker -v $PWD/data:/data -i -t openkbs/jdk-maven-gradle-docker
```

# Build and Run your own image
Say, you will build the image "my/jdk-maven-gradle-docker".

```bash
docker build -t my/jdk-maven-gradle-docker .
```

To run your own image, say, with some-jdk-maven-gradle-docker:

```bash
mkdir ./data
docker run -d --name some-jdk-maven-gradle-docker -v $PWD/data:/data -i -t my/jdk-maven-gradle-docker
```

# Shell into the Docker instance

```bash
docker exec -it some-jdk-maven-gradle-docker /bin/bash
```


# Compile or Run java -- while no local installation needed
Remember, the default working directory, /data, inside the docker container -- treat is as "/".
So, if you create subdirectory, "./data/workspace", in the host machine and 
the docker container will have it as "/data/workspace".

```
#!/bin/bash -x
mkdir ./data
cat >./data/HelloWorld.java <<-EOF
public class HelloWorld {
   public static void main(String[] args) {
      System.out.println("Hello, World");
   }
}
EOF
cat ./data/HelloWorld.java
alias djavac='docker run -it --rm --name some-jdk-maven-gradle-docker -v '$PWD'/data:/data openkbs/jdk-maven-gradle-docker javac'
alias djava='docker run -it --rm --name some-jdk-maven-gradle-docker -v '$PWD'/data:/data openkbs/jdk-maven-gradle-docker java'
djavac HelloWorld.java
djava HelloWorld
```
And, the output:
```
Hello, World
```
Hence, the alias above, "djavac" and "djava" is your docker-based "javac" and "java" commands and 
it will work the same way as your local installed Java's "javac" and "java" commands. 

# Run JavaScript -- while no local installation needed
Run the NodeJS mini-server script:
```
./tryNodeJS.sh
```
Then, open web browser to go to http://0.0.0.0:3000/ to NodeJS mini-web server test.

# Python Virtual Environments
There are various ways to run Python virtual envrionments, for example,

### Setup virtualenvwrapper in $HOME/.bashrc profile
Add the following code to the end of ~/.bashrc
```
#########################################################################
#### ---- Customization for multiple virtual python environment ---- ####
#########################################################################
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
source /usr/local/bin/virtualenvwrapper.sh
export WORKON_HOME=~/Envs
if [ ! -d $WORKON_HOME ]; then
    mkdir -p $WORKON_HOME
fi
```

### To create & activate your default venv environment, say, "my-venv":
```
mkvirtualenv my-venv
workon my-venv
```

# To run specialty Java/Scala IDE alternatives
However, for larger complex projects, you might want to consider to use Docker-based IDE. 
For example, try the following Docker-based IDEs:
* [openkbs/docker-atom-editor](https://hub.docker.com/r/openkbs/docker-atom-editor/)
* [openkbs/eclipse-photon-docker](https://hub.docker.com/r/openkbs/eclipse-photon-docker/)
* [openkbs/eclipse-photon-vnc-docker](https://hub.docker.com/r/openkbs/eclipse-photon-vnc-docker/)
* [openkbs/eclipse-oxygen-docker](https://hub.docker.com/r/openkbs/eclipse-oxygen-docker/)
* [openkbs/intellj-docker](https://hub.docker.com/r/openkbs/intellij-docker/)
* [openkbs/intellj-vnc-docker](https://hub.docker.com/r/openkbs/intellij-vnc-docker/)
* [openkbs/knime-vnc-docker](https://hub.docker.com/r/openkbs/knime-vnc-docker/)
* [openkbs/netbeans9-docker](https://hub.docker.com/r/openkbs/netbeans9-docker/)
* [openkbs/netbeans](https://hub.docker.com/r/openkbs/netbeans/)
* [openkbs/papyrus-sysml-docker](https://hub.docker.com/r/openkbs/papyrus-sysml-docker/)
* [openkbs/pycharm-docker](https://hub.docker.com/r/openkbs/pycharm-docker/)
* [openkbs/scala-ide-docker](https://hub.docker.com/r/openkbs/scala-ide-docker/)
* [openkbs/sublime-docker](https://hub.docker.com/r/openkbs/sublime-docker/)
* [openkbs/webstorm-docker](https://hub.docker.com/r/openkbs/webstorm-docker/)
* [openkbs/webstorm-vnc-docker](https://hub.docker.com/r/openkbs/webstorm-vnc-docker/)

# See also
* [Java Development in Docker](https://blog.giantswarm.io/getting-started-with-java-development-on-docker/)
* [Alpine small image JDKs](https://github.com/frol/docker-alpine-oraclejdk8)


# Proxy & Certificate Setup
* [Setup System and Browsers Root Certificate](https://thomas-leister.de/en/how-to-import-ca-root-certificate/)

# Corporate Proxy Root and Intemediate Certificates setup for System and Web Browsers (FireFox, Chrome, etc)
1. Save your corporate's Certificates in the currnet GIT directory, `./certificates`
2. During Docker run command, 
```
   -v `pwd`/certificates:/certificates ... (the rest parameters)
```
If you want to map to different directory for certificates, e.g., /home/developer/certificates, then
```
   -v `pwd`/certificates:/home/developer/certificates -e SOURCE_CERTIFICATES_DIR=/home/developer/certificates ... (the rest parameters)
```
3. And, inside the Docker startup script to invoke the `~/scripts/setup_system_certificates.sh`. Note that the script assumes the certficates are in `/certificates` directory.
4. The script `~/scripts/setup_system_certificates.sh` will automatic copy to target directory and setup certificates for both System commands (wget, curl, etc) to use and Web Browsers'.

# Releases information
```
developer@aurora:~/app$ /usr/scripts/printVersions.sh 
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
java: /usr/bin/java /usr/share/java /usr/lib/jvm/java-11-openjdk-amd64/bin/java /usr/share/man/man1/java.1.gz

/usr/lib/jvm/java-11-openjdk-amd64/bin/java
openjdk version "11.0.13" 2021-10-19
OpenJDK Runtime Environment (build 11.0.13+8-Ubuntu-0ubuntu1.20.04)
OpenJDK 64-Bit Server VM (build 11.0.13+8-Ubuntu-0ubuntu1.20.04, mixed mode, sharing)
/usr/apache-maven-3.8.4/bin/mvn
Apache Maven 3.8.4 (9b656c72d54e5bacbed989b64718c159fe39b537)
Maven home: /usr/apache-maven-3.8.4
Java version: 11.0.13, vendor: Ubuntu, runtime: /usr/lib/jvm/java-11-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "5.11.0-34-generic", arch: "amd64", family: "unix"
/usr/bin/python3
Python 3.8.10
/usr/bin/gradle

Welcome to Gradle 7.4!

Here are the highlights of this release:
 - Aggregated test and JaCoCo reports
 - Marking additional test source directories as tests in IntelliJ
 - Support for Adoptium JDKs in Java toolchains

For more details see https://docs.gradle.org/7.4/release-notes.html


------------------------------------------------------------
Gradle 7.4
------------------------------------------------------------

Build time:   2022-02-08 09:58:38 UTC
Revision:     f0d9291c04b90b59445041eaa75b2ee744162586

Kotlin:       1.5.31
Groovy:       3.0.9
Ant:          Apache Ant(TM) version 1.10.11 compiled on July 10 2021
JVM:          11.0.13 (Ubuntu 11.0.13+8-Ubuntu-0ubuntu1.20.04)
OS:           Linux 5.11.0-34-generic amd64

DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=20.04
DISTRIB_CODENAME=focal
DISTRIB_DESCRIPTION="Ubuntu 20.04.3 LTS"
NAME="Ubuntu"
VERSION="20.04.3 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.3 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
```


