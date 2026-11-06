# TFTP: copy files to SD (mmcblk0p1) from U-Boot

## Part 1: One-time setup

### Ubuntu

```bash
sudo apt install -y tftpd-hpa
sudo chown -R $USER /srv/tftp
sudo systemctl enable tftpd-hpa
sudo systemctl restart tftpd-hpa
sudo ufw allow 69/udp
```

## Part 2: Copy files to the kit

### Ubuntu

```bash
cp images/linux/image.ub /srv/tftp/
cp images/linux/u-boot.elf /srv/tftp/
cp images/linux/system.dtb /srv/tftp/
cp boot_dev/boot.scr /srv/tftp/
cp ../hdl/SYSTEM_TOP.bin /srv/tftp/
```

### U-Boot

```
setenv ipaddr 192.168.10.120
saveenv
ping 192.168.10.110

mmc dev 0
mmc rescan
fatls mmc 0:1
tftpboot 0x10000000 192.168.10.110:image.ub
fatwrite mmc 0:1 0x10000000 image.ub ${filesize}
tftpboot 0x10000000 192.168.10.110:u-boot.elf
fatwrite mmc 0:1 0x10000000 u-boot.elf ${filesize}
tftpboot 0x10000000 192.168.10.110:system.dtb
fatwrite mmc 0:1 0x10000000 system.dtb ${filesize}
tftpboot 0x10000000 192.168.10.110:boot.scr
fatwrite mmc 0:1 0x10000000 boot.scr ${filesize}
tftpboot 0x10000000 192.168.10.110:SYSTEM_TOP.bin
fatwrite mmc 0:1 0x10000000 SYSTEM_TOP.bin ${filesize}
fatls mmc 0:1
reset
```

# SCP: copy files to SD (mmcblk0p1) from PetaLinux

## Part 1: Setup after every kit boot

### PetaLinux (login root/root)

```bash
ifconfig eth0 192.168.10.120 up
ping -c 3 192.168.10.110
mkdir -p /mnt/sd
mount /dev/mmcblk0p1 /mnt/sd
```

## Part 2: Copy files to the kit

### Ubuntu

```bash
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null images/linux/image.ub images/linux/u-boot.elf images/linux/system.dtb boot_dev/boot.scr ../hdl/SYSTEM_TOP.bin root@192.168.10.120:/mnt/sd/
```

### PetaLinux

```bash
ls -l /mnt/sd
sync
umount /mnt/sd
reboot
```
