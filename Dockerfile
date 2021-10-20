#==========================================================
# RZV BASE CONTAINER ======================================
#==========================================================
# Docker Base: amazon linux2
FROM amazonlinux:2 AS serratus-base

## Build/test container for rzv
# sudo yum install -y docker git
# sudo service docker start
# git clone https://github.com/ababaian/rzv.git; cd rzv
#
# sudo docker build -t rzv:local
#

## Push to dockerhub
# sudo docker login
# 
# sudo docker build --no-cache \
#  -t serratusbio/rzv \
#  -t serratusbio/rzv:0.0.3 \
#  -t serratusbio/rzv:latest \
#  -t rzv:latest .
#
# sudo docker push serratusbio/rzv

## Dev testing to enter enter
# sudo docker run --rm --entrypoint /bin/bash -it rzv:latest

#==========================================================
# Container Meta-data =====================================
#==========================================================
# Set working directory
# RUN adduser rzv
ENV HOME=/home/serratus
WORKDIR $HOME

# Container Build Information
ARG PROJECT='rzv'
ARG TYPE='base'
ARG VERSION='0.0.0'

# Software Versions (pass to shell)
ENV RVIDVERSION=$VERSION
ENV SEQKITVERSION='2.0.0'
ENV DIAMONDVERSION='2.0.6-dev'
ENV MUSCLEVERSION='3.8.31'
ENV INFERNALVERSION='1.1.4'
ENV RNAVIENNA='2.4.18'

# Add PERL libraries
ENV CPATH='/usr/lib64/perl5/CORE/'

# Additional Metadata
LABEL author="ababaian"
LABEL container.base.image="amazonlinux:2"
LABEL project.name=${PROJECT}
LABEL project.website="https://github.com/ababaian/rzv"
LABEL container.type=${TYPE}
LABEL container.version=${VERSION}
LABEL container.description="Ribozyviria classifier base image"
LABEL software.license="AGPLv3"
LABEL tags="ribozyviria, diamond, muscle, R, rzv"

#==========================================================
# Dependencies ============================================
#==========================================================
# Update Core
RUN yum -y install tar gzip bzip2 unzip\
                   wget which sudo git
# Build Core
RUN yum -y install \
    gcc gcc-c++ cpp make perl perl-devel \
    bzip2-devel xz-devel zlib-devel \
    curl-devel openssl-devel ncurses-devel &&\
    export 

# Development Tools
RUN yum -y install vim htop less

#==========================================================
# Install Software ========================================
#==========================================================

# INFERNAL ======================================
RUN wget http://eddylab.org/infernal/infernal-${INFERNALVERSION}-linux-intel-gcc.tar.gz &&\
  tar -xvf infernal-${INFERNALVERSION}-linux-intel-gcc.tar.gz &&\
  cd infernal* &&\
  bash configure && make && sudo make install &&\
  cd .. && rm -rf infernal*

# SeqKit ========================================
RUN wget https://github.com/shenwei356/seqkit/releases/download/v${SEQKITVERSION}/seqkit_linux_amd64.tar.gz &&\
  tar -xvf seqkit* && mv seqkit /usr/local/bin/ &&\
  rm seqkit_linux*

# DIAMOND =======================================
# RUN wget --quiet https://github.com/bbuchfink/diamond/releases/download/v"$DIAMONDVERSION"/diamond-linux64.tar.gz &&\
#   tar -xvf diamond-linux64.tar.gz &&\
#   rm    diamond-linux64.tar.gz &&\
#   mv    diamond /usr/local/bin/
# Use serratus-built dev version
RUN wget --quiet https://serratus-public.s3.amazonaws.com/bin/diamond &&\
    chmod 755 diamond &&\
    mv    diamond /usr/local/bin/

# ViennaRNA =====================================
# with Perl Utils
RUN wget https://www.tbi.univie.ac.at/RNA/download/sourcecode/2_4_x/ViennaRNA-${RNAVIENNA}.tar.gz &&\
  tar -xvf ViennaRNA-${RNAVIENNA}.tar.gz &&\
  cd ViennaRNA* &&\
  bash configure --without-perl --without-python --without-python3 &&\
  make && make install &&\
  cd .. && rm ViennaRNA*

#==========================================================
# rzv Initialize ==========================================
#==========================================================
# scripts + test data
COPY data/* data/
COPY scripts/* ./

#==========================================================
# Resource Files ==========================================
#==========================================================
# Sequence resources / databases for analysis
# RUN cd /home/serratus/ &&\
#   git clone https://github.com/rcedgar/palmdb.git &&\
#   gzip -dr palmdb/*

#==========================================================
# CMD =====================================================
#==========================================================
CMD ["/home/serratus/rzv.sh"]
