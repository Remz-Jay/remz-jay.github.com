---
layout: post
title: "PHP: Testing the Pseudo Random Number Generator"
date: 2009-05-26 18:44:44 +0200
comments: true
categories: ["PHP"]
---

Every programmer uses them.. `PRNG`'s, better known as *Pseudo-Random Number Generators*; in PHP represented by the [`rand(min,max)`][1] function. 

Unlike *True Random Number Generators* (`TRNG`'s) that use true random data like atmospheric noise to create their numbers, `PRNG`'s rely on software algorithms to come up with seemingly random numbers.. *but are they*? 

And is there a difference between Linux and Windows `PRNG` results?
 <!-- more -->

I decided to give it a little try, and came up with the following, very simple but yet quite test:

``` php Pseudo Random Number Generator Test 
<?php
//init
$h = 500;
$w = 1000;
$colors = hexdec("FFFFFF");
$col = $colors/10;
$img = imagecreatetruecolor($w,$h);
$nul = 0;
$een = 0;
$twee = 0;
$drie = 0;
$vier = 0;
$vijf = 0;
$zes = 0;
$zeven = 0;
$acht = 0;
$negen = 0;
$tien = 0;
$tp = 0;

//cols
for($i=0;$i<$h;$i++) {
 //rows
 for($j=0;$j<$w;$j++) { 		
 $k = rand(0,10); 		
 imagesetpixel($img,$j,$i,($col*$k)); 		
 $tp++; 		
 switch($k) { 			
 case(0): $nul++; break; 			
 case(1): $een++; break; 			
 case(2): $twee++; break; 			
 case(3): $drie++; break; 			
 case(4): $vier++; break; 			
 case(5): $vijf++; break; 			
 case(6): $zes++; break; 			
 case(7): $zeven++; break; 			
 case(8): $acht++; break; 			
 case(9): $negen++; break;
 case(10): $tien++; break; 		
 } 	
 } 
} 
$bl = imagecolorallocate($img,0,0,0); 
$or = imagecolorallocate($img,220,210,60); 
imagefilledrectangle($img,5,5,150,230,$bl); 
imagestring($img,3,10,10,"Nul: $nul (".round(($nul/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,30,"Een: $een (".round(($een/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,50,"Twee: $twee (".round(($twee/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,70,"Drie: $drie (".round(($drie/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,90,"Vier: $vier (".round(($vier/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,110,"Vijf: $vijf (".round(($vijf/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,130,"Zes: $zes (".round(($zes/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,150,"Zeven: $zeven (".round(($zeven/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,170,"Acht: $acht (".round(($acht/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,190,"Negen: $negen (".round(($negen/($tp/100)),2)."%)",$or); 
imagestring($img,3,10,210,"Tien: $tien (".round(($tien/($tp/100)),2)."%)",$or); 
header("Content-type: image/png"); imagepng($img); imagedestroy($img); 
?>
```

Running this script will result in a noisy image, which when everything goes well, should be patternless (otherwise the results wouldn't be as random as they should be!). 
For convenience I added a few counters, to display the spread of the numbers.

In my test results **on both Windows and Linux**, the results came up about equal each time: 
There are no patterns in the images, significantly decreasing the chance of predicting the next number the `PRNG` will produce. (Which is important for various obvious matters). 
Though there are no visible patterns, the number spread seems to be about equal each run.. ***9% for each of the 11 possibilities..***

{% img /images/prngtest-output.png %}

I have my doubts about the randomness of such an equal spread.. but I'm not drawing any conclusions just yet.. perhaps when I feel like investigating this further ;-)

[1]: http://nl1.php.net/manual/en/function.rand.php
