---
layout: post
title: "Bacula: Purging and deleting old volumes"
date: 2015-01-15 14:08:02 +0100
comments: true
categories: [bacula, backup, linux] 
---
I've been using bacula for a couple of months now in conjunction with puppet to
make automated backups of all servers that are managed by puppet. 
My bacula setup labels a volume for every job it runs with a unique name:

``` ini Bacula Label Format
Label Format = "${Job}.${Year}${Month:p/2/0/r}${Day:p/2/0/r}.${Hour:p/2/0/r}${Minute:p/2/0/r}"
```

These volumes are automatically purged once the retention of all files contained on the volume expires (which is
		configured per-pool). Due to the unique names however, the volumes cannot
be recycled. The result of this is that the volumes that have been marked as
purged in the catalog remain as-is on the disk. After some time this ultimately
resulted in a full disk, thus halting all backups performed on that pool. Not
good. Not good at all. 
<!-- more -->

I thought volumes would be truncated at the time they are marked as purged, but
I probably made some configuration error somewhere along the road or I don't
quite understand how the truncating process works, because all of my purged
disks are using their original disk space. 

Because I'm pressed for time and can't be bothered with old backups anyway,
				I've decided to just delete all purged volumes (which were beyond their
						retention date anyway). Perhaps the steps I took to delete these
				volumes can help others (Or others can recommend me a better way to
						deal with old volumes), so here goes:

## Pruning all clients
Before you start cleaning old volumes, it might be wise to ensure that all
volumes are pruned before cleaning, so you maximize the number of volumes you
are going to delete.

``` bash Pruning all clients
#!/bin/bash
clients=`mysql -e'select Name from Client ORDER BY Name ASC;' bacula | tail -n+2`
	
for client in `echo $clients`
do
  echo "prune files client=${client} yes" | bconsole
done
```

## Checking the number of volumes to be purged
Using `list volumes` in `bconsole` you can check the status of all volumes known to bacula.
I'm merely interested in the number of volumes that are currently marked as purged:

``` bash Listing the number of Purged Volumes
echo "list volumes" | bconsole | grep "Purged" | awk {'print $4'} | wc -l
```
This resulted in a list of *thousands* of volumes. (We're running, full, incremental and diff backups, so the numbers stack up). Time to get rid of them.

## Removing purged volumes from the catalog and deleting them

Using this script I've removed all purged volumes from the catalog, after which they were physically deleted from the disk, freeing up precious space for more recent backups.
``` bash Deleting all Purged Volumes
#!/bin/bash
for f in `echo "list volume" | bconsole | grep Purged | cut -d ' ' -f6`; do 
	echo "delete volume=$f yes" | bconsole;
	rm -rf /mnt/bacula/default/$f;
done
```
## Removing volumes that are missing from the catalog
Somehow I also ended up with some volumes on the disk that were not present in the bacula catalog at all. In my opinion these could be cleaned up as well, hence:

``` bash Deleting volumes that are not present in the catalog
#!/bin/bash

cd /mnt/bacula/default
for i in `find . -maxdepth 1 -type f -printf "%f\n"`; do
  echo "list volume=$i" | bconsole | if grep --quiet "No results to list"; then
        echo "$i is ready to be deleted"
        rm -f /mnt/bacula/default/$i
  fi
done
```

## Finishing up
To prevent full disks these tasks should be scheduled using `cron` and run daily (or at least weekly) to keep your disks and catalog lean & clean.
