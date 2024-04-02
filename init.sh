#!/bin/bash
#!/bin/bash
# Goon managmement node deployment. 

# Main mirrors
HTTP_MAIN_MIRROR_URL="http://southfront.mm.fcix.net/fedora/linux"
HTTPS_MAIN_MIRROR_URL="https://southfront.mm.fcix.net/fedora/linux"
RSYNC_MAIN_MIRROR_URL="rsync://southfront.mm.fcix.net/fedora-enchilada/linux"
# EPEL mirror
HTTP_EPEL_MIRROR_URL="http://southfront.mm.fcix.net/epel"
HTTPS_EPEL_MIRROR_URL="https://southfront.mm.fcix.net/epel"
RSYNC_EPEL_MIRROR_URL="rsync://southfront.mm.fcix.net/fedora-epel"
##
# Rclone AMD64 uri
RCLONE_AMD64_URI="https://downloads.rclone.org/rclone-current-linux-amd64.zip"
# Rclone ARM uri
RCLONE_ARM_URI="https://downloads.rclone.org/rclone-current-linux-arm.zip"

# use ftp mirror to serve files



function die() {
    echo $1
    exit 1
}


function createEnvironment() {
    local envDir=$1
    local hackRpmDir=$2
    local hackRpmUrl=$3

    if [ -d $envDir ]; then
        echo "Environment already exists in $envDir"
        return
    fi

    mkdir -p $envDir
    downloadHackRpms $hackRpmDir $hackRpmUrl
    pushd $envDir
    mkdir -p {repos,cache,logs}
    popd
}





function checkForApplications()
{

    local APP_ARR=(rclone rsync wget rpm)

        for app in "${APP_ARR[@]}"
        do

        which $app &> /dev/null 

            if [ $? -ne 0 ]; then
                die "Application $app not found. Please install it before proceeding"
            fi

        done


}



function downloadHackRpms() {
    local hackRpmDir=$1
    local hackRpmUrl=$2

    if [ -d $hackRpmDir ]; then
        echo "Hack RPMs already downloaded in $hackRpmDir"
        return
    fi

    mkdir -p $hackRpmDir
    pushd $hackRpmDir
    wget $hackRpmUrl
    popd
}



function mirrorRepoInDir() {
    local repoDir=$1
    local repoUrl=$2

    if [ -d $repoDir ]; then
        echo "Repo $repoName already exists in $repoDir"
        return
    fi


}


# meat and potatoes

function main()
{



}


main 


exit 0 


#end 
#lets install munge, slurm and all dependencies

MAIN_INSTALL_DIR=/opt/slurm_current
MAIN_INSTALL_TMP_DIR=/tmp/slurm_tmp
MAIN_INSTALL_PREFIX=/opt



#make the directories 
mkdir -p ${MAIN_INSTALL_DIR}
mkdir -p ${MAIN_INSTALL_TMP_DIR}

#permissions for the directories
chmod -R 655 ${MAIN_INSTALL_DIR}
chmod -R 655 ${MAIN_INSTALL_TMP_DIR}

#check to see if we have apt or dnf avaialble for us
PKG_MAN_TRAP=1

grep -iP "Debian|Ubuntu" /etc/os-release > /dev/null
if [ $? -eq 0 ]
then 
PKG_MAN_TRAP=0
apt-get install -ymq ansible ansible-core
fi

grep -iP "fedora|redhat|oracle*|alma*" /etc/os-release > /dev/null
#lets make sure we get the ansible packages
if [ $? -eq 0 ]
then
PKG_MAN_TRAP=0
dnf install -y ansible-core ansible ansible-collection-ansible-utils ansible-collection-ansible-posix ansible-collection-community-general
fi

if [ ${PKG_MAN_TRAP} -eq 1 ]
then
echo "we don't have Deb/Ubuntu or RHEL distros here"
echo "exiting"
exit 1
fi

#use this to install packages via ansible
ansible-playbook --connection=local --inventory 127.0.0.1 ./site.yml

#change directory to tmp place 
pushd ${MAIN_INSTALL_TMP_DIR}

#lets grab latest slurm 
wget -O slurm-23.02-latest.tar.bz2 https://download.schedmd.com/slurm/slurm-23.02-latest.tar.bz2

#grab latest munge
wget -O munge-0.5.15.tar.xz https://github.com/dun/munge/releases/download/munge-0.5.15/munge-0.5.15.tar.xz

#grab prometheus monitoring- version 2.47
wget -O prometheus-2.47.0.linux-amd64.tar.gz https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz



#get the parent directories of the archives
MUNGE_PARENT_DIR=$(tar atf munge-0.5.15.tar.xz | head -n1)
SLURM_PARENT_DIR=$(tar atf slurm-23.02-latest.tar.bz2 | head -n1)
PROMETHEUS_PARENT_DIR=$(tar atf prometheus-2.47.0.linux-amd64.tar.gz | head -n1)



# untars the archives
tar -axvf munge-0.5.15.tar.xz #-C _munge_current
tar -axvf slurm-23.02-latest.tar.bz2 #-C _slurm_current
tar -axvf prometheus-2.47.0.linux-amd64.tar.gz #-C  _prometheus_current




#start the building munge 
pushd ${MUNGE_PARENT_DIR}
bash ./configure --prefix=${MAIN_INSTALL_PREFIX}/munge --sysconfdir=/etc --localstatedir=/var --runstatedir=/run
make -j4 && make install
make clean
popd 


#install slurm
pushd ${SLURM_PARENT_DIR}
#bash ./configure --prefix=${MAIN_INSTALL_PREFIX}/slurm --sysconfdir=/etc --localstatedir=/var --runstatedir=/run
PMIX_PATH=$(pmix_info --path prefix | cut -d ':' -f 2 | sed 's/ //g')

bash ./configure --prefix=${MAIN_INSTALL_PREFIX}/slurm --sysconfdir=/etc \
--localstatedir=/var --runstatedir=/run --enable-dependency-tracking \
--enable-pam --enable-multiple-slurmd --enable-deprecated --with-pmix=${PMIX_PATH}


make -j4 && make install
make clean
popd 


## prometheus install 
mv ${PROMETHEUS_PARENT_DIR} ${MAIN_INSTALL_PREFIX}/prometheus

## Make the munge key
sudo -u munge ${MAIN_INSTALL_PREFIX}/munge/sbin/mungekey --verbose

#Create the profile for the environment 
cat << EOF > /etc/profile.d/z99_hotep.sh

PATH=${MAIN_INSTALL_PREFIX}/munge/bin:${MAIN_INSTALL_PREFIX}/munge/sbin:${MAIN_INSTALL_PREFIX}/slurm/bin:${MAIN_INSTALL_PREFIX}/slurm/sbin:\${PATH}
LD_LIBRARY_PATH=${MAIN_INSTALL_PREFIX}/munge/lib:${MAIN_INSTALL_PREFIX}/slurm/lib:${MAIN_INSTALL_PREFIX}/munge/lib64:${MAIN_INSTALL_PREFIX}/slurm/lib64:\${LD_LIBRARY_PATH}
CPATH=${MAIN_INSTALL_PREFIX}/munge/include:${MAIN_INSTALL_PREFIX}/slurm/include:\${CPATH}

export PATH
export LD_LIBRARY_PATH
export CPATH

EOF
#add manpath to profile
#export MANPATH=${HOME}/spindle_build/share/man:${MANPATH}

#set up the ntp service with chrony configuration
if ! [ -f /etc/chrony.conf_bak ]
then 
mv /etc/chrony.conf /etc/chrony.conf_bak
cat << EOF > /etc/chrony.conf
#hotep ntp settings
server time.facebook.com iburst
server time.windows.com iburst
pool 2.fedora.pool.ntp.org iburst
pool 0.us.pool.ntp.org iburst
server time.apple.com iburst
server ntp1.ona.org iburst
server ntp1.net.berkeley.edu iburst
pool 0.freebsd.pool.ntp.org iburst
pool 1.openbsd.pool.ntp.org iburst
pool time.nist.gov iburst
server utcnist2.colorado.edu iburst

driftfile /var/lib/chrony/drift

makestep 1.0 3

rtcsync

keyfile /etc/chrony.keys

leapsectz right/UTC

logdir /var/log/chrony

EOF

fi 



#Firewall services
firewall-cmd --add-service=ntp 
firewall-cmd --add-service=ssh

## setup permanent
firewall-cmd --runtime-to-permanent 

#setup services
## chronyd
systemctl enable chronyd
systemctl start chronyd


