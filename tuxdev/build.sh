#!/bin/bash
# Assumes Ubuntu Budgie 18.10 Minimal Install
# Do not run whole script in sudo

###Setup###

##Env Vars##
#NEED TO SET FOLLOWING VARS PRIOR TO RUNNING SCRIPT: gitRepos

#Basic Info#
username=`whoami`

#Git Info#
email="1390583+jgriepentrog@users.noreply.github.com"
name="John Griepentrog"

#Platform#
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

#Ubuntu Release Codename#
source /etc/os-release
codename=`lsb_release -cs`

#Kernel
kernel=`uname -r`

###Package Installs###

##Add Repos##
#VS Code - Official#
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

#KeePass - PPA#
sudo add-apt-repository -y ppa:jtaylor/keepass

#Chrome - Official#
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] https://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

#Dropbox - Official#
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E 
echo "deb [arch=amd64] https://linux.dropbox.com/ubuntu/ $codename main" | sudo tee /etc/apt/sources.list.d/dropbox.list
#echo "deb [arch=amd64] https://linux.dropbox.com/ubuntu/ zesty main" | sudo tee /etc/apt/sources.list.d/dropbox.list

#Node#
nodeVersion=8 #Match current AWS Lambda
curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
echo "deb [arch=amd64] https://deb.nodesource.com/node_$nodeVersion.x $codename main" | sudo tee /etc/apt/sources.list.d/nodesource.list
echo "deb-src [arch=amd64] https://deb.nodesource.com/node_$nodeVersion.x $codename main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
#echo "deb [arch=amd64] https://deb.nodesource.com/node_$nodeVersion.x bionic main" | sudo tee /etc/apt/sources.list.d/nodesource.list && \
#echo "deb-src [arch=amd64] https://deb.nodesource.com/node_$nodeVersion.x bionic main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list && \

#Yarn#
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb [arch=amd64] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

#Docker#
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#Set manually to bionic - update as available, planned in Dec 2018
#echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list
echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" | sudo tee /etc/apt/sources.list.d/docker.list
   
#Update package list to latest
sudo apt-get update

##Packages Removals##
#Remove unneeded / unused items
sudo apt-get remove firefox -y
sudo apt-get remove plank -y

#Clean up from removal
sudo apt-get autoremove -y

##Package Upgrades##
sudo apt-get upgrade -y

##Package Installs##
aptPkgs="net-tools build-essential python-gpg python-pip "
aptPkgs+="lightdm-settings arc-theme "
aptPkgs+="gedit gthumb "
aptPkgs+="google-chrome-stable keepass2 dropbox "
aptPkgs+="keychain git "
aptPkgs+="nodejs yarn "
aptPkgs+="docker-ce "
aptPkgs+="code "
aptPkgs+="adb "

#Apt#
sudo apt-get install -y $aptPkgs

#Snaps#
sudo snap install canonical-livepatch
sudo snap install insomnia

#pip installs and upgrades
python -m pip install --upgrade pip 
python -m pip install setuptools --upgrade --user
#AWS CLI Install
python -m pip install awscli --upgrade --user
#SAM CLI Install
python -m pip install aws-sam-cli --upgrade --user


##Platform Specific Installs##
#VM
if [ $opt = $VM ]; then 
	#VirtualBox Guest Additions
	
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

#Physical
if [ $opt = $Phys ]; then 
	#Update package list to latest
	sudo apt-get update

	#Install packages
	sudo snap install remmina
	sudo apt-get install -y openvpn
	sudo apt-get install -y network-manager-openvpn
	sudo apt-get install -y network-manager-openvpn-gnome
	
	sudo restart network-manager
	
	#Install EasyTether
	wget http://www.mobile-stream.com/beta/ubuntu/18.04/easytether_0.8.9_amd64.deb
	sudo dpkg -i easytether_0.8.9_amd64.deb
	systemctl enable systemd-networkd
	systemctl start systemd-networkd
	#echo "source-directory interfaces.d" | sudo tee -a /etc/network/interfaces
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

read -p "Press any key to continue... " -n1 -s

###Package Config###

#ADB#
sudo touch /etc/udev/rules.d/51-android.rules
echo 'SUBSYSTEM==\"usb\", ATTR{idVendor}==\"2e17\", MODE=\"0666\", GROUP=\"plugdev\"' | sudo tee -a /etc/udev/rules.d/51-android.rules	

#Backgrounds#
cp ~/Dropbox/bgs/Std2fCM.jpg ~/Pictures
sudo cp ~/Dropbox/bgs/Std2fCM.jpg /usr/share/backgrounds
cp ~/Dropbox/bgs/fire-tiger_1920x1080.jpg ~/Pictures

#Login Screen#
sudo cp settings/lightdm/slick-greeter.conf /etc/lightdm

#Docker#
#Enables running Docker command without sudo
sudo gpasswd -a $username docker

#Atom#
#apm install atom-ide-ui
#apm install ide-typescript
#apm install node-debugger
#apm install language-babel
#apm install linter
#apm install linter-eslint
#apm install docblockr
#apm install split-diff

#VS Code#
#Settings
mkdir -p ~/.config/Code/User/
cp settings/vscode/* ~/.config/Code/User/
#Extensions
code --install-extension aws-amplify.aws-amplify-vscode
code --install-extension luqimin.velocity
code --install-extension peterjausovec.vscode-docker
code --install-extension dbaeumer.vscode-eslint
code --install-extension kumar-harsh.graphql-for-vscode
code --install-extension christian-kohler.npm-intellisense
code --install-extension zhuangtongfa.material-theme
code --install-extension robertohuertasm.vscode-icons
code --install-extension donjayamanne.githistory
code --install-extension vsmobile.vscode-react-native
code --install-extension eamodio.gitlens
code --install-extension slevesque.vscode-hexdump

#SSH Keys##
mkdir -p ~/.ssh
cp ~/Dropbox/keys/* ~/.ssh
chown -R $username ~/.ssh
chmod -R 700 ~/.ssh

#Set environment vars
echo '' >> ~/.profile
echo '# set PATH so it includes Yarn'"'"'s bin if it exists' >> ~/.profile
echo 'if yarn global bin &>/dev/null; then' >> ~/.profile
echo '    PATH="`yarn global bin`:$PATH"' >> ~/.profile
echo 'fi' >> ~/.profile
#AWS#
#CLI Setup
aws configure set default.region us-east-1
aws configure set default.output json

#NPM#
#Increases max watches which is needed for dealing with large # of files in a directory
#Can be common for large NPM dependencies trees
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
#Upgrade to latest
sudo npm install npm@latest -g
#Install NPM Globals
yarn global add eslint eslint-config-standard eslint-plugin-import eslint-plugin-node eslint-plugin-promise eslint-plugin-standard eslint-plugin-react babel-eslint eslint-plugin-babel
yarn global add lerna
yarn global add jest

#Finalize Desktop
dconf load / < settings/dconf/dconf-select-settings.config

#Project Directory#
mkdir ~/Development
cd ~/Development

#Git#
#Basic Config
git config --global user.email $email
git config --global user.name "$name"
git config --global push.default simple
#Set up repos
for repo in "${gitRepos[@]}"
do
	git clone $repo
done
