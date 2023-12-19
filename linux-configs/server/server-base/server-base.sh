#!/bin/bash
#### *****RUN AS ROOT***** ####

if [[ "$EUID" -ne 0 ]]; then
    echo "****THIS SCRIPT MUST BE RUN AS THE ROOT USER.****"
    exit
fi

BASH_PROFILE="/root/.bash_profile"
SERVER_BASE_PROFILE="./root/server-base.sh"
STATUS_LOG="/root/status.log"
GETTY="/etc/systemd/system/getty@tty1.service.d/"
CONFIGS="http://bbaker2ud.gihub.io/configs/"
SCRIPTS="http://bbaker2ud.gihub.io/scripts/"
GUACD_SOURCE="http://bbaker2ud.github.io/GUACD/"
DIRECTORY="/root/scripts/"
GUACDIR="/root/GUACD/"
UPDATES="updates.sh"
OVERRIDE="override.conf"
AUTOSTART="/etc/xdg/openbox/autostart"
KIOSK_PROFILE="[[ -z \$DISPLAY && \$XDG_VTNR -eq 1 ]] && exec startx"
CRONTAB="/var/spool/cron/crontabs/root"
VMDOWNLOAD="https://download3.vmware.com/software/CART24FQ2_LIN64_2306/"
VMBUNDLE="VMware-Horizon-Client-2306-8.10.0-21964631.x64.bundle"
USERNAME=""
PASSWORD=""
DEVICE_HOSTNAME=""
HOWMANY="0"
CIFS_CREDS="/etc/cifs-credentials"
VALID="0"

# Determine whether the .bash_profile file exists ? get the profile : set the profile
if [[ -f $BASH_PROFILE ]]
then
    CURRENT_PROFILE="$(cat "$SERVER_BASE_PROFILE")"
else
    CURRENT_PROFILE=$PROFILE
    echo "$BASH_PROFILE : $(date)"
    echo "$CURRENT_PROFILE" > "$BASH_PROFILE"
fi

# Determine whether the log file exists ? get the status : set status0
if [[ -f $STATUS_LOG ]]
then
    CURRENT_STATUS="$(cat "$STATUS_LOG")"
else
    CURRENT_STATUS="stage0"
    echo "$CURRENT_STATUS : $(date)"
    echo "$CURRENT_STATUS" > "$STATUS_LOG"
fi

# Define your actions as functions
getCredentials()
{
    echo "Please enter your UD username: " &&
    read -p "Username: " USERNAME &&
    echo "Please enter your UD password: " &&
    read -sp "Password: " PASSWORD &&
    echo "username=${USERNAME}" > $CIFS_CREDS &&
    echo "password=${PASSWORD}" >> $CIFS_CREDS
}

setHostname()
{
    echo "Please enter the desired hostname for this device: " &&
    read -sp "Device hostname: " DEVICE_HOSTNAME &&
    hostnamectl hostname $DEVICE_HOSTNAME &&
}

getGUACD()
{
    mkdir $GUACDIR ||
    wget -P $GUACDIR ${GUACD_SOURCE}guacd_list -q --show-progress &&
    wget -P $GUACDIR -i ${GUACDIR}guacd_list -q --show-progress &&
    chmod +x "${GUACDIR}getGUACDc.sh" &&
    ".${GUACDIR}getGUACDc.sh" &&
    cat "${GUACDIR}guacd.info"
}

setupAutoLogin()
{
    passwd -d root &&
    mkdir $GETTY ||
    wget -P $GETTY "${CONFIGS}${OVERRIDE}" &&
    CURRENT_STATUS="stage1"
    echo "$CURRENT_STATUS : $(date)"
    echo "$CURRENT_STATUS" > "$STATUS_LOG"
    reboot
}

joinRealm()
{
    echo "Installing realmd..." &&
    apt -y install realmd &&
    echo "Discovering realm..." &&
    realm discover adws.udayton.edu &&
    success=0 &&
    until [ $success -ge 1 ]; do
        echo "Joining realm..." &&
        echo $PASSWORD | realm join -U $USERNAME adws.udayton.edu &&
        if [ $? -eq 0 ]; then
            success=1
            echo "success=$success"
        else
            getCredentials
        fi
    done
    echo "Permitting domain user logins..." &&
    realm permit -g 'domain users@adws.udayton.edu' &&
    echo "Permitting admin logins..." &&
    realm permit -g cas.role.administrators.casit.workstations@adws.udayton.edu &&
    echo "Enabling the creation of home directory on first login..." &&
    pam-auth-update --enable mkhomedir &&
    echo "Done."
}

update()
{
    echo "Creating /root/scripts directory..." &&
    mkdir $DIRECTORY ||
    echo "Downloading ${UPDATES}..." &&
    wget -P $DIRECTORY "${SCRIPTS}${UPDATES}" &&
    echo "Changing permissions..." &&
    chmod +x "${DIRECTORY}${UPDATES}" &&
    echo "Running updates.sh..." &&
    ./$UPDATES &&
    CURRENT_STATUS="stage2" &&
    echo "$CURRENT_STATUS : $(date)" &&
    echo "$CURRENT_STATUS" > "$STATUS_LOG" &&
    echo "Updates finished. Rebooting now." &&
    sleep 1 &&
    reboot
}

addCrontab()
{
    echo "Adding crontab for automatic updates..." &&
    echo "0 0 1 * * ${DIRECTORY}${UPDATES}" >> $CRONTAB &&
    echo "Done."
}

addSudoers()
{
    echo "Adding sudoers..." &&
    echo "%cas.role.administrators.casit.workstations@adws.udayton.edu ALL=(ALL) ALL" >> /etc/sudoers &&
    echo "landesk ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &&
    echo "Defaults:landesk !requiretty" >> /etc/sudoers &&
    echo "Done."
}

installDisplayManagerComponents()
{
    apt install -y xorg xserver-xorg x11-xserver-utils xinit openbox &&
    echo -e "\nxset s off\n\nxset s noblank\n\nxset -dpms\n\nsetxkbmap -option terminate:ctrl_alt_bksp\n\n#setxkbmap -option srvrkeys:none" >> $AUTOSTART &&
    echo -e "\n\nvmware-view --serverURL=vdigateway.udayton.edu --fullscreen --nomenubar --allSessionsDisconnectedBehavior='Logoff' --usbAutoConnectOnInsert='TRUE'" >> $AUTOSTART &&
    echo "Display Manager Components installed."
    sleep 1
}

installVMwareHorizonClient()
{
    wget "${VMDOWNLOAD}${VMBUNDLE}" &&
    chmod +x $VMBUNDLE &&
    env TERM=dumb ./$VMBUNDLE --console --required &&
    echo "VMware Horizon Client installed."
    rm $VMBUNDLE &&
    sleep 1
}

installOpenSSH()
{
    apt install openssh-server -y &&
    ufw enable &&
    ufw allow ssh &&
    echo "SSH enabled and configured."
    sleep 1
}

reconfigureBashProfile()
{
    echo $KIOSK_PROFILE > $BASH_PROFILE &&
    echo ".bash_profile reconfigured."
    sleep 1 &&
    reboot
}

removeBashProfile()
{
    rm $BASH_PROFILE
    echo ".bash_profile removed."
    CURRENT_STATUS="stage3" &&
    echo "$CURRENT_STATUS : $(date)"
    echo "$CURRENT_STATUS" > "$STATUS_LOG"
    sleep 1 &&
    reboot
}

disableAutoLogin()
{
    rm "${GETTY}${OVERRIDE}" &&
}

installFalconSensor()
{
    apt -y install python3-pip &&
    pip install gdown &&
    echo "Downloading CrowdStrike Falcon sensor..."
    gdown 1YnvSQmCgUE0lRs5Fauvfub_KsUhcnbCw &&
    echo "Installing Falcon Sensor..." &&
    dpkg --install falcon-sensor_6.38.0-13501_amd64.deb &&
    /opt/CrowdStrike/falconctl -s --cid=0FA34C2A8A4545FC9D85E072AFBABA4A-E7 &&
    systemctl start falcon-sensor &&
    rm falcon-sensor_6.38.0-13501_amd64.deb
}

mountNetworkShare()
{
    echo "Installing cifs-utils..." &&
    apt-get install cifs-utils &&
    echo "Mounting network share..." &&
    mkdir /media/share ||
    GOOD=0 &&
    until [ $GOOD -ge 1 ]; do
    mount -v -t cifs -o rw,vers=3.0,username=$USERNAME,password=$PASSWORD //itsmldcs1.adws.udayton.edu/ldlogon/unix /media/share
        if [ $? -eq 0 ]; then
            GOOD=1
            echo "success=$GOOD"
        else
            echo "success=$GOOD"
        fi
    done &&
    echo "Network share mounted..."
}

configureFirewall()
{
    echo "Enabling firewall..." &&
    echo "Opening ports..." &&
    ufw allow 22 &&
    ufw allow 9593 && 
    ufw allow 9594 && 
    ufw allow 9595/tcp && 
    ufw allow 9595/udp &&
    echo "Firewall configured..." &&
}

installIvantiAgent()
{
    echo "Creating temporary directory..." &&
    mkdir -p /tmp/ems ||
    echo "Navigating to temporary directory..." &&
    cd /tmp/ems &&
    echo "Downloading nixconfig.sh..." &&
    cp /media/share/nixconfig.sh /tmp/ems/nixconfig.sh &&
    echo "Making nixconfig.sh exectutable..." &&
    chmod a+x /tmp/ems/nixconfig.sh &&
    echo "Installing Ivanti Agent..." &&
    /tmp/ems/nixconfig.sh -p -a itsmldcs1.adws.udayton.edu -i all -k ea67f4cd.0 &&
    echo "Ivanti agent installed..." 
}

case "$CURRENT_STATUS" in
    stage0)
        getCredentials
        setHostname
        setupAutoLogin
    ;;
    stage1)
        update
    ;;
    stage2)
        addCrontab
        installOpenSSH
        addSudoers
        setHostname
        joinRealm
        #  installDisplayManagerComponents
        #  installVMwareHorizonClient
        #  reconfigureBashProfile
        getGUACD
        mountNetworkShare
        installFalconSensor
        configureFirewall
        disableAutoLogin
        removeBashProfile
    ;;
    stage3)
        echo "The script '$0' is finished."
    ;;
    *)
        echo "Something went wrong!"
    ;;
esac
