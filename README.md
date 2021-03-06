# zConf ZNC User Management system
# v0.9

If you need help, or have an issue, please use the GitHub issue tracking, however you can contact me
on irc.rvzm.me, channel #zhost :)

To get started, edit 'zconf-settings.tcl.dist' and save as 'zconf-settings.tcl'

!!! zConf is still in BETA TESTING - some features may not work

## special thanks to PentSec aka Deliri0m on freenode for translating into spanish :D

## Requirements
 - eggdrop 1.8
 - tcl package sqlite3
 - ZNC with admin

## ZNC
 your ZNC should have a 'zconf' account with admin rights, the password will be set in the zconf-settings.tcl

 You should have the following modules loaded:
 - controlpanel
 - blockuser
 - lastseen
 
## Run Notes

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
help     | get help with zConf
version  | view zConf version
adminlist| list zConf admins
access   | view the zConf ZNC "access points" - what to connect to
pwdgen   | generate a random password using the default password length

## admin commands
Command   | Effect
----------|-------
lastseen  | Show last connection of a user
admin     | manage the zConf admins
-> regset | manage public registration on/off
-> approve| approve an account
-> add    | add a zConf admin
-> remove | remove a zConf admin
-> reg    | register a user
-> freeze | Freeze an account
-> restore| Unfreeze an account
-> purge  | Delete an account
m         | moderator command
-> op     | give a user operator status
-> deop   | remove a users operator status
-> voice  | grant a user voice status 
-> devoice| remove a users voice status
-> kick   | kick a user from the channel
-> ban    | ban a user from the channel