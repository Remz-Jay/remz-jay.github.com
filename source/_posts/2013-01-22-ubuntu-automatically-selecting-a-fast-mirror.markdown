---
layout: post
title: "Ubuntu: Automatically selecting a fast mirror"
date: 2013-01-22 12:04
comments: true
categories: [Linux, Ubuntu]
---

Letting Ubuntu pick the `apt-get` mirror closest to you is pretty easy.

Just add these mirror directives to the top of `/etc/apt/sources.list` and you're good to go:

```
deb mirror://mirrors.ubuntu.com/mirrors.txt precise main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt precise-updates main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt precise-backports main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt precise-security main restricted universe multiverse
```



