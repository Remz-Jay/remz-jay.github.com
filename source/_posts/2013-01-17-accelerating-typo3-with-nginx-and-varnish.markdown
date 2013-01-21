---
layout: post
title: "Accelerating TYPO3 with Nginx &amp; Varnish"
date: 2013-01-17 14:00
comments: true
categories: [Nginx, Varnish, TYPO3]
published: false
---

So, you have a TYPO3 website and despite all your best efforts, it's still too slow in your opinion.

Maybe it's time to start using Varnish as a caching reverse proxy to help speed things along. It's fairly easy to set up, but there are some caveats when it comes to TYPO3. I'll try to outline a fairly basic scenario below that should fit a number of TYPO3 installations.

# The setup

What we're going to build is an Nginx server that handles all external requests from the web. It uses Varnish as a backend server. We put Nginx in front of Varnish because Varnish is unable to handle SSL requests, and the site we're serving uses SSL.
Nginx will handle all SSL related things. Behind that, everything is just regular HTTP.

Varnish in turn uses an Apache2+mod_php server as backend which is the 'real' webserver that is serving TYPO3. This shouldn't have to be Apache2, but can just as well be Nginx/Lighttpd+php-fpm or anything else you can come up with. 

<!-- more -->
We'll start from the top down:

## Nginx

I like to have all my vhosts in separate files, so we'll start by adding
``` nginx
include /etc/nginx/conf.d/*.conf;
```	
at the end of the `http{ .. }` part of `/etc/nginx/nginx.conf`. 

Now we can use `/etc/nginx/conf.d/varnish.site.conf` for our new vhost:

``` nginx
server {
        listen [::]:80 default ipv6only=on;
        listen 80;
        server_name varnish.site;
        location / {
          rewrite ^(.*) https://varnish.site$1 permanent;
        }
}

server {
        listen 443 ssl;
        listen [::]:443 ipv6only=on ssl;
        ssl_certificate /etc/ssl/nginx/varnish_site.crt;
        ssl_certificate_key /etc/ssl/nginx/varnish_site.key;
        ssl_protocols SSLv3;
        ssl_ciphers HIGH:!ADH:!MD5;
        ssl_prefer_server_ciphers on;
        server_name varnish_site;
        access_log /var/log/nginx/varnish.site.access_log main;
        error_log /var/log/nginx/varnish.site.error_log notice;
    
        rewrite ^/a/ /to/b/ permanent;
        rewrite ^/and/c/(.*) /to/b/also/$1 permanent;

  		location / {
                proxy_pass http://127.0.0.1:9090;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto https;
                proxy_redirect off;
        }
}
```

This takes care of a couple of things:

 * A HTTP server on TCP/80 of all interfaces that redirects all calls to `http://varnish.site` to `https://varnish.site`
 * A HTTPS server on TCP/443 of all interfaces that will forward all calls to the `proxy_pass`, but does so using HTTP.
 * Before any forwarding is done, it evaluates the rewrites that are defined, so all redirection is done by the first responder instead of passing them down the chain.  

 
## Varnish

The Nginx server above will proxy all calls to `http://127.0.0.1:9090`, so that's where we'll run our Varnish server (`-a`).  
Additionally we'll specify a default backend (`-b`) and a management interface (`-T`) to be able to use `varnishadm`.

On the Gentoo machine used in this example the setup would be: 

``` 
# /etc/conf.d/varnishd

# options passed to varnish on startup
# please see the varnishd man page for more options
VARNISHD_OPTS="-a 127.0.0.1:9090 -b 127.0.0.1:8080 -T 127.0.0.1:7070"

# arguments passed to varnishncsa
# please see the varnishncsa man page for more options
VARNISHNCSA_ARGS="-c -a -w /var/log/varnish/access.log"                                                                  
```
