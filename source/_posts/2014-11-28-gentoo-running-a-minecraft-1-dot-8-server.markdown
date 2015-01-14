---
layout: post
title: "Gentoo: Running a Minecraft 1.8 server"
date: 2014-11-28 13:36:57 +0100
comments: true
categories: [gentoo, linux, minecraft]
---
Running a dedicated Minecraft server can be a challenging job. You have to find a balance between performance and usability using "server software" that doesn't seem to be designed to provide for long running, resilient services. 

Being a first-time Minecraft server operator I had to tackle various challenges in order to come up with a way to provide a stable and reliable service to my players. The following article is a recollection of the things I implemented and scripts I wrote in order to run a Minecraft 1.8 server. The scripts mentioned are specific to Gentoo Linux, but could also be used on most other Linux flavours, albeit with some modifications to match that platform's `init.d` scripts.
<!-- more --> 
## Preparations
### Screen
In the scripts we're going to use we use `screen` as the means to deamonize the Minecraft process. I've given this a lot of thought, because using `screen` as a deamonizer feels very wrong  to me when there are dedicated tools (such as the `start-stop-daemon`) for that particular job. Furthermore, I'm more of a `tmux` guy myself when it comes to terminal multiplexing. 

However, after searching the internet, `screen` seems to be the most popular way of daemonizing Minecraft by far. I don't dare to speculate on wether this is caused by a lack of knowledge in the Minecraft server scene or based on a sound choice.

I have my own reasons for using `screen ` instead of `start-stop-deamon` or `tmux`:
-  `screen` (and/or `tmux`) allows me to interact with the game's console. If I use `start-stop-daemon` instead, the process will be truly deamonized, and there is no way to bring it to the foreground anymore to allow for interaction. Why do we *need* console interaction you might ask? Because we do backups for example. In order to have reliable backups, we have to tell the Minecraft server to flush any changes to the disk and stop saving while the backup is running. This is all done using console commands.
- `screen` has an awesome command, `stuff`, that allows us to send commands to a detached (deamonized)  instance. This provides us with the possibility of interacting with a running instance using scripts/services *outside* of that screen instance.

So, before we continue, make sure `screen` is installed on your box:


	# emerge -av app-misc/screen
	
### Java SE 8
My first attempts on running Minecraft 1.8 used the JDK that was present on my box at that time, being `IcedTea JDK 6.1.13.3 [icedtea-bin-6]`. You *can* actually use that JDK (or any other Java SE 6 JDK/JRE for that matter), but my installation was haunted by substantial, noticeable lag while the server process was using 100% CPU non-stop (on one core, the  main Minecraft server process being single-threaded) and the console and logs were spammed with these warnings:

	[23:52:10] [Server thread/WARN]: Can't keep up! Did the system time change, or is the server overloaded? Running 19381ms behind, skipping 387 tick(s)
	
Despite all optimisations that you will read about in this article that were already in effect at that time, the lag remained, and would at times get so bad that Minecraft's  internal watchdog would mark the server as crashed:

	[21:21:15] [Server Watchdog/FATAL]: A single server tick took 60.00 seconds (should be max 0.05)
	[21:21:15] [Server Watchdog/FATAL]: Considering it to be crashed, server will forcibly shutdown.
	[21:21:15] [Server Watchdog/ERROR]: This crash report has been saved to: /mnt/ramdisk/./crash-reports/crash-2014-11-27_21.21.15-server.txt
	[21:21:15] [Server Shutdown Thread/INFO]: Stopping server

After some research on the internet some posts mentioned that upgrading to Java 8 could make all the difference, so I did. And it worked! While CPU usage is still reasonably high (around 70~80% at most times), the lag and warnings are gone, and subsequently, so are the crashes. So, I'll advise to use the same JDK as I did in this article. To install:

	# emerge -av dev-java/oracle-jdk-bin
	
**Read** the error you receive from running that command, resolve the fetch restriction by following the instructions in that error message and continue installing. Afterwards:

	# java-config --list-available-vms
	The following VMs are available for generation-2:
	1)      IcedTea JDK 6.1.13.3 [icedtea-bin-6]
	*)      Oracle JDK 1.8.0.25 [oracle-jdk-bin-1.8] 
	
	# java-config --set-system-vm 2
	Now using oracle-jdk-bin-1.8 as your generation-2 system JVM
	
The command above marks the newly installed JDK as your system JVM. This might not be a possibility for you if you have other software on your system that is incompatible with Java 8 (or the Oracle JDK). In that case, you can set the installed JDK as the User VM for the user you are using to run Minecraft. To do so:

	# su <minecraftuser>
	$ java-config --set-user-vm 2
	Now using oracle-jdk-bin-1.8 as your user JVM
	
### RAMDisk
Being haunted by performance issues, I've read quite a lot on Minecraft server performance and optimisation. There is one article that stands out from the crowd and is a *must* read for everyone running Minecraft servers. I encourage you to go and read [sk89q's Improving your Minecraft server’s performance][1] first before continuing this article.

Among other minor optimisations, such as the Java flags that are used in my setup, one of the biggest influences is the use of a RAMDisk to host your Minecraft setup on. This eliminates any delays caused by `iowait` due to slow disks and speeds up various tasks, such as loading the map. I use a Dell PowerEdge 1950 III Blade server as the hardware platform for my Minecraft server, and although beefy as it may be for this purpose, it is not equipped with SSD's which is a potential cause for performance degradation. The installation/use of a RAMDisk is quite easy, but there are some drawbacks you have to keep in mind, such as that RAMDisks are not permanent storage. In case you suffer a power outage or kernel panic, the data on your RAMDisk is gone. To counter this issue, you'll have to implement some way to synchronise the RAMDisk from/to persistant storage. 

The `init.d` script we'll later discuss takes care of all this hassle, but in order for it to work, we first have to create the RAMDisk.

Edit your `/etc/fstab` and add a RAMDisk at a mountpoint of your choise:

	# vim /etc/fstab
	tmpfs                   /mnt/ramdisk    tmpfs           rw,nodev,nosuid,size=2G,uid=1000,gid=1000,mode=1700     0 0
 

Adjust the `size=` parameter to match the amount of spare (unused) RAM you have available and the size of your actual Minecraft installation. (My installation is only 300MB actually, but I have 36GB RAM in this machine which is mostly vacant so I picked a comfortably large disk size). Adjust the `uid=` and `gid=` parameters to the id's of the dedicated user you are using to run your Minecraft server with. (Never run trivial services such as this as `root`!).

Next, create the mountpoint:

	# mkdir /mnt/ramdisk

And try to mount the RAMDisk and see if it works:

	# mount /mnt/ramdisk
	# df -h
	Filesystem      Size  Used Avail Use% Mounted on
	/dev/sda3        63G   48G   13G  80% /
	udev             10M  4.0K   10M   1% /dev
	tmpfs           7.9G  628K  7.9G   1% /run
	shm             7.9G     0  7.9G   0% /dev/shm
	cgroup_root      10M     0   10M   0% /sys/fs/cgroup
	tmpfs           7.9G   72K  7.9G   1% /tmp
	/dev/sdb1       200G  192G  8.2G  96% /mnt/backups
	tmpfs           2.0G  297M  1.8G  15% /mnt/ramdisk 

### Install Minecraft as you normally would
If you haven't done so already, install a Minecraft like you normally would. For me, that is a directory `/home/remco/minecraft`  which contains the server `.jar`, the world and all settings.

## The Scripts
The `init.d` script is what makes this setup tick. It does all the heavy lifting. The location for this script is `/etc/init.d/minecraft`
{% include_code minecraft-init.d.sh %}

The `init.d` script loads settings from a `conf.d` script. The location for
this script is `/etc/conf.d/minecraft`
{% include_code minecraft-conf.d.sh %}

## Finishing up
- Install cronjobs as `root`:

```
# crontab -e
```
- Add these lines:
```
0 * * * *       /etc/init.d/minecraft backup 1> /dev/null
* * * * *       /sbin/rc-service minecraft watch 1> /dev/null
```

- Set service to start automatically:

```
rc-update add minecraft default
```

[1]: http://www.sk89q.com/2013/03/improving-your-minecraft-servers-performance/
