---
title: Design Notes on InsulWare
layout: post
category: insulware
tags: insulware openembedded
---

# High Level Overview #
The file manifest in `/home/new/` does the heavy lifting for connecting serial devices to remote ports. 
The files include 

* parseSMS
* handleDevice
* deviceDetect
* requestResources
* serialToNet
* auditConfig

## SMS Parsing ##
`parseSMS` is already finished and checks for new SMS messages, parses the messages, and acts according to a simple command structure. 
The command structure is `<command> resource`. 
The command can be one of, `STO`, `EXEC`, `EXEC1`. 
`STO` downloads and stores a file. 
`EXEC` executes a file that should already exist. 
`EXEC1` downloads the file indicated and then runs it. 

## auditConfig ##
auditConfig is an ini formatted config file. And example,
    [deviceDetect]
    vid=foo
    pid=bar
    
    [resourceRequest]
    remote_addr=localhost
    port_addr=80
    page=audit.php
    user_id=nathan
    key_loc=key
    
    [serialToNet]
    remote_addr=localhost
    remote_port=9001


## handleDevice ##
`handleDevice` detects currently connected devices and prints a USB vid/pid pair. 
It will read in USB vid/pid pairs from deviceDetect and check if they are currently attached. If so the vid/pid is printed, each device is printed on a new line. 

## resourceRequest ##
`resourceRequest` uses the URL indicated in the resourceRequest section of auditConfig to request the remote dedicate resources for an attached device. The response should be permission granted along with a baud rate to use. 

## serialToNet ##
`serialToNet` strings together a serial port of an indicated device to a TCP socket on a remote server indicated by the settings in the `serialToNet` section of `auditConfig`.


# Implementation #
This section describes the initially desired implementation of the files described above. 
With any luck the implementation is not stuck on what I have here and can be changed in the future without breaking interfaces described previously. 

## handleDevice ##
I don't know yet.

## resourceRequest ##
`resourceRequest` is a bash script wrapper for curl. 
Accept parameters in order `DEST PORT PAGE USER KEY`. 
Does a curl on the page indicated at dest:port. 
Attaches the query string `?user=${USER}&key=${KEY}`. 
The remote should respond with `permission=granted\nbaud=<baud>`. 
The baud rate is echoed to stdout if permission was granted. 

## serialToNet ##
`serialToNet` takes in the following arguments: `BAUD ADDR PORT`. 
This currently does a combination of `socat` and `ssh` magic. 
`socat` forwards the serial port to a port on localhost. 
`ssh` uses local port forwarding to forward the port opened by socat to a remote port and secures it. 

There are a number of other ways of doing this, many of the good ones involve using socat.
If we could secure telnet over this ssh tunnel then something along the lines of RFC 2217 could be used. 
