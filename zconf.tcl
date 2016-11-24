# zconf.tcl - v0.7.5
# ZNC user management system
# --------------------------
# Requires ZNC admin account
#  named zconf.
# --------------------------
#  - env -
#  Tested on Eggdrop 1.8.0 RC-1
#  Should work on 1.6.21
putlog "zConf: Loading...";
if {[catch {source scripts/zconf/zconf-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/zconf/zconf-settings.tcl' file.";
}

namespace eval zconf {
	namespace eval setup {
                proc getPath {} {
                        global zconf::settings::path
                        return $zconf::settings::path
                }
		proc write_db { w_db w_info } {
                        set fs_write [open $w_db w]
                        puts $fs_write "$w_info"
                        close $fs_write
                }
		if {![file exists "[getPath]/userdir"]} {
        		file mkdir "[getPath]/userdir"
        		file mkdir "[getPath]/userdir/settings"
        		file mkdir "[getPath]/userdir/admin"
		}
		if {![file exists "[getPath]/userdir/settings/regset"]} {
			set path [getPath]
			set regdb "$path/userdir/settings/regset"
			write_db $regdb "public"
		}
	}
	namespace eval bind {
		# zConf Public Commands
		bind pub - ${zconf::settings::pubtrig}request zconf::proc::request
		bind pub - ${zconf::settings::pubtrig}approve zconf::proc::approve
		bind pub - ${zconf::settings::pubtrig}version zconf::proc::version
		bind pub - ${zconf::settings::pubtrig}info zconf::proc::info
		bind pub - ${zconf::settings::pubtrig}help zconf::help::main
		bind pub - ${zconf::settings::pubtrig}status zconf::proc::status
		bind pub - ${zconf::settings::pubtrig}admins zconf::proc::admins
		bind pub - ${zconf::settings::pubtrig}access zconf::proc::access
		bind pub - ${zconf::settings::pubtrig}pwdgen zconf::proc::pwdgen
		# zConf Admin Commands
		bind pub - ${zconf::settings::pubtrig}admin zconf::proc::admin::admin
		bind pub - ${zconf::settings::pubtrig}chk zconf::proc::check
		bind pub - ${zconf::settings::pubtrig}freeze zconf::proc::admin::freeze
		bind pub - ${zconf::settings::pubtrig}purge zconf::proc::admin::purge
		bind pub - ${zconf::settings::pubtrig}restore zconf::proc::admin::restore
		bind pub - ${zconf::settings::pubtrig}regset zconf::proc::admin::regset
		bind pub - ${zconf::settings::pubtrig}listusers zconf::proc::admin::listusers
		# Return from ZNC
		bind msgm - * zconf::proc::znccheck
		# DCC commands
		bind dcc m znc zconf::proc::znc
		bind dcc m nsauth zconf::proc::nsauth
		bind dcc m addadmin zconf::proc::admin::dccadmadd
	}
	namespace eval proc {
		proc request {nick uhost hand chan text} {
			if {[lindex [split $text] 0] == ""} { putserv "PRIVMSG $chan :Error - Please specify username."; return }
			set path [zconf::util::getPath]
			set regdb "$path/userdir/settings/regset"
			set udb "$path/userdir/$nick"
			set bdb "$path/userdir/$nick.freeze"
			set b2db "$path/userdir/[lindex [split $text] 0].freeze"
			set ndb "$path/userdir/$nick.un"
			set nickdb "$path/userdir/[lindex [split $text] 0].nick"
			set regstat [zconf::util::read_db $regdb]
			if {$regstat == "public"} {
				if {[file exists $udb]} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
				if {[file exists $bdb]} { putserv "PRIVMSG $chan :Error - Account frozen: [zconf::util::read_db $bdb]"; return }
				if {[file exists $b2db]} { putserv "PRIVMSG $chan :Error - Account frozen: [zconf::util::read_db $b2db]"; return }
				if {[file exists $ndb]} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
				set authnick "$path/userdir/$nick.auth"
				zconf::util::write_db $ndb [lindex [split $text] 0]
				zconf::util::write_db $nickdb $nick
				zconf::util::write_db $authnick [zconf::util::randpass 5]
	                        global target
        	                set target "^chan"
				putserv "NOTICE $nick :Your approval code is [zconf::util::read_db $authnick] | type ${zconf::settings::pubtrig}approve <code> to finish"
				return
			}
			if {$regstat == "off"} { putserv "PRIVMSG $chan :Error - Public registration is disabled."; return }
		}
		proc approve {nick uhost hand chan text} {
			set v1 [lindex [split $text] 0]
			set path [zconf::util::getPath]
			set udb "$path/userdir/$nick"
			if {![llength [split $v1]]} { putserv "PRIVMSG $chan Error - Please include your auth code"; return }
			if {[file exists $udb]} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
			set authnick "$path/userdir/$nick.auth"
			set propcode [zconf::util::read_db $authnick]
			if {![string match $v1 $propcode]} { putserv "PRIVMSG $chan :Error - Inavlid auth code"; return }
			if {[string match $v1 $propcode]} {
				putserv "PRIVMSG $chan :Your ZNC password will be /notice'd to you."
				putserv "PRIVMSG $chan :You can view the access points for your znc via ${zconf::settings::pubtrig}access"
				set passwd [zconf::util::randpass ${zconf::settings::passlen}]
				set ndb "$path/userdir/$nick.un"
	                        global target
	                        set target "^chan"
				putserv "PRIVMSG *controlpanel :AddUser [zconf::util::read_db $ndb] $passwd"
				putserv "NOTICE $nick :$passwd"
			}
		}
		proc access {nick uhost hand chan text} {
			putserv "PRIVMSG $chan : - Access Points for zConf ZNC"
			putserv "PRIVMSG $chan :Via IRC - ${zconf::settings::irclink}"
			putserv "PRIVMSG $chan :Via Web - ${zconf::settings::weblink}"
		}
		proc version {nick uhost hand chan text} {
			putserv "PRIVMSG $chan :zconf.tcl - zConf v[getVersion] ZNC Account management system"
		}
		proc info {nick uhost hand chan text} {
			putserv "PRIVMSG $chan :zConf is currently running."
			putserv "PRIVMSG $chan :Access zConf ZNC at [getURL]"
		}
		proc pwdgen {nick uhost hand chan text} {
			putserv "NOTICE $nick :Your randomly generated password is: [zconf::util::randpass ${zconf::settings::passlen}]"
		}
		proc status {nick uhost hand chan text} {
			set hostname [exec hostname]
			set commandfound 0;
			set fp [open "| uptime"]
			set data [read $fp]
			if {[catch {close $fp} err]} {
			putserv "PRIVMSG $chan :Error getting status..."
			} else {
			set output [split $data "\n"]
			foreach line $output {
				putserv "PRIVMSG $chan :${line}"
				}
			}
		}
		proc admins {nick uhost hand chan text} { putserv "PRIVMSG $chan :[zconf::util::listadmin $chan]"}
		proc znc {hand idx text} {
			putserv "PASS :zconf:[zncPass]"
		}
		proc nsauth {hand idx text} {
			putserv "PRIVMSG NickServ :IDENTIFY [getPass]"
		}
		proc check {nick uhost hand chan text} {
			putserv "PRIVMSG $chan :Admin Check - [isAdmin $nick]";
		}
		proc znccheck {nick uhost hand text} {
			if {$hand == "znc"} {
				putlog "zconf - $nick / $hand / $text"
				global target
				if {$target == "^chan"} { set method "PRIVMSG"; set target [getChan]; } else { set method "NOTICE"; }
				putserv "$method $target :$text";
			}
		}
		proc getPass {} {
			global zconf::settings::pass
			return $zconf::settings::pass
		}
		proc zncPass {} {
			global zconf::settings::zncpass
			return $zconf::settings::zncpass
		}
		proc getChan {} {
			global zconf::settings::zchan
			return $zconf::settings::zchan
		}
		proc getURL {} {
			global zconf::settings::url
			return $zconf::settings::url
		}
		proc getVersion {} {
			global zconf::settings::version
			return $zconf::settings::version
		}
		proc isAdmin {nick} {
			if {[file exists "[zconf::util::getPath]/userdir/admin/$nick"]} { return "1" } else { return "0" }
		}
		namespace eval admin {
			proc isAdmin {nick} {
				if {[file exists "[zconf::util::getPath]/userdir/admin/$nick"]} { return "1" } else { return "0" }
			}
			proc listusers {nick uhost hand chan text} {
				if {[isAdmin $nick] == "0"} { putserv "PRIVMSG $chan :Error - only admins can run that command."; return }
				global target
				set target $nick
				putserv "PRIVMSG *controlpanel :ListUsers"
			}
			proc freeze {nick uhost hand chan arg} {
				if {[isAdmin $nick] == "0"} { putserv "PRIVMSG $chan :Error - only admins can run that command."; return }
				set txt [split $arg]
				set v1 [string tolower [lindex $txt 0]]
				set msg [join [lrange $txt 1 end]]
				if {![llength [split $v1]]} { putserv "PRIVMSG $chan :Please specify a username and a reason"; return }
				if {![llength [split $msg]]} { putserv "PRIVMSG $chan :Please specify a username and a reason"; return }
				set path [zconf::util::getPath]
				set ndb "$path/userdir/$v1.nick"
				set bnick [zconf::util::read_db $ndb]
				set udb "$path/userdir/$v1.freeze"
				if {![file exists $ndb]} { putserv "PRIVMSG $chan :Error - User does not exist"; return }
				if {[file exists $udb]} {
					if {[lindex [split [zconf::util::read_db $udb]] 0] == "Frozen"} { putserv "PRIVMSG $chan :Error - User already frozen"; return }
				}
				global target
				set target "^chan"
				zconf::util::write_db $udb "Frozen for $msg"
				putserv "PRIVMSG $chan :Freezing user $v1 for $msg"
				putserv "PRIVMSG *blockuser :block $v1"
			}
			proc restore {nick uhost hand chan text} {
				if {[isAdmin $nick] == "0"} { putserv "PRIVMSG $chan :Error - only admins can run that command."; return }
				set v1 [lindex [split $text] 0]
				if {![llength [lindex [split $text] 0]]} { putserv "PRIVMSG $chan :Please specify a username"; return }
				set path [zconf::util::getPath]
				set ndb "$path/userdir/$v1.nick"
				set bnick [zconf::util::read_db $ndb]
				set udb "$path/userdir/$v1.freeze"
				if {![file exists $ndb]} { putserv "PRIVMSG $chan :Error - User does not exist"; return }
				if {![file exists $udb]} { putserv "PRIVMSG $chan :Error - User is not banned"; return }
				global target
				set target "^chan"
				zconf::util::write_db $udb "unfrozen"
				putserv "PRIVMSG $chan :Unfreezing user $v1"
				putserv "PRIVMSG *blockuser :unblock $v1"
			}
			proc purge {nick uhost hand chan text} {
				if {[isAdmin $nick] == "0"} { putserv "PRIVMSG $chan :Error - Only admins can run that command"; return }
				set d "yes"
				if {$d == "yes"} { putserv "PRIVMSG $chan :Error- command disabled."; return }
				set v1 [lindex [split $text] 0]
				set path [zconf::util::getPath]
				set ndb "$path/userdir/$v1.nick"
				set bnick [zconf::util::read_db $ndb]
				set udb "$path/userdir/$v1.freeze"
				if {![file exists $ndb]} { putserv "PRIVMSG $chan :Error - User does not exist"; return }
				if {![file exists $udb]} { putserv "PRIVMSG $chan :User is not frozen - re-registration is possible"; }
				global target
				set target "^chan"
				putserv "PRIVMSG $chan :Purging account of $v1"
				putserv "PRIVMSG *controlpanel :DelUser $v1"
				set fp [open "| scripts/zconf/remove.sh $v1.nick $bnick.*"]
				set data [read $fp]
				if {[catch {close $fp} err]} {
				putserv "PRIVMSG $chan :Error removing files";
				} else {
				set output [split $data "\n"]
				putserv "PRIVMSG $chan :$output"
				}
			}
			proc dccadmadd {hand idx text} {
				set path [zconf::util::getPath]
				if {[file exists "$path/userdir/admin/$text"]} { putdcc $idx "zConf - Error - $text is already a zConf admin"; return }
				if {![file exists "$path/userdir/admin/$text"]} {
					set adb "$path/userdir/admin/$text"
					zconf::util::write_db $adb "1"
					if {[file exists $adb]} { putdcc $idx "zConf: Successfully added $text ad a zConf admin"; return }
					if {![file exists $adb]} { putdcc $idx "zConf: Error adding $text - please try again"; return }
				}
			}
			proc admin {nick uhost hand chan text} {
				if {[isAdmin $nick] == "0"} { putserv "PRIVMSG $chan :Error - only admins can run that command."; return }
				set v1 [lindex [split $text] 0]
				set v2 [lindex [split $text] 1]
				set v3 [lindex [split $text] 2]
				set v4 [lindex [split $text] 3]
				set v5 [lindex [split $text] 4]
				if {$v1 == "add"} {
					if {[file exists "[zconf::util::getPath]/userdir/admin/$v2"]} { putserv "PRIVMSG $chan :Error - $v2 is already a zConf admin"; return }
					if {![file exists "[zconf::util::getPath]/userdir/admin/$v2"]} {
						set path [zconf::util::getPath]
						set adb "$path/userdir/admin/$v2"
						zconf::util::write_db $adb "1"
						if {[file exists $adb]} { putserv "PRIVMSG $chan :zConf: Successfully added $v2 ad a zConf admin"; return }
						if {![file exists $adb]} { putserv "PRIVMSG $chan :zConf: Error adding $v2 - please try again"; return }
					}
				}
				if {$v1 == "list"} { putserv "PRIVMSG $chan :[zconf::util::listadmin $chan]"; return }
			}
			proc regset {nick uhost hand chan text} {
				if {[zconf::proc::isAdmin $nick] == "0"} { putserv "PRIVMSG $chan :Error - only admins can run that command."; return }
				set v1 [lindex [split $text] 0]
				if {![llength [split $v1]]} {
					putserv "PRIVMSG $chan :Error - please specify option."
					putlog "zConf \$ \[COMMAND LOG\] :admin: regset - no args"
					return
				}
				if {$v1 == "public"} {
					set path [zconf::util::getPath]
					set regdb "$path/userdir/settings/regset"
					zconf::util::write_db $regdb "public"
					putserv "PRIVMSG $chan :Registration set to Public"
					putlog "zConf \$ \[COMMAND LOG\] :admin: regset - args: public"
					return
				}
				if {$v1 == "off"} {
					set path [zconf::util::getPath]
					set regdb "$path/userdir/settings/regset"
					zconf::util::write_db $regdb "off"
					putserv "PRIVMSG $chan :Registration set to Off. | until reenabled, zConf will not accept new registrations."
					putserv "zConf \$ \[COMMAND LOG\] :admin: regset - args: "
				}
			}
		}
	}
	namespace eval help {
		proc main {nick uhost hand chan text} {
			set v1 [lindex [split $text] 0]
			set v2 [lindex [split $text] 1]
			set v3 [lindex [split $text] 2]
			set v4 [lindex [split $text] 3]
			set v5 [lindex [split $text] 4]
			set v6 [lindex [split $text] 5]
			if {![llength [split $v1]]} { putserv "PRIVMSG $chan :zConf::help - use the 'commands' subcommand for help with commands"; return }
			putserv "PRIVMSG $chan :zConf::help - command: $v1"
			if {$v1 == "commands"} {
				putserv "NOTICE $nick :version request approve info zhelp status"
				putserv "NOTICE $nick :to find out more, use /msg [getNick] zhelp \037command\037"
				putserv "PRIVMSG $chan :version request approve info status"
				putserv "PRIVMSG $chan :use 'help \037command\037' for more info"
			}
			if {$v1 == "version"} { putserv "PRIVMSG $chan :zConf::help - version - Prints version information"; return }
			if {$v1 == "request"} { putserv "PRIVMSG $chan :zConf::help - request - Request a ZNC account"; return }
			if {$v1 == "approve"} { putserv "PRIVMSG $chan :zConf::help - Approve your account with the given code"; return }
			if {$v1 == "info"} { putserv "PRIVMSG $chan :zConf::help - Prints information about zconf"; return }
			if {$v1 == "status"} { putserv "PRIVMSG $chan :zConf::help - show server status, uptime, and load"; return }
		}
		proc getNick {} {
			global botnick
			return $botnick
		}
	}
	namespace eval util {
                proc getPath {} {
                        global zconf::settings::path
                        return $zconf::settings::path
                }
		# write to *.db files
		proc write_db { w_db w_info } {
			set fs_write [open $w_db w]
			puts $fs_write "$w_info"
			close $fs_write
		}
		# read from *.db files
		proc read_db { r_db } {
			set fs_open [open $r_db r]
			gets $fs_open db_out
			close $fs_open
			return $db_out
		}
		# create *.db files, servers names files
		proc create_db { bdb db_info } {
			if {[file exists $bdb] == 0} {
				set crtdb [open $bdb a+]
				puts $crtdb "$db_info"
				close $crtdb
			}
		}
		proc getVersion {} {
			global $zconf::settings::version
			return $zconf::settings::version
		}
		proc randpass {length {chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"}} {
		set range [expr {[string length $chars]-1}]
		set txt ""
		for {set i 0} {$i < $length} {incr i} {
			set pos [expr {int(rand()*$range)}]
			append txt [string range $chars $pos $pos]
			}
		return $txt
		}
		proc listadmin {chan} {
			putserv "PRIVMSG $chan :- Current zConf admin listing -"
			set commandfound 0;
			set fp [open "| scripts/zconf/list.sh"]
			set data [read $fp]
			if {[catch {close $fp} err]} {
			putserv "PRIVMSG $chan :Error listing admins..."
			} else {
			set output [split $data "\n"]
			putserv "PRIVMSG $chan :$output"
			}
		}
	}
}

putlog "zConf: Loaded version [zconf::util::getVersion]"
