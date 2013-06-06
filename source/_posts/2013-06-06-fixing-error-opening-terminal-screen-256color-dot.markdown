---
layout: post
title: "Fixing 'Error opening terminal: screen-256color.'"
date: 2013-06-06
comments: true
categories: [Linux, tmux, screen]
---

If you're using `tmux ` or `screen` as a wrapper for your terminal sessions (such as when using the [Text Triumvirate][1]), chances are that you are presented with the following error when you invoke a command that uses 256 color mode (such as `multitail` or `htop`):

	Error opening terminal: screen-256color.
	
I don't know if this is the recommended solution, but it's a pretty quick fix and seems to work on multiple distributions:

```
cd /usr/share/terminfo/
cp x/xterm-256color s/screen-256color
```

[1]:http://www.drbunsen.org/the-text-triumvirate/