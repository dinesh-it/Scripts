#!/bin/sh

#
# bat_stat.sh
#
# Developed by Dinesh D <dinesh@exceleron.com>
#
# Changelog:
# 2015-05-26 - created
#

stat=$((100*$(sed -n "s/remaining capacity: *\(.*\) m[AW]h/\1/p" /proc/acpi/battery/BAT0/state)/$(sed -n "s/last full capacity: *\(.*\) m[AW]h/\1/p" /proc/acpi/battery/BAT0/info)));
charge=$(sed -n "s/charging state: *\(.*\) /\1/p" /proc/acpi/battery/BAT0/state);

export DISPLAY=:0;
if [ $stat -lt 10 ] && [ $charge != 'charging' ]
then
	notify-send -u "critical" "Battery Low ! $stat%" "Will hibernate soon.";
	espeak "Battery $stat %";
elif [ $stat -lt 20 ] && [ $charge != 'charging' ]
then
	notify-send -u "normal" "Battery Low!" "Battery remaining $stat%";
	espeak "Battery $stat %";
elif [ $stat -gt 100 ] && [ $charge != 'discharging' ]
then
	notify-send -u "low" "Battery Full!" "You can unplug the charger to increase battery life";
fi
