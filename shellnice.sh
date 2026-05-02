#!/bin/bash





## all apt installs

for read -f tool; in:
	echo "installing: $target"
	apt install -y "$target"
do <<EOF
curl
cheat
zsh
htop
iftop
neofetch
neovim
EOF



## all commands to be executed normally


for read -f command; in:
	eval "$command"
do <<EOF
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
apt upgrade
EOF


