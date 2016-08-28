# zconf-settings.tcl

namespace eval zconf {
	namespace eval settings {
		variable pubtrig "&";
		variable admtrig "!";
		variable zchan "#znc";
		variable url "placeholder";
		variable version "0.7.1";
		variable pass "placeholder";
		variable zncpass "placeholder";

	}
}
putlog "zConf - Settings Loaded";
