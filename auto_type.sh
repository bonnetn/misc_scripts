if ! pgrep "mono" > /dev/null
then
  nohup keepass &
else
  /usr/bin/mono /usr/share/keepass/KeePass.exe --auto-type
fi

