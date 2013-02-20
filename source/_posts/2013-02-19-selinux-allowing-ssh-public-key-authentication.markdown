---
layout: post
title: "SELinux: Allowing SSH public key authentication"
date: 2013-02-19 17:03
comments: true
categories: [SELinux, SSH, CentOS, Linux]
---

### The issue
I experienced a seemingly weird issue with a freshly installed CentOS server today.

SSH Public key authentication was correctly set up; The `sshd_config` was properly configured and a `~/.ssh/authorized_keys` was present with the correct rights and verified correct contents (as the file was yanked from another, working, server with `scp`).

All attempts to connect to the machine using key authentication silently failed however.
<!-- more -->  
After debugging the usual `sshd` stuff i noticed the following entries in `/var/log/audit/audit.log`:


	type=USER_AUTH msg=audit(1361289386.691:2344): user pid=22997 uid=0 auid=0 ses=99 subj=unconfined_u:system_r:sshd_t:s0-s0:c0.c1023 msg='op=pubkey acct="root" exe="/usr/sbin/sshd" hostname=? addr=81.81.21.231 terminal=ssh res=failed'
	type=USER_AUTH msg=audit(1361289386.700:2347): user pid=22997 uid=0 auid=0 ses=99 subj=unconfined_u:system_r:sshd_t:s0-s0:c0.c1023 msg='op=pubkey acct="root" exe="/usr/sbin/sshd" hostname=? addr=81.81.21.231 terminal=ssh res=failed'

Turns out that SELinux was interfering with the key authentication because there was no security context for the newly created `~/.ssh` directory. 	

### The solution
The fix is pretty easy:

	$ restorecon -R -v /root/.ssh

After which key authentication started working and the messages in `audit.log` changed to:

	type=USER_AUTH msg=audit(1361289395.365:2351): user pid=22997 uid=0 auid=0 ses=99 subj=unconfined_u:system_r:sshd_t:s0-s0:c0.c1023 msg='op=success acct="root" exe="/usr/sbin/sshd" hostname=? addr=81.81.21.231 terminal=ssh res=success'
	type=USER_AUTH msg=audit(1361289715.705:2378): user pid=23033 uid=0 auid=0 ses=99 subj=unconfined_u:system_r:sshd_t:s0-s0:c0.c1023 msg='op=pubkey_auth rport=41104 acct="root" exe="/usr/sbin/sshd" hostname=? addr=81.81.21.231 terminal=? res=success'
	type=USER_AUTH msg=audit(1361289715.705:2379): user pid=23033 uid=0 auid=0 ses=99 subj=unconfined_u:system_r:sshd_t:s0-s0:c0.c1023 msg='op=key algo=ssh-rsa size=1023 fp=a4:5c:4d:16:61:8c:af:7f:ea:c7:95:ec:15:a9:20:66 rport=41104 acct="root" exe="/usr/sbin/sshd" hostname=? addr=81.81.21.231 terminal=? res=success'
	type=USER_AUTH msg=audit(1361289715.714:2382): user pid=23033 uid=0 auid=0 ses=99 subj=unconfined_u:system_r:sshd_t:s0-s0:c0.c1023 msg='op=success acct="root" exe="/usr/sbin/sshd" hostname=? addr=81.81.21.231 terminal=ssh res=success'
	
Win!
	
> No actual IP addresses or fingerprints were harmed during the creation of this article.