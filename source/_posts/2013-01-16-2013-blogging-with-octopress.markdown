---
layout: post
title: "2013: Blogging with Octopress"
date: 2013-01-16 20:06
comments: true
categories: [Meta, Git]
---

Well. Here we are! 

New year, new approach to blogging. 

In the past year I haven't managed to push out a lot of blog articles though I've been working with loads of new, interesting technologies and approaches.

Being a programmer, I blame the software I use to blog. In my case that's the [TYPO3][3] installation at [rem.co][2]. It's recently been updated to TYPO3 6.0, and I haven't gotten around to fixing all the bugs that appeared after such a major upgrade.

Moreover, that site uses the ancient tt_news plugin as a blog substitute, which makes blogging a bit… troublesome to put it mildly. Especially "*advanced*" stuff like including code snippets and multiple layouts in one article.

{% img left http://octopress.org/images/logo.png %}
Then [Octopress][4] enters the stage, combining a lot of my favorite technologies to provide a somewhat nerdy approach to blogging.  
*Why haven't I tried this before?*


It uses [Git][8] as VCS **and** distribution system, publishes to [Github][5] and [Github Pages][6] and uses [markdown][7] to render my blog post ramblings, which in turn enables me to use the Mac OSX app [Markdown Pro][1] to quickly type up an article about a brilliant code snippet that I just came up with in an off-line fashion.  
*What can go wrong, right?*


Oh, yeah, and then there's one last thing. Traditionally, my website has always been hosted on my own bare metal server. Most stuff on that machine is highly unstable and/or experimental, so [rem.co][2]'s uptime hasn't been exemplary over the past few years, and probably never will be. Well, blog.rem.co is actually hosted by Github, so my gentoo, shorewall, nginx, varnish and apache experiments should no longer prevent you from reading the blog!
    

Well, let's see how long I can keep this up and if ye olde TYPO3 blog can be retired in favor of this one.. 

[1]: http://www.markdownpro.com/
[2]: https://rem.co
[3]: http://www.typo3.org
[4]: http://octopress.org
[5]: https://github.com/Remz-Jay
[6]: http://pages.github.com/
[7]: http://daringfireball.net/projects/markdown/syntax
[8]: http://git-scm.com/