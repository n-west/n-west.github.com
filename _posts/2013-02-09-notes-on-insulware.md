---
layout: post
title: Notes on Setting up Insulware
category: insulware
tag: insulware,openembedded,beaglebone
---

Notes on setting up Insulware
=============================

I'm working on setting up some firmware for a beaglebone, located at [http://github.com/n-west/insulware](n-west/insulware).
Some specific goals:
* Set cpufreq governor to powersave on boot
* Have users set up on first boot
* Have ppp configured and ready to go
* Set up cron jobs ready for first boot

# systemd #
Even though sysvinit and rc scripts work with systemd I decided to go with systemd for setting the governor on boot. This is mostly because systemd seems to be all the rage even though people complain about it; I figured I'd see what all the fuss is about.

Here's my systemd service script. It's located in `/lib/systemd/systemd/monitormode.service`

    [Unit]
    Description=Monitor Mode Setup for insulware
    After=multi-user.target

    [Service]
    ExecStart=/usr/bin/cpufreq-set --governor powersave
    
    [Install]
    WantedBy=multi-user.target

ExecStart gets called when the command `systemctl start monitormode` is called. It just executes whatever you put there. To get this to start on boot you have to do `systemctl enable monitormode.service`. Don't leave off the `.service` part; it won't work and you get a super obscure error:

    $ systemctl enable monitormode
    Failed to issue method call: Invalid argument

## Installing ##

From my research so far (and stdout) it looks like the systemctl command just creates a symlink to the service file:

    $ systemctl enable monitormode.service
    ln -s '/lib/systemd/system/monitormode.service' '/etc/systemd/system/multi-user.target.wants/monitormode.service'

So in my recipe for insulware I'll have to do that linking. I doubt systemctl will work in the OE environment.

# PPP #

PPP has been finicky, although it does work. For some reason the USB modem is detected and I can see the module loaded on boot, but the `/dev/ttyHS[0-4]` devices are not created. What *does* create the device nodes is unplugging/plugging back in the modem. I read about another guy having the same problem for some home automation stuff he was trying to do. I can't find the link right now and I don't recall him having a solution, but this is kind of a problem.

# Cron Jobs #
Well, this is for another day... I forgot to install crontab apparently. Are there any alternatives? Is crontab the best solution for scheduling jobs?

# Users (`/etc/passwd`)
This will be a combination of the `/etc/passwd` and `/etc/shadow`, I think. That's relatively simple and the easy way for me to think about doing it is to set up users the way I want on a booted device and just copy those files in to my repo. 
