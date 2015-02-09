---
layout: post
title: "Bacula: Cancelling all jobs that are currently writing"
date: 2015-02-09 14:08:07 +0100
comments: true
categories: [backup, bacula, linux, oneliner]
---

*Just a quick post with the oneliner of the day.* 

**Scenario**: after a bacula director restart a couple of jobs were stuck on the FD with message:

``` bash Bacula File Director Error
Running Jobs:
Writing: Incremental Backup job node.cluster.company.com JobId=8702 Volume=""
    pool="bacula.director.company.com:pool:default.incremental" device="DefaultFileStorage" (/mnt/bacula/default)
    spooling=0 despooling=0 despool_wait=0
    Files=0 Bytes=0 AveBytes/sec=0 LastBytes/sec=0
FDSocket closed
```

<!-- more -->
    
There were a couple of these jobs that were stuck, preventing all other jobs from running, because those were waiting for a free slot on the FD.

**Solution?** Well, I *could* have resumed or fixed those jobs, but I'm in a hurry, so I just cancelled them so the rest of the schedule could be processed. And I'm lazy too, so I just cancelled all currently writing jobs in one go:

``` bash Bacula Oneliner: Cancel all currently writing jobs
for j in `echo "s storage" | bconsole | grep -i writing | awk '{print $6}'`; do echo "cancel $j" | bconsole; done
```

After that, the schedule started processing right away. Next issue.
