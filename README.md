# raspbiansetup -- My "After Install" Configurations #

## Raspbian Install and First Boot ##

This is fairly straight forward, the only difference is that wifi
needs to be set up and ssh enabled before the first boot.

### For the Basic Install ###

dd bs=4M if=<raspbian .img> of=/dev/mmcblk0 conv=fsync status=progress

### Update the Host Name ###

Mount the Linux root partition, and edit <mount point>/etc/hostname.

### Set Up the Network ###

To do this, add the following to the boot partition after writing the image.

  * Create an empty file named 'ssh' (touch ssh).
  * Create a file named 'wpa_supplicant.conf' with the following contents

        country=US
        ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
        update_config=1
        
        network={
            ssid="<the network's ssid>"
            psk="<the network's password>"
        }

Boot the pi.

After booting the pi, check the router to find the IP address and 'ssh
pi@<the IP address>'. The password is 'raspberry'.

NOTE that if the extra USB<->wifi adapter is plugged in, there may be
two IP addresses. Only one will allow logins!

## Update /etc/hosts and Set the Locale and the Timezone ##

Add local hosts to /etc/hosts.
sudo raspi-config
	- Add en_US.UTF-8.
	- Choose en_US.UTF-8 as a default.
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/US/Central /etc/localtime
sudo reboot

## Change the Password and Update ##

passwd
sudo apt -y update
sudo apt -y upgrade
sudo apt -y autoremove
sudo reboot

## Set up the Environment ##

ssh-keygen -t rsa -C pi@${HOSTNAME}
git clone https://github.com/johnjacques/environment.git
rm $HOME/.profile
ln -s $HOME/environment/login $HOME/.profile
rm $HOME/.bashrc
ln -s $HOME/environment/environment $HOME/.bashrc
rm $HOME/.bash_logout
ln -s $HOME/environment/logout $HOME/.bash_logout
sudo reboot

## Turn Off X ##

sudo systemctl set-default multi-user.target
sudo reboot

## DHCP Server and Access Point ##

This is useful when trying to communicate with the raspberry pi in a
remote location (no internet) such as astrophotography. The steps are
mostly from
https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md,
but I've never tried the bridging bit at the end. Here are the
steps. I've added a USB wifi adapter to the pi
(https://www.amazon.com/gp/product/B00762YNMG/ref=ppx_yo_dt_b_asin_title_o08_s00?ie=UTF8&psc=1).

sudo apt install dnsmasq hostapd
sudo systemctl stop dnsmasq
sudo systemctl stop hostapd

...to keep the interface names consistent, use ifrename

sudo apt install ifrename

...create /etc/iftab with the following
wlan0 mac <mac address of the built-in wifi interface>
wlan1 mac <mac address of the plug in wifi interface>

...replace /etc/dhcpcd.conf with the following
interface wlan1
	nohook wpa_supplicant
static ip_address=192.168.2.50/24
denyinterfaces wlan1

...replace /etc/dnsmasq.conf with the following
interface=wlan1
	dhcp-range=192.168.2.100,192.168.2.200,255.255.255.0,24h

...create /etc/hostapd/hostapd.conf with the following contents
interface=wlan1
hw_mode=g
channel=1
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
ssid=pimount
wpa_passphrase=SeeTheStars

...uncomment DAEMON_CONF in /etc/default/hostapd and have it point to the above
DAEMON_CONF="/etc/hostapd/hostapd.conf"

sudo reboot

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo systemctl unmask dnsmasq
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

## SSH Login Without Password ##

From the build server,

cat .ssh/id_rsa.pub

Copy the output of the above, and on the pi,

echo <output from above> >> .ssh/authorized_keys
