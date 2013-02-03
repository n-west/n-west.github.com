---
layout: default
title: Notes on Angstrom+BeagleBone+Option Icon Modem
---

# Introduction #
I'm using a BeagleBone. 
I use OpenEmbedded/bitbake to build Angstrom images. 
I use [setup-scripts](http://gitorious.org/angstrom/angstrom-setup-scripts)  to set up my OE environment \(I'm lazy\)
I build an image I called [insulaudit-image](https://github.com/n-west/meta-insulaudit/tree/master/image) that will probably be slightly more customized in the future. 

I am trying to use an Option GlobeTrotter Icon322 3G modem from the beaglebone.

# A brief timelime #
Around Dec 25, 2012 I was using a beaglebone running an image that I can't recall. I think it was a cloud9-image or something. 
The image was able to identify the modem and connect to the network. 

I had this great idea to build a custom image for some work we were about to do on insulaudit. 
So I fired up OE and built using Angstrom's recent release v2012.12.

Well, the modem was detected but could not connect to networks. 
The symptoms were

    AT
    OK
    AT+CFUN?
    +CFUN: 4
    
    OK
    AT+CFUN=1
    OK
    AT+CFUN?
    +CFUN: 4

Needless to say, this was frustrating.
I don't want to relay the whole thing, so check out [the notes](https://gist.github.com/4696606) I am keeping.
TL;DR is I think the hso kernel module might be to blame, but there's a good chance I'm wrong. 
It might be whatever network manager/modem manager Angstrom uses.

But *something* changed in those 7 months and broke modems that use the hso kernel module.

# A couple of links#
There's a few handy links that are worth sharing.
[Option summarized sending an SMS using AT commands on their website](https://gist.github.com/4645594). I don't know why they took it down.
[This guy has some interesting notes doing similar things](http://beaglebonegsmmonitor.blogspot.com/2012_04_01_archive.html)
[This person had the same exact issues with Angstrom + our modem and hso module.](http://www.draisberghof.de/usb_modeswitch/bb/viewtopic.php?f=3&t=1227). His solution was to switch to Ubuntu.
