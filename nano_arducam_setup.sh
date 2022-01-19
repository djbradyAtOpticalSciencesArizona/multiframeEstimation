#!/bin/bash

####################################################################
### Make essential modification and installation for Jetson Nano ###
### to work with Arducam 1MP Quadrascopic Camera Bundle Kit      ###
### By Minghao, May 06, 2021                                     ###
####################################################################

GAPTIME=1
# Gaps bettwen each operation block. Easier debug and break

#############################
### Setting date and time ###
#############################
echo
echo "Setting date and time..."
echo
sleep $GAPTIME

TIMEZONE='America/Phoenix'
#stop linux system's auto time sync, it does not work good
sudo timedatectl set-ntp no 
# a small validation mechanism using while-if-break
while :
do
	read -p "Type date and time (a little ahead so you have time to validate) with the format: 
	YYYY-MM-DD HH:MM:SS
	" DATETIME
	read -p "Date and time: $DATETIME, proceed? (y/n) " VAL_CHAR
	if [[ $VAL_CHAR =~ ^[Yy]$ ]]
	then
    		break
	fi
done
sudo timedatectl set-time "$DATETIME"
timedatectl #verify time now
sleep 3
# Changing system time seems to temperally lock some file
# apt options would be blocked if no waiting

####################################
### Upgrade and Install Packages ###
####################################
echo
echo "Upgrade and install packages..."
echo
sleep $GAPTIME

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install tmux v4l-utils libv4l-dev python3-pip mplayer ntp ntpdate libcanberra-gtk0 libcanberra-gtk-module 
# libcanberra-gtk*is for opencv widget

##########################
### Time sync settings ###
##########################
# use ntp to sync time
echo
echo "Sync time..."
echo
sleep $GAPTIME

# First manual time sync
sudo service ntp stop
sudo ntpdate -s time.nist.gov
sudo service ntp start
timedatectl #verify time now
ntpq -p #check ntp working status

# record the date now, add it to text contents
DATE="`date +%F`"

# Auto time sync upon startup and internet connection
RCF=/etc/rc.local
if [ -f "$RCF" ]; then
    echo "$RCF exists. Please change it manually."
    while :
    do
        read -p "Did you check and set it manually? (y/n) " VAL_CHAR
        if [[ $VAL_CHAR =~ ^[Yy]$ ]]; then
            break
        fi
    done
else
    echo "Making a $RCF..."
    echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will exit 0 on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Sync time upon Internet
# Added by Minghao, $DATE
( /etc/init.d/ntp stop
until ping -nq -c3 8.8.8.8; do
   echo 'Waiting for network...'
done
ntpdate -s time.nist.gov
/etc/init.d/ntp start )&

exit 0" | sudo tee -a $RCF >&-
fi

#############################
### Vim text editor setup ###
#############################
echo
echo "Setting up vim..."
echo
sleep $GAPTIME

# set vim as default visudo editor
sudo update-alternatives --set editor /usr/bin/vim.basic

echo "
\" Set tab to 4 spaces, by Minghao, $DATE
filetype plugin indent on
\" show existing tab with 4 spaces width
set tabstop=4
\" when indenting with '>', use 4 spaces width
set shiftwidth=4
\" On pressing tab, insert 4 spaces
set expandtab

\" Set default color scheme, added by minghao, $DATE
syntax on
colorscheme ron" \
    | sudo tee -a /usr/share/vim/vimrc >&-

echo "
# Set vim as default editor, added by minghao, $DATE
export VISUAL='vim'
export EDITOR='vim'" \
    >> ~/.bashrc

#############################################
### Install v4l2 python package with pip3 ###
#############################################
echo
echo "Installing v4l2..."
echo
sleep $GAPTIME

# as root so any user can use
sudo -H pip3 install v4l2-fix  
############### Deprecated ##################
### method before Arducam release a fixed ###
### version of v4l2                       ###
#sudo -H pip3 install v4l2
## manually fix the bug by alter 2 lines
#V4L2F='/usr/local/lib/python3.6/dist-packages/v4l2.py'
#sudo sed -i '197s/range(1, 9)/list(range(1, 9))/' $V4L2F
#sudo sed -i '248s/range(0, 4)/list(range(0, 4))/' $V4L2F
##############################################
# set default python version python3
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 10

#############################################
### Download Arducam python code examples ###
#############################################
echo
echo "Downloading Arducam python code examples...."
echo
sleep $GAPTIME

git clone https://github.com/ArduCAM/MIPI_Camera.git
cp -r ./MIPI_Camera/Jetson/Jetvariety/example ~/Desktop/Arducam_example

###################################
### Install Arducam v4l2 driver ###
###################################
echo
echo "Installing Arducam v4l2 driver... "
echo "NEEDS REBOOT"
echo
sleep $GAPTIME

wget -q https://github.com/ArduCAM/MIPI_Camera/releases/download/v0.0.3/install_full.sh
DINSNAME=Arducam_v4l2_driver_installer.sh
mv install_full.sh $DINSNAME
chmod +x $DINSNAME
bash $DINSNAME -m arducam

exit 0
