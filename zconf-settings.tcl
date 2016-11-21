# zconf-settings.tcl

namespace eval zconf {
	namespace eval settings {
		# SETTINGS
		#  pubtrig - public trigger
		#  zchan   - channel for zconf to reside
		#  url     - web access to your znc
		#  version - please dont change this :(
		#  pass    - nickserv pass
		#  zncpass - password for znc
		#  path    - where do you want the userdir to reside?
		#            you must have access to this directory.
		variable pubtrig "-";
		variable zchan "#znc";
		variable url "placeholder";
		variable version "0.7.3";
		variable pass "placeholder";
		variable zncpass "placeholder";
		variable path "/home/user/zconf";

	}
}
putlog "zConf - Settings Loaded";
