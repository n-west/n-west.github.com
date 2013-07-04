---
title: Getting termios (serial port io) for socat working on Angstrom/Beaglebone
layout: default
---

# Background #
I'm trying to use socat on my beaglebone. 
I have a custom image based on Angstrom's systemd image that loads up some
custom firmware I've created. 
This relies on socat to connect a serial port to a TCP socket. 
Socat worked beautifully in all of my tests, then I tried to actually do a demo
and socat failed, giving

    2000/01/01 10:58:00 socat[446] E parseopts(): unknown option "b9600"

So the option to set the baud rate of my serial port is unknown. Le sigh...

# Investigations #
## Socat ##
I look for the baud rates available in my socat installation with

    socat -?? | grep 'b[0-9]'

On my laptop I get a large list of supported baud rates in the TERMIOS group. 
On my beaglebone I get nothing. 
No wonder it can't deal with the baud rate option...

## OpenEmbedded ##
The default socat recipe (there's actually two: one in openembedded-core and one
in meta-openembedded has a line with an extra configure option disabling termios
support. 
I commented that line out to get termios support. 
That created a build error for me. 

    Log data follows:
    | DEBUG: SITE files ['endian-little', 'bit-32', 'arm-common', 'common-linux',
    'common-glibc', 'arm-linux', 'arm-linux-gnueabi', 'common']
    | ERROR: Function failed: do_compile (see
    /home/nathan/Documents/setup-scripts-1_2/build/tmp-angstrom_v2012_05-eglibc/work/armv7a-angstrom-linux-gnueabi/socat-1.7.1.2-r1/temp/log.do_compile.7517
    for further information)
    | NOTE: make -j2
    | ccache arm-angstrom-linux-gnueabi-gcc  -march=armv7-a -fno-tree-vectorize
    -mthumb-interwork -mfloat-abi=softfp -mfpu=neon -mtune=cortex-a8
    --sysroot=/home/nathan/Documents/setup-scripts-1_2/build/tmp-angstrom_v2012_05-eglibc/sysroots/beaglebone
    -O2 -pipe -g -feliminate-unused-debug-types -D_GNU_SOURCE -Wall -Wno-parentheses
    -DHAVE_CONFIG_H -I.  -I.   -c -o socat.o socat.c
    | ccache arm-angstrom-linux-gnueabi-gcc  -march=armv7-a -fno-tree-vectorize
    -mthumb-interwork -mfloat-abi=softfp -mfpu=neon -mtune=cortex-a8
    --sysroot=/home/nathan/Documents/setup-scripts-1_2/build/tmp-angstrom_v2012_05-eglibc/sysroots/beaglebone
    -O2 -pipe -g -feliminate-unused-debug-types -D_GNU_SOURCE -Wall -Wno-parentheses
    -DHAVE_CONFIG_H -I.  -I.   -c -o xioinitialize.o xioinitialize.c
    | xioinitialize.c: In function 'xioinitialize':
    | xioinitialize.c:69:48: error: 'OSPEED_OFFSET' undeclared (first use in this
    function)
    | xioinitialize.c:69:48: note: each undeclared identifier is reported only once
    for each function it appears in
    | make: *** [xioinitialize.o] Error 1
    | make: *** Waiting for unfinished jobs....
    | ERROR: oe_runmake failed
    NOTE: package socat-1.7.1.2-r1: task do_compile: Failed

# Solutions #

Thanks to "The Presence" on the [gumstix mailing
list](http://gumstix.8.n6.nabble.com/Re-cross-compiling-bitbake-headaches-SOLVED-td562502.html)
I was able to fix the problems. 
I present to you basically a rehash of his e-mail in a hopefully more convenient
form. 

So there is a missing definition for `OSPEED_OFFSET`. 
Grepping the source tree will find the following:

    $ grep * -e 'OSPEED'
    config.h.in~:#  define OSPEED_OFFSET (ISPEED_OFFSET+1)
    config.h.in~:#  undef OSPEED_OFFSET

So OSPEED_OFFSET should be defined to be `I_SPEED_OFFSET + 1`, I have no idea
why it is getting undef'd. 
In the `config.h` file underneath the `ISPEED_OFFSET` definition I added the
following line

    #define OSPEED_OFFSET 13

Retrying the build I see there are some more definitions missing. 

    | .  -I.   -c -o xio-readline.o xio-readline.c
    | xio-termios.c:48:132: error: 'CRDLY_SHIFT' undeclared here (not in a function)
    | xio-termios.c:97:135: error: 'TABDLY_SHIFT' undeclared here (not in a
    function)
    | xio-termios.c:205:132: error: 'CSIZE_SHIFT' undeclared here (not in a
    function)
    | make: *** [xio-termios.o] Error 1
    | make: *** Waiting for unfinished jobs....
    | ERROR: oe_runmake failed
    NOTE: package socat-1.7.1.2-r1: task do_compile: Failed

Going back and grepping the source tree...

    $ grep */* -e 'CRDLY_SHIFT'
    autom4te.cache/output.0:  { $as_echo "$as_me:${as_lineno-$LINENO}: result:
    please determine CRDLY_SHIFT manually" >&5
    autom4te.cache/output.0:$as_echo "please determine CRDLY_SHIFT manually" >&6; }
    autom4te.cache/output.1:  { $as_echo "$as_me:${as_lineno-$LINENO}: result:
    please determine CRDLY_SHIFT manually" >&5
    autom4te.cache/output.1:$as_echo "please determine CRDLY_SHIFT manually" >&6; }
    Config/config.AIX-5-3.h:#define CRDLY_SHIFT 8
    Config/config.Cygwin-1-5-25.h:#define CRDLY_SHIFT 7
    Config/config.FreeBSD-6-1.h:#define CRDLY_SHIFT -1
    Config/config.Linux-2-6-24.h:#define CRDLY_SHIFT 9
    Config/config.MacOSX-10-5.h:#define CRDLY_SHIFT 12
    Config/config.NetBSD-4-0.h:#define CRDLY_SHIFT -1
    Config/config.OpenBSD-4-3.h:#define CRDLY_SHIFT -1
    Config/config.SunOS-5-10.h:#define CRDLY_SHIFT 9

Apparently this is dependent on the OS you're running. 
I plan to use linux, so I'll use 9.

Looking for the other two missing constants, I used

    $ grep -e 'TABDLY_SHIFT' -e 'CSIZE_SHIFT' -d recurse -f *
which generates a lot of output that I won't copy here. 
The revelant pieces that I found useful: 

    Config/config.Linux-2-6-24.h:#define TABDLY_SHIFT 11
    Config/config.Linux-2-6-24.h:#define CSIZE_SHIFT 4
    Config/config.SunOS-5-10.h:#define TABDLY_SHIFT 11
    Config/config.SunOS-5-10.h:#define CSIZE_SHIFT 4
    Config/config.Cygwin-1-5-25.h:#define TABDLY_SHIFT 11
    Config/config.Cygwin-1-5-25.h:#define CSIZE_SHIFT 4
    Config/config.NetBSD-4-0.h:#define TABDLY_SHIFT -1
    Config/config.NetBSD-4-0.h:#define CSIZE_SHIFT 8
    Config/config.AIX-5-3.h:#define TABDLY_SHIFT 10
    Config/config.AIX-5-3.h:#define CSIZE_SHIFT 4
    Config/config.OpenBSD-4-3.h:#define TABDLY_SHIFT -1
    Config/config.OpenBSD-4-3.h:#define CSIZE_SHIFT 8
    Config/config.MacOSX-10-5.h:#define TABDLY_SHIFT -1
    Config/config.MacOSX-10-5.h:#define CSIZE_SHIFT 8
    Config/config.FreeBSD-6-1.h:#define TABDLY_SHIFT -1
    Config/config.FreeBSD-6-1.h:#define CSIZE_SHIFT 8
    config.h.in~:#undef TABDLY_SHIFT
    config.h.in~:#undef CSIZE_SHIFT

So, in config.h I added the following lines:
    + #define CRDLY_SHIFT 9
    + #define TABDLY_SHIFT 11
    + #define CSIZE_SHIFT 4

Now the build succeeds. 

# Summary and diffs #
In summary, here is the diff from the original config to the working one:

    *** config.h.old    2013-02-14 13:04:09.489644780 -0600
    --- config.h    2013-02-14 13:11:57.715966591 -0600
    ***************
    *** 496,501 ****
    --- 496,507 ----
      /* have ispeed */
      #define ISPEED_OFFSET 13
      
    + /* add def's missing from OE configure to get termios working on beaglebone */
    + #define OSPEED_OFFSET 14                                                        
    + #define CRDLY_SHIFT 9
    + #define TABDLY_SHIFT 11
    + #define CSIZE_SHIFT 4
    + 
      /* openssl fips */
      /* #undef OPENSSL_FIPS */
      

And the bitbake recipe in meta-oe/recipes-support/socat/socat_1.7.1.2.bb

    *** socat_1.7.1.2.bb    2013-02-14 13:18:41.625969470 -0600
    --- socat_1.7.1.2.bb.old    2013-02-14 13:18:35.517939181 -0600
    ***************
    *** 11,17 ****
      SRC_URI[md5sum] = "9c0c5e83ce665f38d4d3aababad275eb"
      SRC_URI[sha256sum] = "f7395b154914bdaa49805603aac2a90fb3d60255f95691d7779ab4680615e167"
      
    ! # EXTRA_OECONF = " --disable-termios "
      
      inherit autotools
      
    --- 11,17 ----
      SRC_URI[md5sum] = "9c0c5e83ce665f38d4d3aababad275eb"
      SRC_URI[sha256sum] = "f7395b154914bdaa49805603aac2a90fb3d60255f95691d7779ab4680615e167"
      
    ! EXTRA_OECONF = " --disable-termios "
      
      inherit autotools
  
I'll update when I get a chance to test this on my 'bone. 
Hopefully this finds someone in similar straits.
