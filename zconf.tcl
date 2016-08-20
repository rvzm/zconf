# zconf.tcl - v0.4
# ZNC user management system
# --------------------------
# REQUIREMENTS:
# - eggdrop 1.8
# - ZNC admin account
if {[catch {source scripts/zconf-settings.tcl} err]} {
	putlog "Error: Could not load 'scripts/zconf-settings.tcl' file.";
}
putlog "zConf loaded";

namespace eval zconf {
	namespace eval bind {
		bind pub - ${zconf::settings::pubtrig}request zconf::proc::request
		bind pub - ${zconf::settings::pubtrig}approve zconf::proc::approve
		bind pub - ${zconf::settings::pubtrig}zversion zconf::proc::version
		bind pub - ${zconf::settings::pubtrig}info zconf::proc::info
		bind pub - ${zconf::settings::pubtrig}status zconf::proc::status
		bind pub o ${zconf::settings::pubtrig}userban zconf::proc::userban
		bind pub o ${zconf::settings::pubtrig}banuser zconf::proc::userban
		bind msg - Error: zconf::proc::zncresponce:error
		bind msg - User zconf::proc::zncresponce:good
		bind dcc m znc zconf::proc::znc
		bind dcc m nsauth zconf::proc::nsauth
	}
	namespace eval proc {
		proc request {nick uhost hand chan text} {
			if {[lindex [split $text] 0] != ""} { putserv "PRIVMSG $chan :Error - This command takes no arguments."; return }
			set udb "userdir/$nick"
			set bdb "userdir/$nick.ban"
			if {[file exists $udb]} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
			if {[file exists $bdb]} { putserv "PRIVMSG $chan :Error - You are banned: [zconf::util::read_db $bdb]"; return }
			set authnick "userdir/auth.$nick"
			zconf::util::write_db $authnick [zconf::util::randpass 5]
			putserv "NOTICE $nick :Your approval code is [zconf::util::read_db $authnick]"
		}
		proc approve {nick uhost hand chan text} {
			set v1 [lindex [split $text] 0]
			set udb "userdir/$nick"
			if {![llength [split $v1]]} { putserv "PRIVMSG $chan Error - Please include your auth code"; return }
			if {[file exists $udb]} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
			set authnick "userdir/auth.$nick"
			set propcode [zconf::util::read_db $authnick]
			if {![string match $v1 $propcode]} { putserv "PRIVMSG $chan :Error - Inavlid auth code"; return }
			if {[string match $v1 $propcode]} {
				zconf::util::write_db $udb [zconf::util::randpass 15]
				putlog "zConf: DB set | [zconf::util::read_db $udb]"
				putserv "PRIVMSG $chan :Your ZNC password will be /notice'd to you."
				set passwd [zconf::util::read_db $udb]
				putserv "PRIVMSG *controlpanel :AddUser $nick $passwd"
				putserv "NOTICE $nick :$passwd"
			}
		}
		proc version {nick uhost hand chan text} {
			putserv "PRIVMSG $chan :zconf.tcl - zConf v[getVersion] ZNC Account request system"
		}
		proc info {nick uhost hand chan text} {
			putserv "PRIVMSG $chan :zConf is currently running."
			putserv "PRIVMSG $chan :Access zConf ZNC at [getURL]"
			putserv "PRIVMSG $chan :Your username is your nickname."
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
		proc userban {nick uhost hand chan arg} {
			set txt [split $arg]
			set v1 [string tolower [lindex $txt 0]]
			set msg [join [lrange $txt 1 end]]
			if {![llength [split $v1]]} { putserv "PRIVMSG $chan :Please specify a username and a reason"; return }
			if {![llength [split $msg]]} { putserv "PRIVMSG $chan :Please specify a username and a reason"; return }
			if {![file exists $v1]} { putserv "PRIVMSG $chan :Error - User does not exist"; return }
			if {[lindex [split [zconf::util::read_db $udb]] 0] == "Banned"} { putserv "PRIVMSG $chan :Error - User already banned"; return }
			set udb "userdir/$v1.ban"
			zconf::util::write_db $udb "Banned for $msg"
			putserv "PRIVMSG $chan :Banning user $v1 for $msg"
			putserv "PRIVMSG *controlpanel :DelUser $v1"
		}
		proc znc {hand idx text} {
			putserv "PASS :zconf/rueo:[zncPass]"
		}
		proc nsauth {hand idx text} {
			putserv "PRIVMSG NickServ :IDENTIFY [getPass]"
		}
		proc zncresponce:error {nick uhost hand arg} {
			#if {$nick != "*controlpanel"} { return }
			global zconf::settings::zchan
			set txt [split $arg]
			set msg [lrange $txt 0 end]
			putserv "PRIVMSG $zconf::settings::zchan :$msg"
		}
		proc zncresponce:good {nick uhost hand arg} {
			set txt [split $arg]
			set msg [lrange $txt 0 end]
			putserv "PRIVMSG [getChan] :$msg"
		}
		proc getPass {} {
			global zconf::settings::pass
			return $zconf::settings:pass
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
			return $zonf::settings::version
		}
	}
	namespace eval util {
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
	}
}
