---
layout: post
title: "Iptables: Creating persistent bans from Fail2Ban"
date: 2009-08-18 15:53:10 +0200
comments: true
categories: [fail2ban, firewall, iptables, linux, php]
---
On my servers I use the nifty program [Fail2Ban][1] to perform logbased automatic firewalling of 'bad' ip's. 

The idea behind this is easy: Some IP performs an action I don't approve of. This can be any number of things, e.g. requesting pages in Apache that are commonly accessed by bots and/or scanners, or trying to log in to SSH with accounts that do not exist on the system. This bad behavior gets logged, and Fail2Ban keeps tabs on those logs, and using a number of rules it determines if a host is 'bad' enough to temporarily or permanently ban all access to the server. It does so by adding a few chains to Iptables (one for each thing it checks for), and dynamically adding/removing IP's to/from these chains. 

This all works perfectly. However, there's one issue; When Iptables gets reloaded, it restores its default rules, removing the Fail2Ban chains and all the rules they contain, even if the ip's in the chain were marked as permanent.

I created a workaround for this problem, consisting of two simple steps: 

 - When a 'bad' ip gets banned, it's added to the Iptables chain, but also written to a file, containing all collected 'bad' ip's. (I use `/etc/shitlist` for this purpose). 

 - Whenever Iptables gets reloaded, I run a PHP script that checks the `/etc/shitlist` file for 'safe' and duplicate ip's, and writes all other ip's to the permanent Blocklist chain. (The checking for 'safe' ip's might be a bit unneeded, but with my Fail2Ban rules it's possible that one of my own ip's gets banned for 10 minutes if a SSH login attempt fails for 5 times. Though it's a temporary ban, the ip will still get written to the shitlist, and would end up in the permanent Blocklist). 


To make this work, I made the following changes: 

Every `jail` in Fail2Ban uses an `action.d` script to perform (un)banning. I defaulted all actions to an action script called `iptables-allports.conf`. Basically this action drops everything in Iptables if a package originates from the 'bad' IP. 

I updated the ban action such that:

```
actionban = iptables -I fail2ban-<name> 1 -s <ip> -j DROP
echo <ip> >> /etc/shitlist
```

After that I created a PHP script that updates Iptables with the ip's contained in the shitlist:


``` php shitlist.php
<?php 
/** script that loads a shitlist file into iptables */ 
//CONFIG 
$shitlists = array("/root/list.txt","/etc/shitlist");
$chain = "Blocklist";
$safelist = array("x.x.x.x", "y.y.y.y", "z.z.z.z");

echo "Reading current IPTABLES state\r\n";
$data = shell_exec('iptables -S '.$chain);
$iparr = explode(' ',$data);
$j = 0;
$ref = array();
for($i=0;$i<sizeof($iparr);$i++) {
	if(substr_count($iparr[$i],".")==3) {
 		$ref[$j] = $iparr[$i];
		 $j++;
	 }
}
sort($ref);
$total = 0;
foreach($shitlists as $shitlist) {
	echo "Reading shitlist at $shitlist\r\n";
	//READ FILE
	$fh = fopen($shitlist,'r');
	if($fh) {
		$itt = 0;
		$iparr = array();
		while(!feof($fh)) {
			$ip = trim(fgets($fh));
			if(strlen($ip)>6) {
				if(array_search($ip,$iparr)===false&&array_search($ip,$safelist)===false&&array_search($ip."/32",$ref)===false) {
					$iparr[] = $ip;
					echo "Now adding $ip to $chain\r\n";
					$ins = 18+$itt;
					shell_exec("iptables -I ".$chain." ".$ins." -s ".$ip."/32 -j DROP");
					$itt++;
				}
 			}
		}
		fclose($fh);
		echo "Finished adding $itt ip's from list $shitlist to chain $chain . Bye!\r\n";
		$total = $total + $itt;
	} else {
 		echo "Could not open shitlist file $shitlist . Skipping this list\r\n";
	}
}
echo "Finished adding $total ip's to chain $chain from ".sizeof($shitlists)." shitlists.\r\n";
?> 
```

You can run the script from the commandline (as root!) simply by stating `php shitlist.php`, or add it to the startup script of your Iptables installation. 

Hope this helps keeping your NIC's available for VALID traffic! 

### Update:

Made some changes to the script to check for already existing bans, to keep your chains clean! 

### Update 2:

Little tweak to the script so it now loads an array of lists, in case you have various sources.


[1]: http://www.fail2ban.org/wiki/index.php/Main_Page
