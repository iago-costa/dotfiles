lsblk
sudo mkfs.fat -F 32 /dev/nvme0n1p1
sudo fatlabel /dev/nvme0n1p1 NIXBOOT
sudo mkfs.ext4 /dev/nvme0n1p2 -L NIXROOT
sudo mount /dev/disk/by-label/NIXROOT /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot

sudo umount /mnt/boot -f
sudo umount /mnt -f

sudo fdisk /dev/nvme0n1
