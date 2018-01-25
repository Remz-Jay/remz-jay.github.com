#!/sbin/runscript
# Copyright 2014 Rem.co Linux Solutions
# Distributed under the terms of the GNU General Public License v2
# $Header: $

extra_commands="syncup syncdown backup rotate emptyrestart watch"

description="Manages a Minecraft installation running under a dedicated user inside a daemonized screen session"
description_syncdown="Synchronizes the RAMdisk back to the persistant storage"
description_syncup="Synchronizes the persistant storage to the RAMdisk"
description_backup="Takes a full backup of the minecraft installation and rotates old backups"
description_rotate="Rotates old backups"
description_emptyrestart="Checks if any users are online in minecraft. If not, restarting the service"
description_watch="Checks if minecraft is still running if it resides in the 'started' state. Restarts the service if not."

depend() {
	need net localmount
	after bootmisc
	use logger
}

start() {
	ebegin "Starting Minecraft"
	if ! sudo -u ${RUNAS} screen -list | grep -q "${SCREENNAME}"; then
		launch || return 1
	else
		eerror "Minecraft screen session is already present, not launching new one."
	fi
	eend $?
}

stop() {
	ebegin "Stopping Minecraft"
	if ! sudo -u ${RUNAS} screen -list | grep -q "${SCREENNAME}"; then
		eerror "The Minecraft screen session cannot be found so we can't stop it"
	else
		sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X stuff "stop$(printf \\r)"
		sleep 5
		#Check if the screen session closed cleanly, otherwise kill it with fire.
		if sudo -u ${RUNAS} screen -list | grep -q "${SCREENNAME}"; then
			sudo -u ${RUNAS} screen -S ${SCREENNAME} -X kill
		fi
	fi
	eend $?
}

reload() {
	ebegin "Reload Minecraft"
	stop
	sleep 3
	start
	eend $?
}

launch() {
 	if ! mountpoint -q ${RAMDISK}; then
		mount ${RAMDISK}
	fi
	sup || return 1
	sudo -u ${RUNAS} screen -dmS ${SCREENNAME} bash -c "cd ${RAMDISK}; java -server -XX:+UseConcMarkSweepGC -Xms2G -Xmx4G -jar ${JARFILE} nogui"
}

sdown() {
	rsync --quiet --archive --delete --recursive --force ${RAMDISK}/ ${PERSISTDIR}
}

syncdown() {
	ebegin "Syncing RAMdisk to Persistant Storage"
	sdown || return 1
	eend $?
}

sup() {
	rsync --quiet --archive ${PERSISTDIR}/ ${RAMDISK}
}

syncup() {
	ebegin "Syncing Persistant Storage to RAMdisk"
	sup || return 1
	eend $?
}

backup() {
	ebegin "Taking a backup"
	if ! sudo -u ${RUNAS} screen -list | grep -q "${SCREENNAME}"; then
		eerror "Minecraft is not running, not taking a live backup"
	fi
	H=$(date +"%H")
	NOW=$(date +"%H:%M")
	sdown || return 1
	sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X stuff "say Hourly backup for $NOW is starting. The World is no longer saving...$(printf \\r)"
	sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X stuff "save-off$(printf \\r)"
	sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X stuff "save-all$(printf \\r)"
	sleep 5
	sudo -u ${RUNAS} /usr/bin/time -f "%e sec at %P CPU" -o /tmp/mctime sh -c "sync; sleep 5; sudo -u ${RUNAS} nice tar czf ${BACKUPDIR}/${PREFIX}$(date +"%d-%m-%Y-%H").tar.gz -C ${RAMDISK} ."
	sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X stuff "save-on$(printf \\r)"
	sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X stuff "say Hourly backup for $NOW is complete and ran for $(cat /tmp/mctime). The World is saving once more.$(printf \\r)"
	rm /tmp/mctime
	if (( 19 <= 10#$H && 10#$H < 23 )); then
		rot || return 1
	fi
	eend $?
}

rot() {
	[ -d ${BACKUPDIR}/daily-saves ] || mkdir -p ${BACKUPDIR}/daily-saves
	find ${BACKUPDIR} -maxdepth 1 -type f -name "${PREFIX}$(date -d "yesterday 20:00 " '+%d-%m-%Y-%H').tar.gz" \
		-exec cp {} ${BACKUPDIR}/daily-saves/daily_$(date -d "yesterday 20:00 " '+%d-%m-%Y').tar.gz \;
	if [ -f ${BACKUPDIR}/daily-saves/daily_$(date -d "yesterday 20:00 " '+%d-%m-%Y').tar.gz ]; then
		find ${BACKUPDIR} -maxdepth 1 -type f -name "${PREFIX}$(date -d "yesterday 20:00 " '+%d-%m-%Y')-*.tar.gz" -exec rm {} \;
	else 
		ewarn "Could not locate yesterday's daily save. Not rotating yesterday's hourly saves."
	fi
}

rotate() {
	ebegin "Starting daily backup rotation"
	rot || return 1
	eend $?
}

emptyrestart() {
	sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X hardcopy /tmp/${SCREENNAME}.dump.1
	sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X stuff "list$(printf \\r)"
	# We need to wait for the command to complete, or the diff will we unreliable
	sleep 1
	sudo -u ${RUNAS} screen -S ${SCREENNAME} -p 0 -X hardcopy /tmp/${SCREENNAME}.dump.2
	NUMP=$(diff -u /tmp/${SCREENNAME}.dump.{1,2} | grep -E "^\+" | grep -Po '\d+/\d+' | cut -d'/' -f1)
	rm /tmp/${SCREENNAME}.dump.{1,2}
	if [ ${NUMP} -eq 0 ]; then
		reload || return 1
	else
		ewarn "There are ${NUMP} player(s) online. Not restarting."
	fi
}
watch() {
	if [ $(rc-service minecraft status | grep -i "started" | wc -l) -eq 1 ]; then
		einfo "MC should be running"
		if ! sudo -u ${RUNAS} screen -list | grep -q "${SCREENNAME}"; then
                	ewarn "But it is not! Restarting service"
			sdown || return 1
			launch || return 1
		else
			einfo "And it is. Good."
		fi

	else
		einfo "MC is in stopped state. Not doing anything."
	fi
}
