# zdb.tcl - zConf Database manager

namespace eval zconf {
	namespace eval zdb {
		package require sqlite3
		proc create {nick uname} {
			set path [zconf::util::getPath]
			set authcode [zconf::util::randpass 5]
			set db "$path/userdir/$nick.db"
			if {![file exists "$db"]} { sqlite3 zdb $db -create true } else { sqlite3 zdb $db -readonly false }
			zdb eval BEGIN
			zdb eval {CREATE TABLE zncdata(username text, auth text, confirmed text, freeze text)}
			zdb eval {INSERT INTO zncdata VALUES($uname,$authcode,'false','false')}
			zdb eval COMMIT
			putlog "zDB ~ Account Created - $nick created / authcode - $authcode / username - $uname"
			zdb close
		}
		proc get {nick v1} {
			set path [zconf::util::getPath]
			set db "$path/userdir/$nick.db"
			if {![file exists "$db"]} { sqlite3 zdb $db -create true } else { sqlite3 zdb $db -readonly true }
			if {$v1 == "uname"} { set chk 0 }
			if {$v1 == "auth"} { set chk 1 }
			if {$v1 == "confirmed"} { set chk 2 }
			if {$v1 == "freeze"} { set chk 3 }
			if {$v1 == ""} { return "Error - No variable asked for" }
			putlog "zDB ~ checking for $v1 (section: $chk)"
			set rt [zdb eval {SELECT * FROM zncdata ORDER BY $v1}]
			set zrt [lindex $rt $chk]
			putlog "zDB ~ Info retreived - $zrt"
			return "$zrt"
			zdb close
		}
		proc freeze {nick} {
			set path [zconf::util::getPath]
			set db "$path/userdir/$nick.db"
			if {![file exists "$db"]}  { putserv "PRIVMSG [zconf::util::getChan] :Error: $nick account doesnt exist"; halt }
			putlog "freezing $nick @ $db"
			sqlite3 zdb $db -readonly false
			zdb eval BEGIN
			zdb eval {UPDATE zncdata SET freeze = "true"}
			zdb eval COMMIT
			putlog "zDB ~ Account $nick frozen"
			zdb close
		}
		proc unfreeze {nick} {
			set path [zconf::util::getPath]
                        set db "$path/userdir/$nick.db"
			if {![file exists "$db"]}  { putserv "PRIVMSG [zconf::util::getChan] :Error: $nick account doesnt exist"; halt }
			sqlite3 zdb $db -readonly false
			zdb eval BEGIN
			zdb eval {UPDATE zncdata SET freeze = "false"}
			zdb eval COMMIT
			putlog "zDB ~ Account $nick unfrozen"
			zdb close
		}
		proc confirm {nick} {
			set path [zconf::util::getPath]
                        set db "$path/userdir/$nick.db"
			if {![file exists "$db"]} { sqlite3 zdb $db -create true } else { sqlite3 zdb $db -readonly false }
			zdb eval BEGIN
			zdb eval {UPDATE zncdata SET confirmed = "true"}
			zdb eval COMMIT
			putlog "zDB ~ Account $nick frozen"
			zdb close
		}
	}
}

putlog "zConf Database Manager v0.1 loaded";
