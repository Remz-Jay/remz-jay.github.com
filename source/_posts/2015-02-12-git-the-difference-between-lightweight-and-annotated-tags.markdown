---
layout: post
title: "Git: The difference between lightweight and annotated tags"
date: 2015-02-12 14:05:50 +0100
comments: true
categories: git
---

I was reviewing some pull requests at work today. One of the PR's had an updated `composer.lock` file. We usually check if the `reference` matches the `version` for this update, to see if that commit is actually released on the module's `master` branch:

``` diff Example of an updated composer.lock
"name": "company/module_name",
- "version": "0.11.0",
+ "version": "0.12.0",
"source": {
	"type": "git",
	"url": "ssh://git@stash.company.net/packages/module_name.git",
-	"reference": "19ecfcb286052457697caad3359d7817e2dfa2f5"
+	"reference": "2c539864d72baede7f169f15eec8c3317e26c1bc"
 },
- "time": "2014-10-08 11:12:23"
+ "time": "2014-11-18 16:47:02"
```

Usually, this `reference` matches the hash of the commit we've tagged as this `version`. In this particular case however, the hash mentioned in `reference` was nowhere to be found in the commit log. So what's going on here?

<!-- more -->
To investigate, I tried checking out that particular hash:

``` bash
$ git checkout 2c539864d72baede7f169f15eec8c3317e26c1bc
Note: checking out '2c539864d72baede7f169f15eec8c3317e26c1bc'.

You are in 'detached HEAD' state. You can look around, make experimental
changes and commit them, and you can discard any commits you make in this
state without impacting any branches by performing another checkout.

If you want to create a new branch to retain commits you create, you may
do so (now or later) by using -b with the checkout command again. Example:

  git checkout -b new_branch_name

HEAD is now at 155ffc0... Merge pull request #3 in packages/module_name from feature/some-feature to master
```

That's funny.. I check out `2c53986`, but I end up with `155ffc0`.

If we check the `rev-list` for that tag, you'll notice that the latest commit is indeed `155ffc0`:

``` bash checking the rev-list for a tag
$ git rev-list 0.12.0  | head -5
155ffc0169e1c80e029de229d08767d3f7d69adc
e147d1873da0a66a816ec6578cd6ae9900c4985b
92471ae1cacf473a45a926a333591fc06750e45f
19ecfcb286052457697caad3359d7817e2dfa2f5
38df1fac8d30415fdb2666c1eaaee2d15ff0ae39
```

If we check `show-ref` however, the tag points to a different hash instead:

``` bash checking reference for a tag
$ git show-ref --tags | grep 0.12.0
2c539864d72baede7f169f15eec8c3317e26c1bc refs/tags/0.12.0
```

If we do the same for tag `0.11.0` you'll notice that they both point to the same commit however:


``` bash lightweight tags point to the same hash
$ git show-ref --tags | grep 0.11.0
19ecfcb286052457697caad3359d7817e2dfa2f5 refs/tags/0.11.0
$ git rev-list 0.11.0  | head -1
19ecfcb286052457697caad3359d7817e2dfa2f5
```


So, what's the difference then? The answer is that there are two distinct types of tags.


## Lightweight and Annotated Tags

{% pullquote %}
This is all due to the fact that there are two distinct types of tags in git:

- **Lightweight tags**: A tag that is attached to an existing commit. This merely functions as a pointer to a specific commit, and as such it 'piggybacks' on that commit's hash as identification. This type of tag does not allow you to store any information that specific to the tag.
- **Annotated tags**: A tag that has its own commit hash and is, as such, stored as a separate object in git. This tag allows you to store information that is related to this specific tag. You can add a tag message, GPG sign it, and the tagger is stored.

{"So, which one should I use? The short answer is **annotated tags**."} [Read this StackOverflow answer to see why][1], because I can't explain it any clearer than that :)
{% endpullquote %}
Creating an annotated tag is easy:

``` bash
$ git tag -s -a -m "JIRA-11: Include your tag message here" 0.12.0
```

- `-s` will GPG sign your tag. More about this further down.
- `-a` will create an annotated tag.
- `-m "<message>"` will add a tag message.
- If you need to amend / fix / replace an existing tag, you can use the `-f` parameter to overwrite the current tag.


## Why should I care?
You *should* care about the advantages of annotated tags. To elaborate, here are three viable use cases:

###Whodunnit
Take my `composer.lock` example. We write modules in separate modules, and include those modules using `composer` in actual projects. If i review a project, I only see the `composer.lock` file, but don't immediately see the code for the actual module. I need some way to make sure that the code that's being rolled out in the current project is approved and stable. This usually means that I have to dive into the module's code and review that as well. But I'm no expert on every single module my company has created, so I'm probably not the best reviewer for a (large) number of modules. How do I know that the code has been reviewed and it's all good? I check the `tag`. If it has been tagged by the module's owner I can rest assured that a proper and thorough review has been done before this release was tagged. Annotated tags make this easy:


``` bash Getting information about a tag
$ git show 0.12.0

tag 0.12.0
Tagger: Remco Overdijk <remco@maxserv.com>
Date:   Thu Feb 12 14:58:11 2015 +0100

OPS-227: Release v0.12.0, which includes fixes for OPS-224, PUP-81 and a cherry-pick of 155ffc0
-----BEGIN PGP SIGNATURE-----
Version: GnuPG/MacGPG2 v2.0.22 (Darwin)
Comment: GPGTools - https://gpgtools.org

iQEcBAABCgAGBQJU3LFzAAoJEOmkwfHWjjgAGpkIAJCwZi2gbXHFTPAbaQBvr8gi
Ds834V02vuMx+dB3rtrYZ4vp+IKxWIYH5hQmgYM7bgQu9yF/3+4xhIP/2n01Mtnu
C4dWyU5zC/6YciiheOa++4xAg+qLYihXT3uclUJwWBhYNJxV9+lzeGX9RMLAfWAM
3abcUDCrmIveF9v5SrFu8cEj5/GRGcx8xiVuFiOdvReOZKkkiFq5Jeb+cUkux44q
yK3tacSVfdPmD9st0WVlOGBB0oaoV/mNd2a/4/fjfn/IUYh+9iMJmvLNtvEmWwEC
WEj3ehXkuuab9tQ8fDs7ERlzuU1HqPw9b7tX0zfJBnAShEqkpBkCaOXJ3iBlYI0=
=dV3m
-----END PGP SIGNATURE-----

commit 155ffc0169e1c80e029de229d08767d3f7d69adc
Merge: 19ecfcb e147d18
Author: Some Developer <devs@company.net>
Date:   Tue Nov 18 17:47:02 2014 +0100

    Merge pull request #3 in packages/module_name from feature/some-feature to master
```

As you can see, `git show` has information about the tag, and specifically *who* tagged it. Further down, you see the actual commit that this tag is connected to. That commit has a different author, but the tag was done by me, so it should be all good, right? No need to delve into that code any further, so we can move on with our original PR.

In short: Annotated tags give you *separation between tagger (reviewer and/or releaser) and author/committer*.

###What is contained in this tag?
Another vital piece of information that is usually contained in the pull request and/or other review docs that may exist is the context of the change set:

- Which changes are included in this change set? 
- To which JIRA tickets are these changes related?
- Why have we decided to release these changes as a new tag?
- Are any additional actions required to make this release work? (Play-books)

As said, we usually document these changes in the PR, which gives a good overview of the entire context. But if you're on the 'receiving end' of the repository, and you don't have access to the review software for instance, that context might not be as clear. 

That's why it's a good idea to copy all (or some) details from the PR into the annotated tag message, so a permanent piece of documentation about the how/what/when and why exists in the repository. See the example above for a plausible tag message.

###Whodunnit for paranoid people
Because, let's face it, everyone should be a bit paranoid these days. How do I know that the tag *and/or* the repository haven't been tampered with? Everyone can impersonate you in git, as long as they have write access to the `origin` repository. So let's say that your private key has leaked, a hacker has configured `git config user.email` with your e-mail address, committed some malware to your repository and moved your tag to a version that includes the malware. *That's not good. That's not good at all.*

Granted, if the above scenario should happen to you, you probably have bigger issues than verifying a tag. But what if you pull in some external changes that you don't quite trust? Or what if one of your enterprise customers wants to ensure that they pull in a verified set of changes onto their platforms? 

That's why you GPG sign your tags. Remember that `-s` parameter we've added?
During creation of the tag you'll notice this:

``` bash
You need a passphrase to unlock the secret key for
user: "Remco Overdijk <remco@maxserv.com>"
2048-bit RSA key, ID D68E3800, created 2013-10-02 (main key ID D90A625D)
```

and in the `git show` example above you'll notice that a PGP signature was included. We can use this information to verify if the `tag` was intact (not tampered with), and that it was actually signed by someone we know **and trust**:

``` bash verifying a tag
$ git verify-tag 0.12.0
gpg: Signature made do 12 feb 14:58:11 2015 CET using RSA key ID D68E3800
gpg: Good signature from "Remco Overdijk <remco@maxserv.com>"
gpg:                 aka "Remco Overdijk <remco@maxserv.nl>"
gpg:                 aka "keybase.io/remz <remz@keybase.io>"
```

Yes, that tag has a good signature, and it was signed by me, whom I explicitly added to my GPG web of trust.


So, now you know how and why. Start using annotated tags!

{% blockquote %}
Certain details, messages, addresses and hashes in this article have been altered to protect company specific details.
{% endblockquote %}

[1]:http://stackoverflow.com/questions/4971746/why-should-i-care-about-lightweight-vs-annotated-tags/4971817#4971817


