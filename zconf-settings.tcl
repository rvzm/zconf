# zconf-settings.tcl

namespace eval zconf {
	namespace eval settings {
		# SETTINGS
		#  pubtrig - public trigger
		#  admtrig - admin trigger
		#  zchan   - channel for zconf to reside
		#  url     - web access to your znc
		#  weblink - url clone, added for vanity :-P
		#  irclink - irc access to your znc
		#  version - please dont change this :(
		#  pass    - nickserv pass
		#  zncpass - password for znc
		#  passlen - password length for generated passwords
		#  path    - where do you want the userdir to reside?
		#            you must have access to this directory.
		variable pubtrig "-";
		variable zchan "#znc";
		variable url "placeholder";
		variable weblink $url;
		variable irclink "placeholder";
		variable version "0.7.7";
		variable pass "placeholder";
		variable zncpass "placeholder";
		variable passlen "23";
		variable path "/home/user/zconf";
		variable force "false";
	}
}
putlog "zConf - Settings Loaded";
