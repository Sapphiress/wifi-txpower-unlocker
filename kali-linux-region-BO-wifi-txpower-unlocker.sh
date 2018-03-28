
#!/bin/bash

#title: kali-linux-region-BO-wifi-txpower-unlocker.sh
#description: Unlocks the wifi txpower of the 2.4Ghz band of the BO region 
#author: Hiruna Wijesinghe https://github.com/hiruna/wifi-txpower-unlocker/
#date: 13/05/2017

#author: Sapphiress
#description: Rewrote for kali 2018.1 heavily modified script from Hiruna.(See above)
#date: 28/03/2018


# Makeshift changelog.
#  Latest* variables do nothing and have been phased out.
#  Changed default txpower to 30dBm.
#  Making script run directly from ~/Downloads.
#  Fixed "sed: can't read db.txt: No such file or directory"
#  Removed /usr/ from CRDA path as it's located in /lib on Kali.
#  Added unxz and removed Jv flags for files are extracted properly.

# Environment
echo "This software must be run as root"
cd ~/Downloads #Probably uneeded however, could help with no db.txt error.

#change the value to the tx power (dBm) you like
txpower=30 #I set it to 33 as 33dBm ~ 2W

set -e #Exit if any line fails

#Update and updrade
apt-get --yes update
apt-get --yes upgrade

#Download dependencies
apt-get --yes install pkg-config libnl-3-dev libgcrypt11-dev libnl-genl-3-dev build-essential

#Download latest CRDA and Wireless Regulatory DB

# These are only here so I don't break anything even though I've made them inactive. -Sapphiress
latestCRDA=3.18
latestWRDB=2017.12.23

wget "https://www.kernel.org/pub/software/network/crda/crda-3.18.tar.xz"
wget "https://www.kernel.org/pub/software/network/wireless-regdb/wireless-regdb-2017.12.23.tar.xz"

#unxz files first. As that is the proper way of doing things.
unxz -f ./crda-3.18.tar.xz
unxz -f ./wireless-regdb-2017.12.23.tar.xz

#Unzip the downloaded files
tar xf ./crda-3.18.tar
tar xf ./wireless-regdb-2017.12.23.tar

#Make db.txt first to avoid errors.
touch ./db.txt
#inset txpower in db.txt
#Correcting pipes... 
sed -i -e 's/(5250 - 5350 @ 80), (30)/(5250 - 5350 @ 80), ('$txpower')/g' ./db.txt
sed -i -e 's/(5470 - 5725 @ 160), (30)/(5470 - 5725 @ 160), ('$txpower')/g' ./db.txt
sed -i -e 's/(5725 - 5875 @ 80), (30)/(5725 - 5875 @ 80), ('$txpower')/g'  ./db.txt
sed -i -e 's/(2402 - 2482 @ 40), (30)/(2402 - 2482 @ 40), ('$txpower')/g'  ./db.txt
sed -i -e 's/(5170 - 5250 @ 80), (30)/(5170 - 5250 @ 80), ('$txpower')/g'  ./db.txt
sed -i -e 's/(5250 - 5330 @ 80), (30)/(5250 - 5330 @ 80), ('$txpower')/g'  ./db.txt
sed -i -e 's/(5490 - 5710 @ 160), (30)/(5490 - 5710 @ 160), ('$txpower')/g' ./db.txt
sed -i -e 's/(5170 - 5250 @ 80), (30)/(5170 - 5250 @ 80), ('$txpower')/g' ./db.txt
sed -i -e 's/(5250 - 5330 @ 80), (30)/(5250 - 5330 @ 80), ('$txpower')/g' ./db.txt
sed -i -e 's/(5490 - 5730 @ 160), (30)/(5490 - 5730 @ 160), ('$txpower')/g' ./db.txt
sed -i -e 's/(2400 - 2494 @ 40), (30)/(2400 - 2494 @ 40), ('$txpower')/g' ./db.txt
sed -i -e 's/(4910 - 5835 @ 40), (30)/(4910 - 5835 @ 40), ('$txpower')/g' ./db.txt

#copy modified db.txt  
cp db.txt wireless-regdb-2017.12.23/db.txt

#compile regulatory.db
make -C wireless-regdb-2017.12.23

#backup the old regulatory.bin and move the new file into /lib/crda
mv /lib/crda/regulatory.bin /lib/crda/regulatory.bin.old
mv wireless-regdb-2017.12.23/regulatory.bin /lib/crda

#copy pubkeys
cp wireless-regdb-2017.12.23/*.pem crda-3.18/pubkeys
#if the extra pubkeys exist, copy them too
if [ -e /lib/crda/pubkeys/benh\@debian.org.key.pub.pem ] ; then
cp /lib/crda/pubkeys/benh\@debian.org.key.pub.pem crda-3.18/pubkeys
fi
if [ -e /lib/crda/pubkeys/linville.key.pub.pem ] ; then
cp /lib/crda/pubkeys/linville.key.pub.pem crda-3.18/pubkeys
fi

#change regulatory.bin path in the Makefile
sed -i "/REG_BIN?=\/lib\/crda\/regulatory.bin/!b;cREG_BIN?=\/lib\/crda\/regulatory.bin" crda-3.18/Makefile
#remove -Werror option when compiling
sed -i "/CFLAGS += -std=gnu99 -Wall -Werror -pedantic/!b;cCFLAGS += -std=gnu99 -Wall -pedantic" crda-3.18/Makefile

#compile
make clean -C crda-3.18
make -C crda-3.18
make install -C crda-3.18

#reboot
printf "A system reboot is required to apply changes. Do you want to reboot now ? [Yes,No,Y,N]:"
read -r reboot
if [ ${reboot,,} == "y" ] || [ ${reboot,,} == "yes" ] ; then
echo "Rebooting..."
reboot
elif [ ${reboot,,} == "n" ] || [ ${reboot,,} == "no" ] ; then
echo "You chose not to reboot. Please reboot the system manually."
else
echo "Invalid option. Please reboot the system manually."
fi
