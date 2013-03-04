---
layout: post
title: "OnApp: Using PHP to launch a VNC connection"
date: 2013-03-01 12:48
comments: true
categories: [OnApp, PHP, VNC]
---

If you're an [OnApp][1] user you probably know you can make a VNC connection to your VM's using the Control Panel.
This uses a java applet in your browser as the VNC client.

Wouldn't it be nice to use your own VNC client (like [Remotix][2]) instead?

In fact, you can, but OnApp spawns a VNC server on a (somewhat) random port and a new random VNC password for each sessions which you'll have to figure out before setting up your connection. 

According to the [OnApp Helpdesk][3] you can use these calls to get the required information:
	GET /virtual_machines/:virtual_machine_id/console.xml
	GET /virtual_machines/:virtual_machine_id/console.json
As I'm lazy I didn't want to do this manually every time, so I devised a little PHP script that can aid in finding the right information:

<!-- more -->  

``` php OnApp VNC Initiator
<?php
/**
 * GET /virtual_machines/:virtual_machine_id/console.xml
 * GET /virtual_machines/:id.xml
 *
 * The first will start the console session and give you the port number to connect to.
 *
 * The second call, you are looking for remote_access_password.
 */
$CPURL = ""; // Insert the IP/hostname for your OnApp CP here
$VMID = ""; // Insert the VM's unique ID here
$username = ""; // Insert your own username here
$password = ""; // Insert the password for your account here

$ch = curl_init("http://{$CPURL}/virtual_machines/{$VMID}/console.json");

curl_setopt($ch, CURLOPT_USERPWD, $username . ":" . $password);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
$result = curl_exec($ch);
$set_one = json_decode($result);
curl_setopt($ch, CURLOPT_URL, "http://{$CPURL}/virtual_machines/{$VMID}.json");
$result = curl_exec($ch);
$set_two = json_decode($result);
$port = $set_one->remote_access_session->port;
echo "PORT:\t" . $set_one->remote_access_session->port . PHP_EOL;
echo "REMOTE_KEY:\t" . $set_one->remote_access_session->remote_key . PHP_EOL;
$rap = $set_two->virtual_machine->remote_access_password;
echo "REMOTE_ACCESS_PASSWORD:\t" . $rap . PHP_EOL;
$un = "root";
$pw = $set_two->virtual_machine->initial_root_password;
echo "ROOTPASS:\t" . $pw . PHP_EOL;
curl_close($ch);
$constructedURL = "vnc://{$CPURL}:{$port}/?vncPassword=" . urlencode($rap);
echo $constructedURL . PHP_EOL;
shell_exec("open " . $constructedURL);
?>
```

### Usage
* Using the PHP CLI: Run `$ php OnAppInitiator.php`
* The script will display all the information required and open up your default VNC client.

### Caveats
* This script assumes that you have the [PHP cURL extension][4] installed and enabled.
* The script is currently HTTP only as it's hard coded. With a little modification you can get HTTPS if your setup uses/requires that.
* You can get the VM's unique ID in the OnApp CP. If you go to the VM's detail page the URL for that page will look like `http://cloud.setup/virtual_machines/dfa2bcguwd9mbi`. The ID is evertyhing after the last `/`.
* The `open` call on the last line might not work on your OS; This script was developed/tested on Mac OSX.
* In order to `open` a `VNC://` link you'll have to specify a link handler on the OS. I used [RCDefaultApp][5] on OSX to set Remotix as the default link handler for VNC links.

### Future / TODO
The script is pretty crude in it's current state but it gets the job done for my day to day needs.

I might fix a couple of things in the near future:

* Grabbing the required variables such as VMID from the run parameters
* Make the script ask for these required variables
* Fix the script for use with HTTPS
* Integrate this script with the OnApp CP so you can start your VNC client right from the CP
[1]:http://onapp.com/
[2]:http://www.nulana.com/remotix-mac
[3]:https://onapp.zendesk.com/entries/22068371-use-own-vnc-client-instead-of-the-onapp-console
[4]:http://php.net/manual/en/book.curl.php
[5]:http://www.rubicode.com/Software/RCDefaultApp/
