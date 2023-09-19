#!/bin/bash

#lets install munge, slurm and all dependencies

MAIN_INSTALL_DIR=/opt/slurm_current
MAIN_INSTALL_TMP_DIR=/tmp/slurm_tmp

#make the directories 
mkdir -p ${MAIN_INSTALL_DIR}
mkdir -p ${MAIN_INSTALL_TMP_DIR}

#permissions for the directories
chmod -R 655 ${MAIN_INSTALL_DIR}
chmod -R 655 ${MAIN_INSTALL_TMP_DIR}

#lets make sure we get the ansible packages
dnf install -y ansible-core ansible ansible-collection-ansible-utils ansible-collection-ansible-posix ansible-collection-community-general

#use this to install packages via ansible
ansible-playbook --connection=local --inventory 127.0.0.1 ./site.yml

#dnf install -y  gcc \
#make \
#cmake \
#automake \
#autoconf \
#java-1.8.0-openjdk-devel \
#java-1.8.0-openjdk \
#pkgconf-pkg-config \
#pkgconf \
#rdma-core-devel \
#libpkgconf \
#zlib-devel \
#bzip2-devel \
#lbzip2 \
#pbzip2 \
#libgcrypt-devel \
#openssl3-devel \
#freeipmi-devel \
#man2html \
#man2html-core \
#lua-devel \
#gtk2-devel \
#gtk3-devel \
#rrdtool-devel \
#http-parser-devel \
#json-c-devel \
#pmix-devel \
#readline-devel \
#libyaml-devel \
#libjwt-devel \
#pam-devel \
#hdf5-devel \
#hwloc-devel \
#libbpf-devel \
#dbus-devel \
#hdf5-devel \
#rocm-runtime-devel \
#libibumad \
#MariaDB-devel \
#infiniband-diags-devel 
##mariadb-devel
#





#change directory to tmp place 
pushd ${MAIN_INSTALL_TMP_DIR}

#lets grab latest slurm 
wget -O slurm-23.02-latest.tar.bz2 https://download.schedmd.com/slurm/slurm-23.02-latest.tar.bz2

#grab latest munge
wget -O munge-0.5.15.tar.gz https://github.com/dun/munge/tarball/master

#grab apache directory studio
wget -O apacheds-2.0.0.AM26.tar.gz https://dlcdn.apache.org//directory/apacheds/dist/2.0.0.AM26/apacheds-2.0.0.AM26.tar.gz


# untars the archives 
tar -axvf munge-0.5.15.tar.gz
tar -axvf slurm-23.02-latest.tar.bz2
tar -axvf apacheds-2.0.0.AM26.tar.gz

#start the building munge 
pushd dun-munge*
bash ./bootstrap

bash configure  --prefix=/usr --sysconfdir=/etc --localstatedir=/var --runstatedir=/run

popd 


#install slurm
pushd slurm-23.02.5/

popd 


## apacheds install 
#note that this is a java thing so not a lot to do here 
mv apacheds-2.0.0.AM26 /opt/apacheds


#setup the environment

MAIN_INSTALL_DIR=${HOME}/spindle_build

export PATH=${HOME}/spindle_build/bin:${PATH}
export LD_LIBRARY_PATH=${HOME}/spindle_build/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=${HOME}/spindle_build/lib64:${LD_LIBRARY_PATH}
export MANPATH=${HOME}/spindle_build/share/man:${MANPATH}
export CPATH=${HOME}/spindle_build/include:${CPATH}
