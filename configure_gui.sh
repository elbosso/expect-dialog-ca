#!/bin/sh
command -v xdialog
xdialogpresent=$?
if [ "$xdialogpresent" = 0 ]; then
	command -v xset
	xsetpresent=$?
	if [ "$xsetpresent" = 0 ]; then
		xset -b
		xpresent=$?
		if [ "$xpresent" = 0 ]; then
			dialog_exe=xdialog
		fi
	fi
fi

