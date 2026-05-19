#!/bin/bash

IFS= read -r -d '' WELCOME << 'EOF'
  _________.__           .__  .__         .__              
 /   _____/|  |__   ____ |  | |  |   ____ |__| ____  ____  
 \_____  \ |  |  \_/ __ \|  | |  |  /    \|  | ____\/ __ \ 
 /        \|   Y  \  ___/|  |_|  |_|   |  \  \  \__\  ___/ 
/_______  /|___|  /\___  >____/____/___|  /__|\___  >___  >
        \/      \/     \/               \/        \/    \/ 
EOF

IFS= read -r -d '' HELP << 'EOF'
shellnice - makes your shell nice!
this will install zsh, oh-my-zsh, neovim and fastfetch.
usage: Shellnice.sh [flags] 
	flags:
		-r	reboots the machine at the end of everything
		-e	installs extended Toolset
		-h	display this text
EOF
SHELLSWAP=true
REBOOT=false
EXTENDED=false




main() {
	## handle cli flags
	while getopts "reh" opt; do
		case $opt in
			r)	REBOOT=true;;
			e)	EXTENDED=true;;
			h)	echo "$HELP";exit;;
		esac
	done

	## run the components:
	apt update -y
	install_basic_toolset
	if [ "$EXTENDED" == true ]; then
		install_extended_toolset
	fi
	if [ "$REBOOT" == true ]; then
		reboot_routine
	else
		echo "$WELCOME"
		echo 'installation complete. rerun with -r to reboot after install'
	fi
}



## the components

install_basic_toolset() {
	echo 'installing basic packages ...'

	## apt packages
	while read -r target; do
		echo "installing: $target"
		apt install -y "$target"
	done <<EOF
git
curl
zsh
tree
fastfetch
neovim
EOF

echo "running Postinstall commands"
CHSH=no sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 
apt -y upgrade
chsh -s \$(which zsh) \${SUDO_USER:-\$USER}


#	## all commands to be executed normally
#	while read -r command; do
#		eval "$command"
#	done <<EOF
#CHSH=no sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
#apt -y upgrade
#chsh -s \$(which zsh) \${SUDO_USER:-\$USER}
#EOF
}


install_extended_toolset() {
	echo 'installing extended packages...'

	## all apt installs
	while read -r target; do
		echo "installing: $target"
		apt install -y "$target"
	done <<EOF
tmux
htop
iftop
broot
EOF

	## all commands to be executed normally
	while read -r command; do
		eval "$command"
	done <<EOF
apt -y upgrade
EOF
}


reboot_routine() {
	local target_user="${SUDO_USER:-$USER}"
	local target_home
	target_home=$(getent passwd "$target_user" | cut -d: -f6)
 
	local marker="$target_home/.config/.shellnice_welcome_shown"
	local profile_script="/etc/profile.d/shellnice_welcome.sh"
 
	# post_reboot_commands-Funktion als Text exportieren
	local post_reboot_fn
	post_reboot_fn=$(declare -f post_reboot_commands)
 
	# Script nach /etc/profile.d/ schreiben — kein .bashrc anfassen
	cat > "$profile_script" << SCRIPT
#!/bin/bash
# shellnice: einmalige Welcome-Message nach Setup-Reboot
# Liegt in /etc/profile.d/ und wird von jeder Login-Shell automatisch gesourct.
# Löscht sich selbst nach der Ausführung.
 
MARKER="$marker"
TARGET_USER="$target_user"
 
if [[ ! -f "\$MARKER" ]]; then
    mkdir -p "\$(dirname \$MARKER)"
    touch "\$MARKER"
    chown "$target_user:$target_user" "\$MARKER"
 
    cat << 'WELCOMEOF'
$WELCOME
WELCOMEOF
 
    fastfetch
 
    $post_reboot_fn
    post_reboot_commands "\$TARGET_USER"
 
    # nach Ausführung selbst entfernen — kein toter Code in profile.d
    rm -f "$profile_script"
fi
SCRIPT
 
	chmod +x "$profile_script"
	echo "welcome script installed to $profile_script"
 
	echo 'setup done — rebooting in 5 seconds. press ctrl+c to abort.'
	sleep 5
	reboot
} 

#############################################################
main "$@"
