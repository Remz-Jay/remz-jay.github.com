---
layout: post
title: "Git: Moving a repository to a new server"
date: 2014-06-10 16:59:56 +0200
comments: true
categories: [Git]
---

The quick, easy and complete way:

1. Clone the repo you want to move or skip this step if you already have one set up:

		git clone git@oldreposerver:repo/name <insert dir>
		cd <insert dir>

2. Make sure your repo has all the latest news from its current `origin`:

		git fetch --all

3. Add the new `origin` as a temporary remote whilst keeping the old one for now:

		git remote add newrepo ssh://git@newreposerver:newrepo/newname

4. Push all `refs` from `origin` to their equivalent counterpart on `newrepo`:

		git push newrepo '+refs/remotes/origin/*:refs/heads/*'

5. Switch `origin` around so your new repository becomes default:

		git remote rename origin oldrepo
		git remote rename newrepo origin
	
6. Or get rid of the old `origin` altogether if you're positive you won't be needing it anymore:

		git remote remove origin
		git remote rename newrepo origin
