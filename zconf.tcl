# zConf.tcl
# ZNC user management system
# --------------------------

putlog "zConf: Loading...";

if {[catch {source scripts/zconf/zconf-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/zconf/zconf-settings.tcl' file.";
}
if {[catch {source scripts/zconf/zdb.tcl} err]} {
	putlog "Error: Could not load 'scripts/zconf/zdb.tcl' file";
	global zconf::settings::force
	if {$zconf::settings::force == "true"} {
		putlog "Forcing zdb.tcl load..."
		source scripts/zconf/zdb.tcl;
	}
}
if {![file exists "userdir/"]} {
	file mkdir "userdir/"
	}
if {![file exists "userdir/admin"]} {
	file mkdir "userdir/admin"
	putlog "zConf - please add your first admin nick using '.addadmin <nick>'"
	}
if {![file exists "userdir/settings.db"]} {
	if {[catch {zconf::zdb::makereg} err]} {
		putlog "zConf: Error creating settings db, to remedy this, use .makereg"
	}
}

namespace eval zconf {
	namespace eval bind {
		# zConf Public Commands
		bind pub - ${zconf::settings::pubtrig}request zconf::proc::request
		bind pub - ${zconf::settings::pubtrig}approve zconf::proc::approve
		bind pub - ${zconf::settings::pubtrig}version zconf::proc::version
		bind pub - ${zconf::settings::pubtrig}help zconf::help::main
		bind pub - ${zconf::settings::pubtrig}status zconf::proc::status
		bind pub - ${zconf::settings::pubtrig}adminlist zconf::proc::admins
		bind pub - ${zconf::settings::pubtrig}access zconf::proc::access
		bind pub - ${zconf::settings::pubtrig}pwdgen zconf::proc::pwdgen
		# zConf Admin Commands
		bind pub - ${zconf::settings::pubtrig}admin zconf::proc::admin::admin
		bind pub - ${zconf::settings::pubtrig}chk zconf::proc::check
		bind pub - ${zconf::settings::pubtrig}lastseen zconf::proc::admin::lastseen
		# Return from ZNC
		bind msgm - * zconf::proc::znccheck
		# DCC commands
		bind dcc m znc zconf::proc::znc
		bind dcc m makereg zconf::zdb::makereg
		bind dcc m nsauth zconf::proc::nsauth
		bind dcc m addadmin zconf::proc::admin::dccadmadd
	}
	namespace eval proc {
		proc request {nick uhost hand chan text} {
			set v1 [lindex [split $text] 0]
			if {$v1 eq ""} { putserv "PRIVMSG $chan :Error - Please specify username."; return }
			set regstat [zconf::zdb::regstat]
			set path [zconf::util::getPath]
			putlog "zconf::log - Request made for '$v1' by $nick - regstat: $regstat"
			if {$regstat == "public"} {
				if {[file exists "$path/userdir/$v1.db"]} {
					if {[zconf::zdb::get $v1 confirmed] == "true"} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
					putlog "zConf::log - checking waiting"
					if {[zconf::zdb::get $v1 confirmed] == "false"} { putserv "PRIVMSG $chan :Error - You have a pending request."; return }
					putlog "zConf::log - checking freeze"
					if {[zconf::zdb::get $v1 freeze] == "true"} { putserv "PRIVMSG $chan :Error - Account frozen"; return }
					}
				putlog "zConf::log - creating user"
				zconf::zdb::create $v1 $nick
				global target
				set target "^chan"
				putserv "PRIVMSG $chan :Account request submitted."
				putserv "NOTICE $nick :Your approval code is [zconf::zdb::get $v1 auth] | type ${zconf::settings::pubtrig}approve $v1 <code> to finish"
				return
			}
			if {$regstat == "admin"} {
				set v1 [lindex [split $text] 0]
				set path [zconf::util::getPath]
				if {[file exists "$path/userdir/$v1.db"]} {
					if {[zconf::zdb::get $v1 confirmed] == "true"} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
					putlog "zConf::log - checking waiting"
					if {[zconf::zdb::get $v1 confirmed] == "false"} { putserv "PRIVMSG $chan :Error - You have a pending request."; return }
					putlog "zConf::log - checking freeze"
					if {[zconf::zdb::get $v1 freeze] == "true"} { putserv "PRIVMSG $chan :Error - Account frozen"; return }
				}
				putlog "zConf::log - creating user"
				zconf::zdb::create $v1 admin
				global target
				set target "^chan"
				putserv "PRIVMSG $chan :Your request has been filed"
				putserv "PRIVMSG $chan :An admin will approve you when one is available"
			 }
			if {$regstat == "off"} { putserv "PRIVMSG $chan :Error - Public registration is disabled."; return }
		}
		proc approve {nick uhost hand chan text} {
			set v1 [lindex [split $text] 0]
			set v2 [lindex [split $text] 1]
			set path [zconf::util::getPath]
			if {$text eq ""} { putserv "PRIVMSG $chan :Error - Please use 'approve <account> <code>'"; return }
			if {$v2 eq ""} { putserv "PRIVMSG $chan :Error - Please include your auth code"; return }
			if {[zconf::zdb::get $v1 freeze] == "true"} { putserv "PRIVMSG $chan :Error - Your account is frozen"; return }
			if {[zconf::zdb::get $v1 confirmed] == "true"} { putserv "PRIVMSG $chan :Your account is already confirmed"; return }
			set propcode [zconf::zdb::get $v1 auth]
			if {![string match $v2 $propcode]} { putserv "PRIVMSG $chan :Error - Invalid auth code"; return }
			if {[string match $v2 $propcode]} {
				putserv "PRIVMSG $chan :Your ZNC password will be /notice'd to you."
				putserv "PRIVMSG $chan :You can view the access points for your znc via ${zconf::settings::pubtrig}access"
				set passwd [zconf::util::randpass ${zconf::settings::passlen}]
				global target
				set target "^chan"
				zconf::zdb::confirm $v1
				putserv "PRIVMSG *controlpanel :AddUser $v1 $passwd"
				putserv "NOTICE $nick :ZNC Password: $passwd"
			}
		}
		proc access {nick uhost hand chan text} {
			putserv "PRIVMSG $chan : - Access Points for zConf ZNC"
			putserv "PRIVMSG $chan :Via IRC - ${zconf::settings::irclink}"
			putserv "PRIVMSG $chan :Via Web - ${zconf::settings::weblink}"
		}
		proc version {nick uhost hand chan text} {
			putserv "PRIVMSG $chan :zConf.tcl - zConf v[zconf::util::getVersion] ZNC Account Management System"
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
		proc admins {nick uhost hand chan text} { putserv "PRIVMSG $chan :[zconf::util::listadmin $chan]"; }
		proc znc {hand idx text} { putserv "PASS :zConf:[zncPass]"; }
		proc nsauth {hand idx text} { putserv "PRIVMSG NickServ :IDENTIFY [getPass]"; }
		proc check {nick uhost hand chan text} { putserv "PRIVMSG $chan :Admin Check - [zconf::util::isAdmin $nick]"; }
		proc znccheck {nick uhost hand text} {
			if {$hand == "znc"} {
				set stop "no"
				putlog "zConf - $nick / $hand / $text"
				global target trig
				if {$nick == "*lastseen"} { if {[lindex [split $text] 1] == $trig} { set stop "yes"; putserv "PRIVMSG [zconf::util::getChan] :Last Seen Info"; putserv "PRIVMSG [getChan] :$text"; return } 
				} else {
				if {$target == "^chan"} { set method "PRIVMSG"; set target [zconf::util::getChan]; } else { set method "NOTICE"; }
				putserv "$method $target :$text"; }
			}
		}
		namespace eval admin {
			proc isAdmin {nick} {
				if {[file exists "[zconf::util::getPath]/userdir/admin/$nick"]} { return "1" } else { return "0" }
			}
			proc lastseen {nick uhost hand chan text} {
				if {[isAdmin $nick] == "0"} { putserv "PRIVMSG $chan :Error - only admins can run that command."; return }
				if {$text eq ""} { putserv "PRIVMSG $chan :Error - please specify a user"; return }
				global trig target
				set trig [lindex [split $text] 0]
				set target $nick
				putserv "PRIVMSG *lastseen :Show"
			}
			proc dccadmadd {hand idx text} {
				set path [zconf::util::getPath]
				if {$text eq ""} { putdcc $idx "zConf - Error - Please specify a name"; return }
				if {[file exists "$path/userdir/admin/$text"]} { putdcc $idx "zConf - Error - $text is already a zConf admin"; return }
				if {![file exists "$path/userdir/admin/$text"]} {
					set adb "$path/userdir/admin/$text"
					open "| touch $adb"
					zconf::util::write_db $adb "1"
					if {[file exists $adb]} { putdcc $idx "zConf: Successfully added $text ad a zConf admin"; return }
					if {![file exists $adb]} { putdcc $idx "zConf: Error adding $text - please try again"; return }
				}
			}
			# Admin Command
			proc admin {nick uhost hand chan text} {
				if {[isAdmin $nick] == "0"} { putserv "PRIVMSG $chan :Error - only admins can run that command."; return }
				putlog "zconf::adminlog - $nick $uhost -- $text";
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
						if {[file exists $adb]} { putserv "PRIVMSG $chan :zConf: Successfully added $v2 as a zConf admin"; return }
						if {![file exists $adb]} { putserv "PRIVMSG $chan :zConf: Error adding $v2 - please try again"; return }
					}
				}
				if {$v1 == "reg"} {
					set path [zconf::util::getPath]
					if {$v2 eq ""} { putserv "PRIVMSG $chan :Error - Please specify user."; return }
					if {[file exists "$path/userdir/$v1.db"]} { putserv "PRIVMSG $chan :Error - User already exists."; return }
					zconf::zdb::admcreate $v2
					set pw ${zconf::settings::passlen}
					set pwr [zconf::util::randpass $pw]
					putserv "NOTICE $nick :Generated Password - $pwr"
					putserv "PRIVMSG *controlpanel :AddUser $v2 $pwr"
				}
				if {$v1 == "list"} { putserv "PRIVMSG $chan :[zconf::util::listadmin $chan]"; return }
				if {$v1 == "freeze"} {
					set path [zconf::util::getPath]
					if {![llength [split $v2]]} { putserv "PRIVMSG $chan :Please specify a account"; return }
					if {![file exists "$path/userdir/$v2.db"]} { putserv "PRIVMSG $chan :Error - Account does not exist"; return }
					if {[zconf::zdb::get $v2 freeze]} { putserv "PRIVMSG $chan :Error - Account already frozen"; return }
					global target
					set target "^chan"
					zconf::zdb::freeze $v2
					putserv "PRIVMSG $chan :Freezing account for $v2"
					putserv "PRIVMSG *blockuser :block $v2"
					}
				if {$v1 == "restore"} {
					set path [zconf::util::getPath]
					if {$v2 eq ""} { putserv "PRIVMSG $chan :Please specify a username"; return }
					if {![file exists "$path/userdir/$v2.db"]} { putserv "PRIVMSG $chan :Error - Account does not exist"; return }
					if {[zconf::zdb::get $v2 freeze] == "false"} { putserv "PRIVMSG $chan :Error - Account is not frozen"; return }
					global target
					set target "^chan"
					zconf::zdb::unfreeze $v2
					putserv "PRIVMSG $chan :Unfreezing user $v2"
					putserv "PRIVMSG *blockuser :unblock $v2"
					}
				if {$v1 == "purge"} {
					if {$v2 eq ""} { putserv "PRIVMSG $chan :Error - Please specify an account"; return }
					set path [zconf::util::getPath]
					if {![file exists "$path/userdir/$v2.db"]} { putserv "PRIVMSG $chan :Error - Account does not exist"; return }
					global target
					set target "^chan"
					putserv "PRIVMSG $chan :Purging account of $v2"
					putserv "PRIVMSG *controlpanel :DelUser $v2"
					file delete "$path/userdir/$v2.db"
					putserv "PRIVMSG $chan :Account Purged"
					}
				if {$v1 == "approve"} {
					if {$v2 eq ""} { putserv "PRIVMSG $chan :Error - Please specify a user"; return }
					set path [zconf::util::getPath]
					if {![file exists "$path/userdir/$v2.db"]} { putserv "PRIVMSG $chan :Error - User does not exist"; return }
					global target
					set target "^chan"
					if {[zconf::zdb::get $v2 confirmed] == "true"} { putserv "PRIVMSG $chan :Error - User already approved"; return }
					zconf::zdb::confirm $v2
					putlog "zConf::log -  account confirmed"
					set passwd [zconf::util::randpass ${zconf::settings::passlen}]
					putlog "zConf::log - password generated: $passwd"
					putserv "PRIVMSG *controlpanel :AddUser $v2 $passwd"
					putlog "zConf::log - account created"
					putserv "NOTICE $nick :ZNC Password: $passwd"
					putserv "PRIVMSG $chan :Account '$v2' approved"
					}
				if {$v1 == "regset"} {
					if {$v2 eq ""} { putserv "PRIVMSG $chan :Error - Please specify a setting"; return }
					if {$v2 == "public"} {
						zconf::zdb::regset public
						putserv "PRIVMSG $chan :zConf Registration set to 'public' - Anyone can request a znc"
						return
					}
					if {$v2 == "admin"} {
						zconf::zdb::regset admin
						putserv "PRIVMSG $chan :zConf -- Registration set to Admin-approved"
						return
					}
					if {$v2 == "off"} {
						zconf::zdb::regset off
						putserv "PRIVMSG $chan :Registration set to Off. Until reenabled, zConf will not accept new registrations."
						return
					} else {
						putserv "PRIVMSG $chan :Error - Please specify either public, admin, or off."
						return
						}
					}
				if {$v1 == "restart"} { putserv "PRIVMSG $chan :Restarting zConf..."; restart }
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
			if {![llength [split $v1]]} { putserv "PRIVMSG $chan :zconf::help - use the 'commands' subcommand for help with commands"; return }
			putserv "PRIVMSG $chan :zconf::help - $v1"
			if {$v1 == "commands"} {
				putserv "PRIVMSG $chan :version request approve status admins access pwdgen"
				putserv "PRIVMSG $chan :use 'help \037command\037' for more info"
			}
			if {$v1 == "version"} { putserv "PRIVMSG $chan :zconf::help - Prints version information"; return }
			if {$v1 == "request"} { putserv "PRIVMSG $chan :zconf::help - Request a ZNC account"; return }
			if {$v1 == "approve"} { putserv "PRIVMSG $chan :zconf::help - Approve your account with the given code"; return }
			if {$v1 == "status"} { putserv "PRIVMSG $chan :zconf::help - Show server status, uptime, and load"; return }
			if {$v1 == "admins"} { putserv "PRIVMSG $chan :zconf::help - Shows current zConf admin listing"; return }
			if {$v1 == "access"} { putserv "PRIVMSG $chan :zconf::help - Shows access information for ZNC"; return }
			if {$v1 == "pwdgen"} { putserv "PRIVMSG $chan :zconf::help - Generates a random password for you"; return }
			}
	}
	namespace eval util {
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
			set path [zconf::util::getPath]
			set p "$path/userdir/admin/"
			set fp [open "| ls $p"]
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
