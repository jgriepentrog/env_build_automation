#!/bin/bash
# Assumes Ubuntu Budgie 18.10 Minimal Install

#Vars
#NEED TO SET FOLLOWING VARS PRIOR TO RUNNING SCRIPT: username, gitRepos

email="1390583+jgriepentrog@users.noreply.github.com"
name="John Griepentrog"

VM="VM"
Phys="Physical"
Exit="Exit"
PS3="Please enter your choice: "
options=("$VM" "$Phys" "$Exit")
select opt in "${options[@]}"
do
    case $opt in
        "$VM")
            break
            ;;
        "$Phys")
            break
            ;;
        "$Exit")
			echo "Exiting as requested"
			exit 1
            ;;
        *) echo invalid option;;
    esac
done

#Set up codename
source /etc/os-release
codename=`lsb_release -cs`

#Get kernel
kernel=`uname -r`

#Add repos

#VS Code - Official
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

#KeePass - PPA
sudo add-apt-repository ppa:jtaylor/keepass

#Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

#Dropbox
#Set manually to xenial - update if available
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5044912E
echo "deb https://linux.dropbox.com/ubuntu/ xenial main" | sudo tee /etc/apt/sources.list.d/dropbox.list

#Node (8 to match Lambda)
nodeVersion=8
curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
echo "deb https://deb.nodesource.com/node_$nodeVersion.x $codename main" | sudo tee /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/node_$nodeVersion.x $codename main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list

#Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

#Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list
   
#Update package list to latest
sudo apt-get update

#Remove unneeded / unused items
sudo apt-get remove firefox -y

#Clean up from removal
sudo apt-get autoremove -y

#Upgrade remainder
sudo apt-get upgrade -y

#Install packages
sudo apt-get install -y lightdm-settings && \
sudo apt-get install -y gedit && \
sudo apt-get install -y gthumb && \
sudo apt-get install -y net-tools && \
sudo apt-get install -y build-essential && \
sudo apt-get install -y google-chrome-stable && \
sudo apt-get install -y keepass2 && \
sudo apt-get install -y dropbox && \ 
#sudo apt-get install -y python-gpgme
sudo apt-get install -y keychain && \
sudo apt-get install -y git && \
sudo apt-get install -y code && \
sudo apt-get install -y nodejs && \
sudo apt-get install -y yarn && \
sudo apt-get install -y python-pip && \
sudo apt-get install -y docker-ce

#Set Up LivePatch
sudo snap install canonical-livepatch

#VirtualBox Guest Additions (VM only)
if [ $opt = $VM ]; then 
	#Download and install latest guest additions
	wget https://download.virtualbox.org/virtualbox/LATEST.TXT
	latest=`cat LATEST.TXT`
	rm -f LATEST.TXT
	#Can no longer use with newest kernel 4.10+
	#latest="5.0.16" #Override latest to working 3D acceleration
	wget "https://download.virtualbox.org/virtualbox/$latest/VBoxGuestAdditions_$latest.iso"
	sudo mkdir /media/iso
	sudo mount -o loop "VBoxGuestAdditions_$latest.iso" /media/iso
	sudo /media/iso/VBoxLinuxAdditions.run
	sudo umount -f /media/iso
	rm "VBoxGuestAdditions_$latest.iso"
fi

#Physical build packages
if [ $opt = $Phys ]; then 
	#Add repos
	sudo add-apt-repository ppa:remmina-ppa-team/remmina-next
	sudo add-apt-repository ppa:nathan-renniewaldock/flux

	#Update package list to latest
	sudo apt-get update

	#Install packages
	sudo snap install remmina
	sudo apt-get install -y flux fluxgui
	sudo apt-get install -y remmina remmina-plugin-rdp libfreerdp-plugins-standard
	sudo apt-get install -y openvpn
	sudo apt-get install -y network-manager-openvpn
	sudo apt-get install -y network-manager-openvpn-gnome
	sudo apt-get install -y adb
	
	sudo restart network-manager
	
	#Install EasyTether
	wget http://www.mobile-stream.com/beta/ubuntu/16.04/easytether_0.8.8_amd64.deb
	sudo dpkg -i easytether_0.8.8_amd64.deb
	echo "source-directory interfaces.d" | sudo tee -a /etc/network/interfaces
	
	#ADB config
	sudo touch /etc/udev/rules.d/51-android.rules
	echo 'SUBSYSTEM==\"usb\", ATTR{idVendor}==\"22b8\", MODE=\"0666\", GROUP=\"plugdev\"' | sudo tee -a /etc/udev/rules.d/51-android.rules	
fi

#Install non-repo packages

#Postman
#wget https://dl.pstmn.io/download/latest/linux64 -O postman.tar.gz
#sudo tar -xzf postman.tar.gz -C /opt
#rm postman.tar.gz
#sudo ln -s /opt/Postman/Postman /usr/bin/postman
#cat > ~/.local/share/applications/postman.desktop <<EOL
#[Desktop Entry]
#Encoding=UTF-8
#Name=Postman
#Exec=postman
#Icon=/opt/Postman/resources/app/assets/icon.png
#Terminal=false
#Type=Application
#Categories=Development;
#EOL

#Insomnia REST
sudo snap install insomnia

#OpenSSL 1.1.0+
#opensslVersion="openssl-1.1.0h"
#cd ~ && wget -O - "https://www.openssl.org/source/$opensslVersion.tar.gz" | tar xzf -
#cd "$opensslVersion"
#./config
#make
#sudo make install
#sudo sh -c 'echo "/usr/local/lib64" > /etc/ld.so.conf.d/openssl.conf'
#sudo ldconfig

#OpenSSH 7.6+
#sudo apt-get install -y lib32z1-dev

#Dropbox
#cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
#~/.dropbox-dist/dropboxd &
#dropbox autostart y

#Clean up
sudo apt-get autoremove -y

read -p "Press any key to continue... " -n1 -s

#Package config

#Watches
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf

#Backgrounds
sudo cp /home/john/Dropbox/bgs/Std2fCM.jpg /usr/share/backgrounds/

#Docker
sudo gpasswd -a $username docker

#NPM - Update to latest
sudo npm install npm@latest -g

#Atom
#apm install atom-ide-ui
#apm install ide-typescript
#apm install node-debugger
#apm install language-babel
#apm install linter
#apm install linter-eslint
#apm install docblockr
#apm install split-diff

#VS Code Extensions
code --install-extension aws-amplify.aws-amplify-vscode

#Git
git config --global user.email $email
git config --global user.name $name
git config --global push.default simple

#Set up SSH keys
mkdir ~/.ssh
cp ~/Dropbox/keys/* ~/.ssh
chown -R $username ~/.ssh
chmod -R 700 ~/.ssh

#Set up project directory
mkdir Development
cd Development

#Git clone repositories
for repo in "${gitRepos[@]}"
do
	git clone $repo
done

#Set environment vars
echo '' >> ~/.profile

#AWS Setup and Upgrade
python -m pip install --upgrade pip 
python -m pip install setuptools --upgrade --user
python -m pip install awscli --upgrade --user

#SAM Setup
python -m pip install aws-sam-cli --upgrade --user

#NPM Globals
yarn global add eslint eslint-config-standard eslint-plugin-import eslint-plugin-node eslint-plugin-promise eslint-plugin-standard eslint-plugin-react babel-eslint eslint-plugin-babel
yarn global add lerna
yarn global add jest
