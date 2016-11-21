# zconf-settings.tcl

namespace eval zconf {
	namespace eval settings {
		variable pubtrig "-";
		variable admtrig "!";
		variable zchan "#znc";
		variable url "placeholder";
		variable version "0.7.2";
		variable pass "placeholder";
		variable zncpass "placeholder";
		variable path "~/zconf";

	}
}
putlog "zConf - Settings Loaded";
