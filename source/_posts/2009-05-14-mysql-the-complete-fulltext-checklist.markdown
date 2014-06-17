---
layout: post
title: "MySQL: The complete FULLTEXT checklist"
date: 2009-05-14 18:16:04 +0200
comments: true
categories: ["MySQL"] 
---

In an effort to help a colleague with `FULLTEXT` search troubles today, I tried to find out everything that could go wrong with setting up this search method on a table.
My short research resulted in this checklist. Failure to comply with these checks will result in *catastrophic* failure :P 
 
1. Make sure the table you're trying to `FULLTEXT` on has `MyISAM` type! Currently, `FULLTEXT` searches do **NOT** work on InnoDB types. 
If you are bound to using `InnoDB` for various reasons, you could create a duplicate table in `MyISAM` to perform your searches on. 

2. Ensure that your tables have `Indexes` with the `FULLTEXT` type for all columns you're trying to perform `FULLTEXT` searches on. If you don't have such an index, you can easily add it by using: 

		ALTER TABLE xxx ADD FULLTEXT(yyy,zzz);
	
	*Where `xxx` is your table name, and `yyy` + `zzz` are the columns you want to search.* Do this for earch individual column or set of columns you want to search.
 
3. If you changed anything in your setup, you might want to rebuild the Indexes. This is done by issuing:
		
		REPAIR TABLE xxx;

4. If you are building a search function for a product catalog, it's likely that you have to match against short words. e.g. a product that has the name `16C`. 
	`FULLTEXT` defaults to using 4 characters for the shortest possible word, so your `16C` is not a valid word, and will be omitted in search results. 
	You can change this by editing your `my.cnf` (likely to reside in `/etc/mysql/my.cnf` on Linux based systems), and adding the `ft_min_word_len` directive to the appropriate sections: 

		[mysqld] 
		ft_min_word_len = 2 

		[myisamchk] 
		ft_min_word_len = 2

	Do note that shortening the minimum word length significantly increases the load on your MySQL server, so this might be a VERY bad idea on large tables/busy systems. (You might as well go back to using `%LIKE%` searches ;)). 
	After you added the directives, restart MySQL (e.g. `/etc/init.d/mysql restart`), and rebuild your table indexes using the `REPAIR` command from check 3.
 
5. `BLOB` is a commonly used fieldtype for fields that contain large bits of content. `BLOB` is a binary type though, and it disables the possibility to use `FULLTEXT` searches on fields that have the `BLOB` type. 
	Solution is to convert the `BLOB` fields you want to search to the non-binary `TEXT` type. (Or any equivalent type of your choise). This can be done by issuing: 

		ALTER TABLE xxx MODIFY yyy TEXT;
 
	*Where `xxx` is the tablename and `yyy` the fieldname.* 
 
6. Last but not least.. make sure you have a MySQL version running that supports `FULLTEXT` searching. Basic `FULLTEXT` has been around since 3.23.23. 
	If you want to use the more advanced `IN BOOLEAN MODE` directive in your `AGAINST()`, you need to have a whopping MySQL 4.1 or better available to you. 
	(Just install MySQL5 and you're in the green!;)) If you are GO on all these checks, and it still doesn't work.. it might very well be your Query that's messed up. 

	Although the FULLTEXT basics are out of this blogposts scope , here's a very basic `FULLTEXT` query that should work: 

		SELECT * 
		FROM xxx 
		WHERE MATCH(yyy,zzz) AGAINST ('+aaa -bbb' IN BOOLEAN MODE);
 
	*`xxx` = table, `yyy` + `zzz` are columns (make sure they're indexed in a group!), `aaa` + `bbb` are Strings. `aaa` will be included, `bbb` excluded.*
 
 Good luck!
