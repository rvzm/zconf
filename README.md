# zConf ZNC User Management system
# v0.7.7

For support, visit #znc on irc.fukin.tech,
or email rvzm@protonmail.com, or on the web
at https://fukin.tech/support/

## special thanks to PentSec aka Deliri0m on freenode

# requirements
 - eggdrop
 `- Tested on 1.8.0rc-4, but should work fine on 1.6.21
 - ZNC Admin Acount with modules controlpanel and blockuser loaded
 `- Account should be named zconf
 - sudo apt install libsqlite3-tcl tcl8.6-tdbc-sqlite3
 - dcc command add ZNC .+bot znc .+host znc *!znc@znc.in .chattr znc +f 

## commands
Command  | Effect
---------|-------
request  | Request a ZNC account
approve  | activate your account with the given approval code
status   | View current zConf server status
info     | View zConf info, including where to access zConf web
help     | get help with zConf
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
lastseen  | Show last connection of user
pubreg    | manage public registration on/off
admin     | manage the zConf admins
-> add    | add a zConf admin
-> list   | list zConf admins
