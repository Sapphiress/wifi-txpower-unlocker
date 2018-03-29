
#!/bin/bash

#title: kali-linux-region-BO-wifi-txpower-unlocker.sh
#description: Unlocks the wifi txpower of the 2.4Ghz band of the BO region 
#ORIGINAL author: Hiruna Wijesinghe https://github.com/hiruna/wifi-txpower-unlocker/
#date: 13/05/2017

#FORK author: Sapphiress https://github.com/Sapphiress/wifi-txpower-unlocker
#description: Rewrote for kali 2018.1 heavily modified script from Hiruna.(See above)
#date: 28/03/2018

#Environment
cd ~/Downloads #Probably uneeded however, could help with no db.txt error.

#change the value to the tx power (dBm) you like
txpower=30 #SAPPHIRESS: Set to 30dBm for conpatability and risk of overheating some cards. ORIGINAL AUTHOR: "I set it to 33 as 33dBm ~ 2W"

# Exit if any line fails.
set -e

# Update apt repositories.
apt-get --yes update

# Ask before upgrade
printf "We suggest upgrading for continuing. Would you like to upgrade now? [Yes,No,Y,N]:"
read -r upgrade
if [ ${upgrade,,} == "y" ] || [ ${upgrade,,} == "yes" ] ; then
echo "Rebooting..."
apt-get --yes upgrade
elif [ ${upgrade,,} == "n" ] || [ ${upgrade,,} == "no" ] ; then
echo "You chose not to upgrade. That's OK we will try anyway."
else
echo "Invalid option. Please Upgrade will not be performed. Trying anyway..."
fi

# Download dependencies
apt-get --yes install pkg-config libnl-3-dev libgcrypt11-dev libnl-genl-3-dev build-essential

# Seperate because a bunch more deps are needed. There will be multiple of same command for debug and readabilities sake.
apt-get --yes install libnl1*
apt-get --yes install python python-m2crypto libssl1*

# Download latest CRDA and Wireless Regulatory DB.

wget "https://www.kernel.org/pub/software/network/crda/crda-3.18.tar.xz"
wget "https://www.kernel.org/pub/software/network/wireless-regdb/wireless-regdb-2017.12.23.tar.xz"

# unxz files first. As that is the proper way of doing things.
unxz -f ./crda-3.18.tar.xz
unxz -f ./wireless-regdb-2017.12.23.tar.xz

# Unzip the downloaded files.
tar xf ./crda-3.18.tar
tar xf ./wireless-regdb-2017.12.23.tar

# Make db.txt then copy a populated version to current dir.
touch ./db.txt
cp ./wireless-regdb-2017.12.23/db.txt ./db.txt
# Inset modified txpower in db.txt. 
sed -i -e 's/(5250 - 5350 @ 80), (30)/(5250 - 5350 @ 80), ('$txpower')/g' db.txt
sed -i -e 's/(5470 - 5725 @ 160), (30)/(5470 - 5725 @ 160), ('$txpower')/g' db.txt
sed -i -e 's/(5725 - 5875 @ 80), (30)/(5725 - 5875 @ 80), ('$txpower')/g' db.txt
sed -i -e 's/(2402 - 2482 @ 40), (30)/(2402 - 2482 @ 40), ('$txpower')/g' db.txt
sed -i -e 's/(5170 - 5250 @ 80), (30)/(5170 - 5250 @ 80), ('$txpower')/g' db.txt
sed -i -e 's/(5250 - 5330 @ 80), (30)/(5250 - 5330 @ 80), ('$txpower')/g' db.txt
sed -i -e 's/(5490 - 5710 @ 160), (30)/(5490 - 5710 @ 160), ('$txpower')/g' db.txt
sed -i -e 's/(5170 - 5250 @ 80), (30)/(5170 - 5250 @ 80), ('$txpower')/g' db.txt
sed -i -e 's/(5250 - 5330 @ 80), (30)/(5250 - 5330 @ 80), ('$txpower')/g' db.txt
sed -i -e 's/(5490 - 5730 @ 160), (30)/(5490 - 5730 @ 160), ('$txpower')/g' db.txt
sed -i -e 's/(2400 - 2494 @ 40), (30)/(2400 - 2494 @ 40), ('$txpower')/g' db.txt
sed -i -e 's/(4910 - 5835 @ 40), (30)/(4910 - 5835 @ 40), ('$txpower')/g' db.txt

# Copy modified db.txt  
cp ./db.txt wireless-regdb-2017.12.23/db.txt

# Compile regulatory.db
make -C wireless-regdb-2017.12.23

# Backup the old regulatory.bin and move the new file into /lib/crda.
# Add /usr before /lib/crda/reulatory.bin if your distro requires it.
mv /lib/crda/regulatory.bin /lib/crda/regulatory.bin.old
mv wireless-regdb-2017.12.23/regulatory.bin /lib/crda

# Copy pubkeys
cp wireless-regdb-2017.12.23/*.pem crda-3.18/pubkeys
# If the extra pubkeys exist, copy them too.
if [ -e /lib/crda/pubkeys/benh\@debian.org.key.pub.pem ] ; then
cp /lib/crda/pubkeys/benh\@debian.org.key.pub.pem crda-3.18/pubkeys
fi
if [ -e /lib/crda/pubkeys/linville.key.pub.pem ] ; then
cp /lib/crda/pubkeys/linville.key.pub.pem crda-3.18/pubkeys
fi

# Change regulatory.bin path in the Makefile.
sed -i "/REG_BIN?=\/usr\/lib\/crda\/regulatory.bin/!b;cREG_BIN?=\/lib\/crda\/regulatory.bin" crda-3.18/Makefile
# Remove -Werror option when compiling.
sed -i "/CFLAGS += -std=gnu99 -Wall -Werror -pedantic/!b;cCFLAGS += -std=gnu99 -Wall -pedantic" crda-3.18/Makefile

# Compile.
make clean -C ./crda-3.18
make -C ./crda-3.18
make install -C ./crda-3.18

# Reboot.
printf "A system reboot is required to apply changes. Do you want to reboot now? [Yes,No,Y,N]:"
read -r reboot
if [ ${reboot,,} == "y" ] || [ ${reboot,,} == "yes" ] ; then
echo "Rebooting..."
reboot
elif [ ${reboot,,} == "n" ] || [ ${reboot,,} == "no" ] ; then
echo "You chose not to reboot. Please reboot the system manually."
else
echo "Invalid option. Please reboot the system manually."
fi
