---
layout: post
title: "Gentoo: Updating and Cleaning"
date: 2013-01-16 23:40
comments: true
categories: [Gentoo, Linux]
---

{% img left http://www.gentoo.org/images/gblend.png 100 100 %} Keeping your Gentoo Linux server up to date isn't as straightforward as let's say an Ubuntu box, where you would just run ``` $ apt-get update && apt-get upgrade && apt-get clean``` for example.

Gentoo is far too flexible for a *one size fits all* approach. The commands outlined below come pretty close for daily use though:

{% gist 2835011 %}

<!-- more -->
We start by syncing the portage tree, required to obtain the latest packages.
After which we update the "world" group (which would entail all packages currently installed) with a couple of options:

-u : Update

-D : Deep, includes updates to prerequisites for packages registered in your world favorites

-N : NewUSE, checks for changes to your USE flags (usually registered in ```/etc/make.conf```or ```/etc/portage/package.use```)

-a : Ask, will show a dialog asking you of the packages to be merged are OK with you. Very useful when you invoke these commands manually, as I do every day. It gives you a last minute escape in case some crucial (like ```sys-fs/udev```) or large (like ```sys-devel/gcc```) package is about to be merged which you really aren't in the mood for.

-v : Verbose, gives more useful output, including the selected USE flags for packages. (Which enables you to spot obvious errors early on).

--with-bdeps=y : Includes build time dependencies, and is useful for solving some common merge errors. (This can also be done by setting ``EMERGE_DEFAULT_OPTS="--with-bdeps=y" `` in ```/etc/make.conf```)


That should suffice to update about every update-able package on your system.

**Always make sure to read *and follow* the instructions that appear after the merge!**  
This is exactly why the second line is mentioned separately and isn't concatenated after the first; It gives you opportunity to execute the required steps for crucial packages that might otherwise break your system.  

After that we proceed with some basic cleanup:

 * Remove obsolete packages with ``emerge --depclean``.
 * Check for broken dependencies/links with ```revdep-rebuild```which will automatically fix the issues.
 * Delete obsolete distfiles (downloaded source packages, required to merge the binaries) for packages that no longer exist on the system with ```eclean-dist```.


Running the sequence above on a regular schedule should ensure that you have a smooth running system!

Got improvements or comments on the procedure outlined above? I'd love to hear them in the comments below.