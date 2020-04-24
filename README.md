# BashBackupScript
A simple and easy to use bash script to automatize your backups

To install it dump the file named "backup" into "/usr/local/bin" and make it executable, or just install the .deb package I provided in the releases tab.
anyway, you can use it as it is on whatever location you want.
use -h to get help like:
backup -h
If you install the .deb package you can see the manpage for detailed descriptions.
If you want to build this package to install the latest version I provided
a very short script that should work on any debian based distro that has installed
the commands gzip and dpkg-deb

a quick install from the master branch:
sudo apt update && sudo apt remove bash-backup -y && sudo apt install git -y && git clone https://github.com/reiikz/BashBackupScript && cd BashBackupScript && ./makedeb && sudo apt install -f $(pwd)/bash-backup_$(./backup -pv)_all.deb -y && cd .. && rm -rf BashBackupScript


If you wanna check the package here is my public key
http://repo.reiikz.tk/keys/dragon@reiikz.tk.asc
