# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=ThdKernel-%KV% by Javinator9889 (for Mi A1/tissot)
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=tissot
supported.versions=10
supported.patchlevels=
'; } # end properties

# shell variables
block=/dev/block/platform/soc/7824900.sdhci/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

set_progress 0.1;
ui_print " | Setting-up permissions";

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;
ui_print " | L Done!";
sleep 0.5;

ui_print " | Dumping boot partition...";
## AnyKernel install
dump_boot;
ui_print " | L Done!";
sleep 0.5;

# begin ramdisk changes

ui_print " | Patching ramdisk...";
ui_print " | L Patching init.rc";
# init.rc
backup_file init.rc;
replace_string init.rc "cpuctl cpu,timer_slack" "mount cgroup none /dev/cpuctl cpu" "mount cgroup none /dev/cpuctl cpu,timer_slack";
set_progress 0.53;

ui_print " | L Patching init.tuna.rc";
# init.tuna.rc
backup_file init.tuna.rc;
insert_line init.tuna.rc "nodiratime barrier=0" after "mount_all /fstab.tuna" "\tmount ext4 /dev/block/platform/omap/omap_hsmmc.0/by-name/userdata /data remount nosuid nodev noatime nodiratime barrier=0";
append_file init.tuna.rc "bootscript" init.tuna;
set_progress 0.57;

ui_print " | L Patching fstab";
# fstab.tuna
backup_file fstab.tuna;
patch_fstab fstab.tuna /system ext4 options "noatime,barrier=1" "noatime,nodiratime,barrier=0";
patch_fstab fstab.tuna /cache ext4 options "barrier=1" "barrier=0,nomblk_io_submit";
patch_fstab fstab.tuna /data ext4 options "data=ordered" "nomblk_io_submit,data=writeback";
append_file fstab.tuna "usbdisk" fstab;
set_progress 0.6;

ui_print " | L Patching SEPolicy";
# sepolicy
$bin/magiskpolicy --load sepolicy --save sepolicy \
  "allow init rootfs file execute_no_trans" \
;
set_progress 0.62;
ui_print " | L Patching ramdisk done!";
sleep 0.5

# If the kernel image and dtbs are separated in the zip
decompressed_image=/tmp/anykernel/kernel/Image
compressed_image=$decompressed_image.gz
if [ -f $compressed_image ]; then
  ui_print " | Checking for Project Treble status";
  if [ "$(file_getprop /system_root/system/build.prop ro.treble.enabled)" = "true" ]; then
    ui_print " | L Treble is enabled";
    dtb=/tmp/anykernel/dtb-treble;
  else
    ui_print " | L Treble is not enabled";
    dtb=/tmp/anykernel/dtb-nontreble;
  fi;
  set_progress 0.65;

  ui_print " | L Including the required DTB files to the kernel";
  # Concatenate all of the dtbs to the kernel
  cat $compressed_image $dtb/*.dtb > /tmp/anykernel/Image.gz-dtb;
  ui_print " | L Done!";
  sleep 0.5;
fi

# end ramdisk changes

ui_print " | Installing ThdKernel-%KV% to the device...";
write_boot;
## end install
set_progress 1;
ui_print " | L ThdKernel-%KV% has been sucessfully installed!";
sleep 0.5;

