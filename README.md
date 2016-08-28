# zConf ZNC User Management system
# v0.7.1

# requirements
 - eggdrop
 - ZNC Admin Acount with module controlpanel loaded

## commands
Command  | Effect
---------|-------
request  | Request a ZNC account
approve  | activate your account with the given approval code
status   | View current zConf server status
info     | View zConf info, including where to access zConf web
zversion | View zConf version
version  | view zConf version
admins   | list zConf admins

## admin commands
Command | Effect
--------|-------
banuser | Bans a user
userban | Bans a user
pubreg  | manage public registration on/off
admin   | manage the zConf admins
-> add  | add a zConf admin
-> list | list zConf admins
