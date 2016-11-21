# zConf ZNC User Management system
# v0.7.3

# requirements
 - eggdrop
 `- Tested on 1.8.0 RC-1, but should work fine on 1.6.21
 - ZNC Admin Acount with module controlpanel loaded
 `- Account should be named zconf

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
access   | view the zConf ZNC "access points" - what to connect to
pwdgen   | generate a random password using the default password length

## admin commands
Command   | Effect
----------|-------
freeze    | Freeze an account
restore   | Unfreeze an account
purge     | Delete an account
listusers | list all users on znc
pubreg    | manage public registration on/off
admin     | manage the zConf admins
-> add    | add a zConf admin
-> list   | list zConf admins
