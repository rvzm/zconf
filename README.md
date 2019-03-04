# zConf ZNC User Management system
# v0.7.8

For support, visit #zconf on irc.insomnia247.nl

## special thanks to PentSec aka Deliri0m on freenode

# requirements
## eggdrop
 zconf is tested on eggdrop 1.8

## ZNC
 your ZNC should have a 'zconf' account with
 admin rights

 You should have the following modules loaded:
 - controlpanel
 - blockuser
 - lastseen
 ====
 - requires tcl package sqlite3
 ====
 To avoid flood ignores for znc, telnet/DCC to bot and do these:
 - .+bot znc
 - .+host znc *!znc@znc.in
 - .chattr znc +f

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
-> reg    | register a user
-> list   | list zConf admins
