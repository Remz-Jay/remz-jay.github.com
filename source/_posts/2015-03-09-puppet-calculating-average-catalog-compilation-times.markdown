---
layout: post
title: "Puppet: Calculating average catalog compilation times"
date: 2015-03-09 18:25:18 +0100
comments: true
categories: [puppet, bash, linux, oneliner]
---
*Just a quick post with the oneliner of the day.* 

When you are debugging catalog compilation issues or other puppet performance issues in general, it is good to know exactly which catalogs are slow to compile. Knowing which catalogs are substantially slower than others allows you to focus on those catalogs and the modules they contain. 

I devised this bash oneliner, [which is almost a direct copy of this example by Jadu Saikia][1], so full credits go to him!

``` bash Calculating Average Catalog Compilation Times in Puppet
cat /var/log/puppet/master.log | grep -i "compiled catalog for" | awk '{printf "%s\t%s\r\n",$9,$14}' | sort | awk 'BEGIN{FS="\t"; printf("%-35s\t\t%s\t\t%s\t\t%s\n", "Node","Count","Total","Average")} NR!=1 {a[$1]++;b[$1]=b[$1]+$2}END{for (i in a) printf("%-35s\t%10.0f\t%10.0f\t%10.2f\n", i, a[i], b[i], b[i]/a[i])}' | sort -n -k4
```
<!-- more -->

This will yield a result similar to:

``` bash Results
Node                                            Count         Total         Average
node02.customer.nl	                          71              44            0.62
srv08.customer.net                              71              50            0.70
solr.company.net                                71              64            0.90
data07.customer.io                              71             599            8.44
web21.customer.org                              73             932           12.77
node01.test.company.net                         79            1894           23.98
crm.company.net                                 70            2325           33.22
solr.website.com                                72            2607           36.21
customer.vps.company.net                        69            2762           40.03
p1.customer.company.net                         72            3058           42.47
customer1.dev.company.net                       70            3115           44.51
customer2.dev.company.net                       71            3325           46.83
solr.dev.company.net                            71            3348           47.15
customer3.dev.company.net                       71            3496           49.24
customer4.dev.company.net                       71            3554           50.06
customer5.dev.company.net                       71            3558           50.11
customer6.dev.company.net                       70            3542           50.60
customer7.dev.company.net                       70            3683           52.62
agent01.isp.bamboo.company.net                  71            3761           52.98
solr.customer.nl                                71            3798           53.50
customer8.dev.company.net                       72            3896           54.11
v2.isp.dev.company.net                          71            3928           55.32
net-loc-isp08.company.net                       71            4108           57.86
puppet.company.net                              70            4092           58.45
customer9.dev.company.net                       70            4112           58.75
customer10.dev.company.net                      71            4188           58.98
customer11.dev.company.net                      70            4139           59.13
zabbix.vps.company.net                          70            4148           59.26
```

Obviously I've randomized the node names to protect company and customer specific details, but the averages are real.

Looks like I have my work cut out for me to reduce those times, ~60 seconds is just way too long. 


[1]:http://www.unixcl.com/2008/09/group-by-clause-functionality-in-awk.html
