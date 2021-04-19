FROM ubuntu:18.04 as esp32_devstage

ARG DEBIAN_FRONTEND=noninteractive

#passwords as arguments so they can be changed
ARG DEV_PW=password
ARG JENKINS_PW=jenkins

ENV LC_CTYPE en_US.UTF-8
ENV LANG en_US.UTF-8

# We need libpython2.7 due to GDB tools
RUN apt-get update && apt-get install -y \
    apt-utils \
    bison \
    ca-certificates \
    ccache \
    check \
    curl \
    flex \
    git \
    gperf \
    lcov \
    nano \
    libncurses-dev \
    libusb-1.0-0-dev \
    make \
    ninja-build \
    libpython2.7 \
    python3 \
    python3-pip \
    unzip \
    wget \
    xz-utils \
    zip \
    locales \
   && apt-get autoremove -y \
   && rm -rf /var/lib/apt/lists/* \
   && update-alternatives --install /usr/bin/python python /usr/bin/python3 10

RUN apt install -y python3-pip
RUN update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

RUN python -m pip install --upgrade pip virtualenv mrtutils

# To build the image for a branch or a tag of IDF, pass --build-arg IDF_CLONE_BRANCH_OR_TAG=name.
# To build the image with a specific commit ID of IDF, pass --build-arg IDF_CHECKOUT_REF=commit-id.
# It is possibe to combine both, e.g.:
#   IDF_CLONE_BRANCH_OR_TAG=release/vX.Y
#   IDF_CHECKOUT_REF=<some commit on release/vX.Y branch>.

ARG IDF_CLONE_URL=https://github.com/espressif/esp-idf.git
ARG IDF_CLONE_BRANCH_OR_TAG=master
ARG IDF_CHECKOUT_REF=

ENV IDF_PATH=/opt/esp/idf
ENV IDF_TOOLS_PATH=/opt/esp

RUN echo IDF_CHECKOUT_REF=$IDF_CHECKOUT_REF IDF_CLONE_BRANCH_OR_TAG=$IDF_CLONE_BRANCH_OR_TAG && \
    git clone --recursive \
      ${IDF_CLONE_BRANCH_OR_TAG:+-b $IDF_CLONE_BRANCH_OR_TAG} \
      $IDF_CLONE_URL $IDF_PATH && \
    if [ -n "$IDF_CHECKOUT_REF" ]; then \
      cd $IDF_PATH && \
      git checkout $IDF_CHECKOUT_REF && \
      git submodule update --init --recursive; \
    fi

# Install all the required tools, plus CMake
RUN $IDF_PATH/tools/idf_tools.py --non-interactive install required \
  && $IDF_PATH/tools/idf_tools.py --non-interactive install cmake \
  && $IDF_PATH/tools/idf_tools.py --non-interactive install-python-env \
  && rm -rf $IDF_TOOLS_PATH/dist

# Ccache is installed, enable it by default
ENV IDF_CCACHE_ENABLE=1

COPY entrypoint.sh /opt/esp/entrypoint.sh

# Add user dev to the image
RUN adduser --quiet dev && \
    echo "dev:$DEV_PW" | chpasswd && \
    chown -R dev /home/dev 

RUN echo '. /opt/esp/idf/export.sh > /dev/null 2>&1 & ' >> /home/dev/.bashrc 

RUN export LC_ALL="en_US.UTF-8"
RUN export LC_CTYPE="en_US.UTF-8"
RUN dpkg-reconfigure locales

ENTRYPOINT [ "/opt/esp/entrypoint.sh" ]
CMD [ "/bin/bash" ]

######################################################################################################
#                           Stage: jenkins                                                           #
######################################################################################################
FROM esp32_devstage as esp32_jenkinsstage

ARG JENKINS_PW

#install jenkins dependencies
RUN apt update && apt install -qq -y --no-install-recommends openjdk-8-jdk  openssh-server ca-certificates
RUN adduser --quiet jenkins && \
    echo "jenkins:$JENKINS_PW" | chpasswd && \
    mkdir /home/jenkins/.m2 && \
    mkdir /home/jenkins/jenkins && \
    chown -R jenkins /home/jenkins 

# Setup SSH server
RUN mkdir /var/run/sshd
RUN echo 'root:password' | chpasswd
RUN sed -i 's/#*PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
