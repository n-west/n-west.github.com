---
layout: post
title: RF Front Ends on Beaglebone
category: sdr
tags: sdr masters hardware
---

I've been frantically trying to get my MS thesis experiment running so I can (finally) finish this degree. 
I've got to the point where I'm about 90% happy with my code as it is, but I'm running in to performance issues. 
My lab at okstate is a little dated in terms of computing power (and even RF front ends, only a couple of USRP1s and USRP2s). 
In terms of computing power the best portable machine we have is running a Core 2 duo. 
Contrary to what marketers will tell you, this hardware is fine for many computing tasks and every day use. 
Unfortunately it sucks in terms of SDR. 

I have a loopback [flowgraph](https://github.com/n-west/gr-west_3_6/blob/master/examples/loopback.grc) that works in all software every time. 
I set up a transmitter running on a laptop with a single core Centrino (yikes!) that does WBPSK modulation, connected to an USRP1. 
The receiver runs on the Core 2 Duo laptop connected to an USRP1. 
I get nothing useful out of the receiver -- every bit is in error. 
When I look at an FFT or waterfall it's very sporadic -- definitely does not look like a continuously streaming PSK signal.

To solve this I'm thinking I'm currently planning to use my laptop as a receiver and use one of my ARM boards as the transmitter. 
I would like to use the ODROID-X I have, but the instructions for building from hardkernel are kind of disappointing. 
There's a meta-layer from a guy building an ODROID-X2 that looks promising, and I've taken a naive approach to copying his work without success. 

My current solution is to use my beaglebone since it's a pretty trusty platform and the clock isn't too bad on it. 
To this end I've started building libbladerf and libhackrf with the gr-osmosdr OOT module in OE.
That work is building, but untested so far. 
It's on my [github](https://github.com/n-west/meta-west)
