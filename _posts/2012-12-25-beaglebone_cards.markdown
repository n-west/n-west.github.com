---
layout: post
title: Creating a Bootable SD card from an Angstrom/OE build

---

# Assumptions / Tools
1. I use cfdisk because the documentation for fdisk/sfdisk/cfdisk says that cfdisk is a beautiful program and should be the first one to use when given a choice. 
See the BUGS section of man fdisk for further information.

2. I use Ubuntu Linux.

# Steps
## Step one: Find the card
Insert SD card, and find what device node the card is on.
    dmesg | tail

The card should show up with some messages about mounting existing filesystems and caching modes.

    [324127.487720] sd 9:0:0:0: [sdc] Attached SCSI removable disk
    [324127.920227] EXT4-fs (sdc2): mounted filesystem with ordered data mode. Opts: (null)
    [324493.170300] sd 9:0:0:0: [sdc] No Caching mode page present
    [324493.170305] sd 9:0:0:0: [sdc] Assuming drive cache: write through
    [324493.172068]  sdc: sdc1 sdc2

In my case the card is on /dev/sdc and has two partitions, sdc1 and sdc2.

## Step two: format the card
The card should be unmounted using something like

```bash
sudo umount /dev/sdc1
sudo umount /dev/sdc2
```

Clear the MBR (Master Boot Record).
Be very careful with this step, this has potential to wipe out your hard drive's MBR as well, which would be very difficult to fix. 

```bash
sudo dd if=/dev/zero of=/dev/sdc bs=1024 count=1024
```

Now use a disk partition tool to create a "boot" and "rootfs" partition. 
As stated earlier, I use cfdisk

```bash
sudo cfdisk /dev/sdc
```

cfdisk is pretty user-friendly. (Yay, for agreeing with the docs!)
Delete the existing partitions and create two more for boot and rootfs. 
Here's what mine looks like

     
                                cfdisk (util-linux 2.20.1)
     
                                     Disk Drive: /dev/sdc
                                Size: 3904897024 bytes, 3904 MB
                     Heads: 121   Sectors per Track: 62   Cylinders: 1016
     
        Name         Flags       Part Type   FS Type           [Label]         Size (MB)
     -------------------------------------------------------------------------------------
        sdc1         Boot         Primary    W95 FAT32                            126.76   
        sdc2                      Primary    ext3              [Angstrom]        3778.15  *
     

Some tips:
1) hit enter over the "bootable" option to make the first partition bootable.
2) W95 FAT32 partition is type 0x0b
3) Linux is type 0x83.

Hit "Write", and "Quit".
Now our disk is partitioned and we need to make a filesystems.

## Create filesystems

```bash
sudo mkfs.vfat -F 32 -n "boot" /dev/sdc1
sudo mkfs.ext3 -L "rootfs" /dev/sdc2
```

The second one will take some time if your disk is big. 
It's always a good idea to use the `sync` command
As the manpage says, sync forces changed blocks to disk and updates the super block. 

```bash
    sudo sync
```

Now we should be able to mount both of the filesystems.

## Mount the newly created filesystems

There are two options here.

One is to remove the disk and plug it in again. 
If you do this, I reccomend doing `sudo eject /dev/sdc` first. 
Your computer will probably automount both filesystems to /media/boot and /media/rootfs. 
The `mount` command alone will list the mountpoints.

My preferred method is to create two directories in `/mnt/`.

```bash
sudo mkdir /mnt/rootfs
sudo mkdir /mnt/boot
```

Now mount the new filesystems

```bash
    sudo mount /dev/sdc1 /mnt/boot
    sudo mount /dev/sdc2 /mnt/rootfs
```

## Write files to disk

Using OE I built Angstrom distribution's  systemd-image. 
This generates the following file manifest:

    Angstrom-systemd-image-eglibc-ipk-v2012.12-beaglebone.rootfs.tar.bz2
    config-3.2.28-r16b+gitr720e07b4c1f687b61b147b31c698cb6816d72f01-beaglebone.config
    config-beaglebone.config
    mkcard.sh
    MLO
    MLO-beaglebone
    MLO-beaglebone-2011.09+git
    modules-3.2.28-r16b+gitr720e07b4c1f687b61b147b31c698cb6816d72f01-beaglebone.tgz
    modules-beaglebone.tgz
    README_-_DO_NOT_DELETE_FILES_IN_THIS_DIRECTORY.txt
    systemd-image-beaglebone.tar.bz2
    u-boot-beaglebone-2011.09+git-r30.img
    u-boot-beaglebone.img
    u-boot.img
    uImage
    uImage-3.2.28-r16b+gitr720e07b4c1f687b61b147b31c698cb6816d72f01-beaglebone-20121224175644.bin
    uImage-beaglebone.bin

Some of these are symlinks. 
Basically we are interested in the longer filenames. 
Using `ls -l` will show you which ones are symlinks. 
You should use the real files and not the links for the following steps. 

1. Copy files to /mnt/boot

```bash
        sudo cp MLO-beaglebone-2011.09+git /mnt/boot/MLO
        sudo cp u-boot-beaglebone-2011.09+git-r30.img /mnt/boot/u-boot.img
        sudo cp uImage-3.2.28-r16b+gitr720e07b4c1f687b61b147b31c698cb6816d72f01-beaglebone-20121224175644.bin /mnt/boot/uImage
```

2. Untar filesystem to /mnt/rootfs

```bash
        sudo tar -xjf Angstrom-systemd-image-eglibc-ipk-v2012.12-beaglebone.rootfs.tar.bz2 -C /mnt/rootfs/
```

It's a good idea to sync again,

```bash
        sudo sync
```

Unmount everything, and give the beaglebone a boot.

## Boot Beaglebone

Eject the SD card

```bash
    sudo umount /dev/sdc1
    sudo umount /dev/sdc2
    sudo eject /dev/sdc
```

Put the card into the beaglebone, and boot.
Hopefully it will boot up and you can see it through the serial port. :-)
