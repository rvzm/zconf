# zdb.tcl - zConf Database manager

source scripts/zconf/lol.tcl
namespace eval zconf {
	namespace eval zdb {
		package require sqlite3
		proc create {nick v1} {
			set path [zconf::util::getPath]
			set authcode [zconf::util::randPass 5]
			set db "$path/userdir/znc.db"
			if {![file exists "$db"]} { sqlite3 zdb $db -create true } else { sqlite3 zdb $db }
			if {[zdb exists {SELECT username FROM $nick}]} {
				set chan [zconf::util::getChan]
				putserv "PRIVMSG $chan :Error: You already have an account"
				return
			}
			zdb eval {TABLE CREATE $nick(username text, freeze text, auth text, confirmed text)}
			zdb eval {INSTER INTO $nick VALUES(username,'$v1')}
			zdb eval {INSTER INTO $nick VALUES(auth,'$authcode')}
			zdb eval {INSERT INTO $nick VALES(freeze,'false')}
			putlog "zDB ~ Database edit - $nick created / authcode - $authcode / username - $v1"
			zdb close
		}
		proc get {nick v1} {
			set path [zconf::util::getPath]
			set db "$path/userdir/znc.db"
			if {![file exists "$db"]} { sqlite3 zdb $db -create true } else { sqlite3 zdb $db -readonly }
			set rt [zdb eval {SELECT $v1 FROM $nick}]
			return "$rt"
			putlog "zDB ~ Info retreived - $rt"
			zdb close
		}
		proc freeze {nick} {
			set path [zconf::util::getPath]
			set db "$path/userdir/znc.db"
			if {![file exists "$db"]} { sqlite3 zdb $db -create true } else { sqlite3 zdb $db }
			zdb eval {INSERT INTO $nick VALUES(freeze,'true')}
			putlog "zDB ~ Account $nick frozen"
			zdb close
		}
		proc confirm {nick} {
			set path [zconf::util::getPath]
			set db "$path/userdir/znc.db"
			if {![file exists "$db"]} { sqlite3 zdb $db -create true } else { sqlite3 zdb $db }
			zdb eval {INSERT INTO $nick VALUES(confirmed,'true')}
			putlog "zDB ~ Account $nick frozen"
			zdb close
		}
	}
}

putlog "zConf Database Manager v0.1 loaded";
