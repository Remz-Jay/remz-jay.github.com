---
layout: post
title: "CSS: Overlapping Flash content with CSS"
date: 2009-05-29 19:06:33 +0200
comments: true
categories: ["CSS"] 
---
By default, flash movies are always shown on the top-level of a display tree. 

However, it can be very useful to be able to move the flash content to the background, and having it overlapped by other content;
e.g. You have a flash movie in the header of your website, but there's a sidebar menu which should be displayed over the header.

This is easily achieved by following these steps: 

1. Add `wmode="transparent"` to your object and embed tags which include the flash movie 
2. Wrap the `object` and `embed` tags by a `div` and assign a CSS class to it. 
3. Define a `z-index` for this class in your stylesheet. 
4. Assign a higher `z-index` for all items that should overlay the flash movie. 
5. Refresh and enjoy. 

#### Example: 

``` html HTML Flash Include
<div class="flashheader"> <object id="header" classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" width="1024" height="202" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,40,0">
 <param name="data" value="fileadmin/template/header.swf" /> <param name="wmode" value="transparent" />
 <param name="allowScriptAccess" value="sameDomain" />
 <param name="allowFullScreen" value="false" />
 <param name="quality" value="high" />
 <param name="bgcolor" value="#ffffff" />
 <param name="src" value="fileadmin/template/header.swf" />
 <param name="name" value="header" /><param name="allowfullscreen" value="false" />
 <embed id="header" type="application/x-shockwave-flash" width="1024" height="202" src="fileadmin/template/header.swf" name="header" bgcolor="#ffffff" quality="high" allowfullscreen="false" allowscriptaccess="sameDomain" wmode="transparent" data="fileadmin/template/header.swf">
 </embed>
 </object>
</div>
```

``` css CSS for Flash
div.flashheader {
 display: block;
 width: 1024px;
 left:0;
 margin-top:-260px;
 position: relative;
 z-index: 1;
}
```

``` css CSS for Overlap
div.side{
 height:578px;
 width:372px;
 float:left;
 background-image:url('../img/rightbar.png');
 position: absolute;
 top:114px;
 left: 612px;
 z-index: 100;
}
```
