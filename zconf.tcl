# zconf.tcl - v0.1
# ZNC account request system
# --------------------------
# REQUIREMENTS:
# - eggdrop 1.8
# - ZNC admin account

namespace eval zconf {
	namespace eval settings {
		variable zstat "*status";
		variable pubtrig "!";
		variable zchan "#znc";
	}
	namespace eval bind {
		bind pub - ${zconf::settings::pubtrig}request zconf::proc::request
		bind pub - ${zconf::settings::pubtrig}zversion zconf::proc::version
		bind notc - *controlpanel!znc@znc.in zconf::proc::zncresponce
		bind dcc m znc zconf::proc::znc
		bind dcc m nsauth zconf::proc::nsauth
	}
	namespace eval proc {
		proc request {nick uhost hand chan text} {
			if {[lindex [split $text] 0] != ""} { putserv "PRIVMSG $chan Error - This command takes no arguments."; return }
			#if {!$zemail} { putserv "PRIVMSG $chan :Error - please include your email."; return }
			if {[file exists $nick]} { putserv "PRIVMSG $chan :Error - You already have an account"; return }
			zconf::util::write_db $nick [zconf::util::randpass 15]
			putlog "zConf: DB set | [zconf::util::read_db $nick]"
			putserv "PRIVMSG $chan :Your ZNC password will be /notice'd to you."
			set passwd [zconf::util::read_db $nick]
			putserv "PRIVMSG *controlpanel :AddUser $nick $passwd"
			putserv "NOTICE $nick :$passwd"
		}
		proc version {nick uhost hand chan text} {
			putserv "PRIVMSG $chan :zconf.tcl - zConf v0.1 ZNC Account request system"
		}
		proc znc {hand idx text} {
			putserv "PASS :zconf/rueo:BarBQBaby"
		}
		proc nsauth {hand idx text} {
			putserv "PRIVMSG NickServ :IDENTIFY BarBQBaby"
		}
		proc zncresponce {nick uhost hand text dest} {
			global botnick
			if {$dest == ""} {set dest $botnick}
			set txt [split $arg]
			set msg [lrange $txt 1 end]
			putserv "PRIVMSG ${zconf::settings:zchan} :$msg"
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
