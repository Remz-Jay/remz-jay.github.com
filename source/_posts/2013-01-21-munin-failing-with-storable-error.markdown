---
layout: post
title: "Munin: failing with Storable error"
date: 2013-01-21 17:29
comments: true
categories: [Linux, Munin]
---

I suffered from a Munin version 2.0.10 installation that refused to update the majority of the graphs. Only the first two of a long list were being updated, the rest all 'hung' at the same moment.

After a little investigating, the problem surfaced:

``` bash
$ su - munin --shell=/bin/bash munin-cron
File is not a perl storable at blib/lib/Storable.pm (autosplit into blib/lib/auto/Storable/fd_retrieve.al) line 398, at /usr/lib64/perl5/vendor_perl/5.12.4/Munin/Master/Utils.pm line 362
File is not a perl storable at blib/lib/Storable.pm (autosplit into blib/lib/auto/Storable/fd_retrieve.al) line 398, at /usr/lib64/perl5/vendor_perl/5.12.4/Munin/Master/Utils.pm line 362
```
<!-- more -->
I started out by fixing all items the `munin-check` script suggested, which is always a good starting point.
Execute the script in a similar fashion as you would do with `munin-cron`:

``` bash
$ su - munin --shell=/bin/bash munin-check
```
Correct all reported errors and check your cron again.

In this particular case this didn't solve the issue however. There appeared to be some `.storable` files in the munin directory, which sounded like viable suspects according to the error messages:

``` bash
$ find /var/lib/munin/ -type f | grep storable
/var/lib/munin/datafile.storable
/var/lib/munin/htmlconf.storable
/var/lib/munin/limits.storable
/var/lib/munin/state-server-server.storable
```

Turns out one of these was the culprit, as moving/deleting them fixed the issue; cron has resumed normal operation.
``` bash
$ cd /var/lib/munin/ && mv *.storable ~
$ su - munin --shell=/bin/bash munin-cron
$
```

Best part of it is that the data collection doesn't seem to have been interrupted in the meantime; All graphs are up2date and have a complete history. Problem solved!