---
layout: post
title: "MySQL: Boolean substitution"
date: 2009-04-27
comments: true
categories: [MySQL, PHP]
---

Today I faced a quite interesting problem, that originated from pure laziness.
I'm developing a backend system for a quite complex database structure. Within this backend, an almost limitless amount of table views have to be created for the end user. Because I'm extremely lazy, and didn't want to develop the html view code for each table view, I created a PHP html-table-generator-class, which takes a `mysql_result_set` as parameter, and outputs the html table in string format.

This method works great, unless for some cases, where a value in the query has to be substituted by a user readable value. A boolean is a good example of such a value.

<!-- more -->

###Booleans in MySQL

Since MySQL doesn't natively support boolean values, there are various methods of saving booleans to a database. Common practices include fields of the format `CHAR(1)`, `TINYINT(1)` and `ENUM('Y','N')`. Recent versions of MySQL also include the `BIT` field format, which in fact boils down to using `TINYINT(1)`, when it comes to boolean values.

I always use the `TINYINT(1)` field format for my boolean columns. This works perfectly, since you can `INSERT` true/false values, which are automatically transformed to 1/0. When you `SELECT` a boolean column in PHP, this also works, since you can compare true/false to 1/0 within PHP. (Whether this loose type handling is preferable is a discussion for another time).

However.. when you `SELECT` a boolean column, and run it through a generic html table generator class such as mine, you'll end up with a nice table showing 1's and 0's, which aren't very user friendly (Having in mind that most backend users aren't quite as computer savvy as you are!). Replacing all 1's and 0's within the PHP code was not an option, since it would be a generic measure, and would also transform ID's and Prices and such. So I had to come up with a solution to substitute the boolean values within the MySQL result by human readable values.

##Substituting boolean values within a MySQL SELECT query


The solution is in fact, as they usually are, quite simple. MySQL supports the use of the `REPLACE()` SQL command. Usually this command is used to `UPDATE` tables with replacement values, but it also works within a `SELECT` query to alter results. Having this in mind I started out replacing one value in the result:

``` sql
SELECT REPLACE(boolColumn,'1','true') AS booleanValue FROM tableName;
```

This works! There's a slight catch though, since 'false' values also have to be substituted. After some fiddling with `IF` and `AND` constructions, the solutions was of course a lot easier:

``` sql
SELECT REPLACE(REPLACE(boolColumn,'0','false'),'1','true') AS booleanValue FROM tableName;
```

And there you have it.. value substitution 101 in MySQL. This method also works for your other substitution needs!