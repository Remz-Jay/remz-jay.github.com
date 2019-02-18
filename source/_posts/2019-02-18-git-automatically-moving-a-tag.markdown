---
layout: post
title: "Git: Automatically moving a tag using a custom command"
date: 2019-02-18 16:56:55 +0100
comments: true
categories: [git, bash, script]
---
Ever find yourself moving a git tag to a new commit? You'll probably know this procedure consists out of three steps;

- Removing the existing tag from your `origin`
- Manually moving the tag (using `-f` to allow moving)
- Pushing the tag back your `origin`

Since this procedure is more cumbersome that it could be, behold, a quick and easy life hack to automate this process into a single custom command.

<!-- more -->

## Before you start

- Make sure you have a `$HOME/bin` directory
- Make sure that directory is in your `PATH`

## The script

- Put this script in your `$HOME/bin` directory:

```bash $HOME/bin/git-retag
#!/bin/bash

((!$#)) && echo No tag given, command ignored! && exit 1
if git rev-parse $1 >/dev/null 2>&1; then
    git push origin :refs/tags/$1
    git tag -f $1
    git push origin $1
else
    echo Tag not found in repo, are you sure you know what you\'re doing? && exit 1
fi
```
- Make it executable by running `chmod u+x $HOME/bin/git-retag`
- Enjoy!

## Testing

```bash
git retag 0.48.0
To upstream.repo.url:test/test.git
 - [deleted]         0.48.0
Updated tag '0.48.0' (was 1276686)
Total 0 (delta 0), reused 0 (delta 0)
To upstream.repo.url:test/test.git
 * [new tag]         0.48.0 -> 0.48.0
```
