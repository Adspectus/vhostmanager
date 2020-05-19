#
# Regular cron jobs for the vhostmanage package
#
0 4	* * *	root	[ -x /usr/bin/vhostmanage_maintenance ] && /usr/bin/vhostmanage_maintenance
