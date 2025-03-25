sudo apt install python3 python-is-python3 pipx syncthing openssh-server openssh-client
pipx install ansible
# get keepassxc working and access github and download the ansible playbook
# add keypassxc ppa and install it
# get db from syncthing
# sign in to github
# create ssh key pair

# send ssh key to github
xclip -sel clip ~/.ssh/id_rsa.pub

# clone dotfiles
cd ~/git/dotfiles/ansible
ansible-playbook -i inventory.ini playbook.yml


