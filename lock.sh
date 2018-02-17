#!/bin/sh
# Lock all Keepass, forget SSH keys, forget GPG keys, forget sudo passwords and
# lock

/usr/bin/pkill keepassxc
# qdbus org.keepassxc.MainWindow /keepassxc org.keepassxc.MainWindow.lockAllDatabases
echo "[x] Closed all opened Keepass files"

/usr/bin/ssh-add -D 
echo "[x] Forgot about all SSH keys"

/usr/bin/killall -s HUP gpg-agent 
echo "[x] Forgot about all GPG keys"

/usr/bin/sudo -K 
echo "[x] Cleared sudo permissions"

/usr/local/bin/physlock -d -s -p 'This computer is locked, thou shall mind your own business... - InsolentBacon'
