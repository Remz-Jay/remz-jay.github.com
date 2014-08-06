---
layout: post
title: "Fail2Ban PhpMyAdmin script"
date: 2009-12-09 16:44:27 +0200
comments: true
categories: [fail2ban]
---
While examining my webserver statistics, I noticed that quite a lot 404's are being served on most of my domains to scan bots that are trying to find exploits in possible running PHPMyAdmin configurations.
 Though harmless if you keep a clean ship with a decently configured PHPMyAdmin and the latest updates like I do, I still decided I couldn't let this behaviour unanswered. So I took action, and wrote a small fail2ban filter that permanently drops all traffic from the IP addresses these scans originate from, like I do with every address that misbehaves in any way.

 The regex used won't capture all attempts, but with my configuration only 1 hit is enough to get you banned (the scripts these scans call are `main.php` and `config.inc.php`, which aren't to be called directly, especially not when they fail with a 404 like these), and all scanning attempts I've seen so far cycle through at least 20 different combinations.

 Well, enough talk, here is the `filter.d` file:

``` ini filter.d
 # Fail2Ban configuration file
 #
 # Author: Remco Overdijk
 #
 # $Revision: 4 $
 #

 [Definition]

 # Option:  failregex
 # Notes.:  regex to match the 404'ed PMA file in the logfile. The
 #          host must be matched by a group named 'host'. The tag '<HOST>' can
 #          be used for standard IP/hostname matching and is only an alias for
 #          (?:::f{4,6}:)?(?P<host>\S+)
 # Values:  TEXT
 #
 failregex = <HOST> -.*'GET .*(php|pma|PMA|p/m/a|db|sql|admin).*/(config/config\.inc|main)\.php.*'.*404.*

 # Option:  ignoreregex
 # Notes.:  regex to ignore. If this regex matches, the line is ignored.
 # Values:  TEXT
 #
 ignoreregex =
```

And this is of course accompanied by a bit in `jail.conf`:

``` ini jail.conf
[apache-pma]

 enabled = true
 filter = apache-pma
 action = iptables-allports[name=pma]
 mail-whois[name=pma, dest=<YOURADDRHERE>]
 logpath = /var/log/apache2/access_log
 bantime = -1
 maxretry = 1
```

Works for me, another 20 additional IPs/day onto the shitlist!

#### Update:

 It seems another variation of these scans are hitting the NIC's quite often; One for Zen Cart to be more precise.
 You can easily add support countering this scanner as well, simply by expanding the failregex with this line:

`^<HOST> -.*'GET .*(cart|boutique|catalog|butik|shop|zen|store).*/install\.txt.*'.*404.*`

 You can put multiple regexes within one failregex, just put each one on a new line.
