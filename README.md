# Raspberry Pi Setup -- My Setup for Local Use #

## Raspberry Pi OS Install and First Boot ##

This should work for raspbian as well, but I'm currently using the
newly named Raspberry Pi OS images from
http://downloads.raspberrypi.org .  This means buster and either arm64
(raspios\_arm64/images) or armhf (raspios\_armhf/images).

This is fairly straight forward, the only difference is that wifi
needs to be set up and ssh enabled before the first boot.  The idea
here is to install without every connecting a display, keyboard, or
mouse.

### For the Basic Install ###

So, assuming the device is mmcblk0 and the image is
2020-05-27-raspios-buster-arm64.img,

sudo dd bs=4M conv=fsync status=progress \
	if=2020-05-27-raspios-buster-arm64.img of=/dev/mmcblk0

With 'conv=fsync', everything should be written when the command
completes.  Just remove the card.

### Update the Host Name ###

Mount the Linux root partition, and edit <mount point>/etc/hostname.

### Set Up the Network ###

To do this, mount the boot partition and add the following to the boot
partition after writing the image.

  * Create an empty file named 'ssh' in the boot partition (touch ssh).
  * Create a file named 'wpa\_supplicant.conf' with the following contents

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
	- Add en\_US.UTF-8.
	- Choose en\_US.UTF-8 as a default.
	- Enable SPI and I2C in Interfacing Options
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/US/Central /etc/localtime
sudo reboot

## Change the Password and Update ##

passwd
sudo apt -y update
sudo apt -y upgrade
sudo apt -y autoremove
sudo reboot

## SSH Login Without Password ##

Create a key pair.  Go ahead and add a pass-phrase, as ssh-agent will
keep the annoyance down to a minimum!

ssh-keygen -t rsa

Copy the public key of the build server to ~/.ssh/authorized_keys.

Copy the public key of the Pi to the build server's ~/.ssh/authorized_keys.

## Set up the Environment ##

git clone https://github.com/johnjacques/environment.git
rm $HOME/.profile
ln -s $HOME/environment/login $HOME/.profile
rm $HOME/.bashrc
ln -s $HOME/environment/environment $HOME/.bashrc
rm $HOME/.bash\_logout
ln -s $HOME/environment/logout $HOME/.bash\_logout
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

sudo apt -y install dnsmasq hostapd
sudo systemctl stop dnsmasq
sudo systemctl stop hostapd

...to keep the interface names consistent, use ifrename

sudo apt -y install ifrename

...create /etc/iftab with the following
wlan0 mac <mac address of the built-in wifi interface>

...replace /etc/dhcpcd.conf with the following
interface wlan1
	nohook wpa\_supplicant
static ip\_address=192.168.2.50/24
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

...uncomment DAEMON\_CONF in /etc/default/hostapd and have it point to the above
DAEMON\_CONF="/etc/hostapd/hostapd.conf"

sudo reboot

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo systemctl unmask dnsmasq
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

## Optional Stuff ##

To sync everything needed for "whatever is currently being developed",
get the 'syncsrc' script.

mkdir ~/bin
scp john@dallben:/home/john/Projects/Pi/bin/syncsrc ~/bin
<logout and then back in>
syncsrc

The rest will depend on what gets sync'd.

### ZWO ASI Camera ###

To use the ASI cameara, the udev rules have to be updated, and the
header and libraries from the SDK have to be installed.  If available,
/home/pi/Projects/ASI\*SDK\* should exist.  If it does exist, do the
following.

sudo cp /home/pi/Projects/ASI*SDK*/lib/asi.rules /lib/udev/rules.d/

if $(uname -m) is aarch64, ARCH=armv8
if $(uname -m) is armv7l, ARCH=armv7

    sudo cp /home/pi/Projects/ASI*SDK*/include/ASICamera2.h /usr/include
    sudo chmod 644 /usr/include/ASICamera2.h
    sudo cp -P /home/pi/Projects/ASI*SDK*/lib/${ARCH}/* /usr/lib

N.B. Plugging the camera I have

ZWO ASI120MC-S 1.2 Megapixel USB3.0 Color

usb 1-1.3: new high-speed USB device number 4 using xhci_hcd
usb 1-1.3: New USB device found, idVendor=03c3, idProduct=120e, bcdDevice= 0.00
usb 1-1.3: New USB device strings: Mfr=1, Product=2, SerialNumber=0
usb 1-1.3: Product: ASI120MC-S
usb 1-1.3: Manufacturer: ZWO

into a USB3 port, will lock up the Pi...

### INDI ###

    sudo apt-get -y install libnova-dev libcfitsio-dev libusb-1.0-0-dev \
    	zlib1g-dev libgsl-dev build-essential cmake git libjpeg-dev \
    	libcurl4-gnutls-dev libtheora-dev libfftw3-dev
    cd ~/Projects
    mkdir indi-build
    cd indi-build
    cmake -DCMAKE_INSTALL_PREFIX=/usr ~/Projects/indi
    make -j4
	sudo make install

### OpenAstro ###

    sudo apt install -y autoconf m4 libtool libsdl-dev libqt4-dev qt4-dev-tools \
         libtiff-dev libraw-dev libv4l-dev libcfitsio-dev libgphoto2-dev \
         libudev-dev autoconf-archive libraw1394-dev libusb-1.0-0-dev
    cd ~/Projects/openastro
    ./bootstrap
    ./configure
    make -j4
	sudo make install

### PHD2 ###

    sudo apt-get install build-essential git cmake pkg-config \
		libwxgtk3.0-gtk3-dev wx-common wx3.0-i18n libindi-dev libnova-dev \
		gettext zlib1g-dev libx11-dev libcurl4-gnutls-dev
    mkdir ~/Projects/phd2-build
    cd ~/Projects/phd2-build
    cmake ../phd2
    make -j4
	sudo make install

### indiprop ###

    qmake
    make
    sudo make install
