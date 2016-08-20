# zconf.tcl - v0.2
# ZNC account request system
# --------------------------
# REQUIREMENTS:
# - eggdrop 1.8
# - ZNC admin account

namespace eval zconf {
	namespace eval settings {
		variable pubtrig "!";
	}
	namespace eval bind {
		bind pub - ${zconf::settings::pubtrig}request zconf::proc::request
		bind pub - ${zconf::settings::pubtrig}zversion zconf::proc::version
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
			#if {[file exists $udb]} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
			if {[lindex [split [zconf::util::read_db $udb]] 0] == "Banned"} { putserv "PRIVMSG $chan :Error - You are [zconf::util::read_db $udb]"; return }
			zconf::util::write_db $udb [zconf::util::randpass 15]
			putlog "zConf: DB set | [zconf::util::read_db $udb]"
			putserv "PRIVMSG $chan :Your ZNC password will be /notice'd to you."
			set passwd [zconf::util::read_db $udb]
			putserv "PRIVMSG *controlpanel :AddUser $nick $passwd"
			putserv "NOTICE $nick :$passwd"
		}
		proc version {nick uhost hand chan text} {
			putserv "PRIVMSG $chan :zconf.tcl - zConf v0.2 ZNC Account request system"
		}
		proc userban {nick uhost hand chan arg} {
			set txt [split $arg]
			set v1 [string tolower [lindex $txt 0]]
			set msg [join [lrange $txt 1 end]]
			if {![llength [split $v1]]} { putserv "PRIVMSG $chan :Please specify a username and a reason"; return }
			if {![llength [split $msg]]} { putserv "PRIVMSG $chan :Please specify a username and a reason"; return }
			if {![file exists $v1]} { putserv "PRIVMSG $chan :Error - User does not exist"; return }
			if {[lindex [split [zconf::util::read_db $udb]] 0] == "Banned"} { putserv "PRIVMSG $chan :Error - User already banned"; return }
			set udb "userdir/$v1"
			zconf::util::write_db $udb "Banned for $msg"
			putserv "PRIVMSG $chan :Banning user $v1 for $msg"
			putserv "PRIVMSG *controlpanel :DelUser $v1"
		}
		proc znc {hand idx text} {
			putserv "PASS :zconf/rue:psst"
		}
		proc nsauth {hand idx text} {
			putserv "PRIVMSG NickServ :IDENTIFY psst"
		}
		proc zncresponce:error {nick uhost hand arg} {
			#if {$nick != "*controlpanel"} { return }
			set txt [split $arg]
			set msg [lrange $txt 0 end]
			putserv "PRIVMSG #znc :$msg"
		}
		proc zncresponce:good {nick uhost hand arg} {
			set txt [split $arg]
			set msg [lrange $txt 0 end]
			putserv "PRIVMSG #znc :$msg"
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
putlog "zConf v0.1 loaded"
