	.file	"devicetable-offsets.c"
# GNU C11 (Gentoo 15.2.1_p20251108-r1 p2) version 15.2.1 20251108 (x86_64-pc-linux-gnu)
#	compiled by GNU C version 15.2.1 20251108, GMP version 6.3.0, MPFR version 4.2.2, MPC version 1.3.1, isl version none
# GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072
# options passed: -mno-sse -mno-mmx -mno-sse2 -mno-3dnow -mno-avx -mno-sse4a -m64 -mno-80387 -mno-fp-ret-in-387 -mpreferred-stack-boundary=3 -mskip-rax-setup -march=x86-64 -mtune=generic -mno-red-zone -mcmodel=kernel -mstack-protector-guard-reg=gs -mstack-protector-guard-symbol=__ref_stack_chk_guard -mindirect-branch=thunk-extern -mindirect-branch-register -mindirect-branch-cs-prefix -mfunction-return=thunk-extern -mharden-sls=all -mrecord-mcount -mfentry -O2 -std=gnu11 -p -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -fcf-protection=branch -falign-jumps=1 -falign-loops=1 -fno-asynchronous-unwind-tables -fno-jump-tables -fpatchable-function-entry=16,16 -fno-delete-null-pointer-checks -fno-allow-store-data-races -fstack-protector-strong -ftrivial-auto-var-init=zero -fzero-init-padding-bits=all -fno-stack-clash-protection -fno-inline-functions-called-once -fmin-function-alignment=16 -fstrict-flex-arrays=3 -fno-strict-overflow -fstack-check=no -fconserve-stack -fno-builtin-wcslen -foffload-options=-fno-stack-protector -foffload-options=-fcf-protection=none
	.text
	.section	.text.startup,"ax",@progbits
	.align 16
	.globl	main
	.section	__patchable_function_entries,"awo",@progbits,.LPFE188
	.align 8
	.quad	.LPFE188
	.section	.text.startup
.LPFE188:
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	nop	
	.type	main, @function
main:
	endbr64
1:	call	__fentry__
	.section __mcount_loc, "a",@progbits
	.quad 1b
	.previous
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:11: 	DEVID(usb_device_id);
#APP
# 11 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_usb_device_id $32 sizeof(struct usb_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:12: 	DEVID_FIELD(usb_device_id, match_flags);
# 12 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_match_flags $0 offsetof(struct usb_device_id, match_flags)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:13: 	DEVID_FIELD(usb_device_id, idVendor);
# 13 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_idVendor $2 offsetof(struct usb_device_id, idVendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:14: 	DEVID_FIELD(usb_device_id, idProduct);
# 14 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_idProduct $4 offsetof(struct usb_device_id, idProduct)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:15: 	DEVID_FIELD(usb_device_id, bcdDevice_lo);
# 15 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bcdDevice_lo $6 offsetof(struct usb_device_id, bcdDevice_lo)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:16: 	DEVID_FIELD(usb_device_id, bcdDevice_hi);
# 16 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bcdDevice_hi $8 offsetof(struct usb_device_id, bcdDevice_hi)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:17: 	DEVID_FIELD(usb_device_id, bDeviceClass);
# 17 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bDeviceClass $10 offsetof(struct usb_device_id, bDeviceClass)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:18: 	DEVID_FIELD(usb_device_id, bDeviceSubClass);
# 18 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bDeviceSubClass $11 offsetof(struct usb_device_id, bDeviceSubClass)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:19: 	DEVID_FIELD(usb_device_id, bDeviceProtocol);
# 19 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bDeviceProtocol $12 offsetof(struct usb_device_id, bDeviceProtocol)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:20: 	DEVID_FIELD(usb_device_id, bInterfaceClass);
# 20 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bInterfaceClass $13 offsetof(struct usb_device_id, bInterfaceClass)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:21: 	DEVID_FIELD(usb_device_id, bInterfaceSubClass);
# 21 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bInterfaceSubClass $14 offsetof(struct usb_device_id, bInterfaceSubClass)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:22: 	DEVID_FIELD(usb_device_id, bInterfaceProtocol);
# 22 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bInterfaceProtocol $15 offsetof(struct usb_device_id, bInterfaceProtocol)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:23: 	DEVID_FIELD(usb_device_id, bInterfaceNumber);
# 23 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_usb_device_id_bInterfaceNumber $16 offsetof(struct usb_device_id, bInterfaceNumber)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:25: 	DEVID(hid_device_id);
# 25 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_hid_device_id $24 sizeof(struct hid_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:26: 	DEVID_FIELD(hid_device_id, bus);
# 26 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_hid_device_id_bus $0 offsetof(struct hid_device_id, bus)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:27: 	DEVID_FIELD(hid_device_id, group);
# 27 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_hid_device_id_group $2 offsetof(struct hid_device_id, group)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:28: 	DEVID_FIELD(hid_device_id, vendor);
# 28 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_hid_device_id_vendor $4 offsetof(struct hid_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:29: 	DEVID_FIELD(hid_device_id, product);
# 29 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_hid_device_id_product $8 offsetof(struct hid_device_id, product)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:31: 	DEVID(ieee1394_device_id);
# 31 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_ieee1394_device_id $32 sizeof(struct ieee1394_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:32: 	DEVID_FIELD(ieee1394_device_id, match_flags);
# 32 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ieee1394_device_id_match_flags $0 offsetof(struct ieee1394_device_id, match_flags)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:33: 	DEVID_FIELD(ieee1394_device_id, vendor_id);
# 33 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ieee1394_device_id_vendor_id $4 offsetof(struct ieee1394_device_id, vendor_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:34: 	DEVID_FIELD(ieee1394_device_id, model_id);
# 34 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ieee1394_device_id_model_id $8 offsetof(struct ieee1394_device_id, model_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:35: 	DEVID_FIELD(ieee1394_device_id, specifier_id);
# 35 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ieee1394_device_id_specifier_id $12 offsetof(struct ieee1394_device_id, specifier_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:36: 	DEVID_FIELD(ieee1394_device_id, version);
# 36 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ieee1394_device_id_version $16 offsetof(struct ieee1394_device_id, version)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:38: 	DEVID(pci_device_id);
# 38 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_pci_device_id $40 sizeof(struct pci_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:39: 	DEVID_FIELD(pci_device_id, vendor);
# 39 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pci_device_id_vendor $0 offsetof(struct pci_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:40: 	DEVID_FIELD(pci_device_id, device);
# 40 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pci_device_id_device $4 offsetof(struct pci_device_id, device)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:41: 	DEVID_FIELD(pci_device_id, subvendor);
# 41 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pci_device_id_subvendor $8 offsetof(struct pci_device_id, subvendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:42: 	DEVID_FIELD(pci_device_id, subdevice);
# 42 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pci_device_id_subdevice $12 offsetof(struct pci_device_id, subdevice)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:43: 	DEVID_FIELD(pci_device_id, class);
# 43 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pci_device_id_class $16 offsetof(struct pci_device_id, class)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:44: 	DEVID_FIELD(pci_device_id, class_mask);
# 44 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pci_device_id_class_mask $20 offsetof(struct pci_device_id, class_mask)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:45: 	DEVID_FIELD(pci_device_id, override_only);
# 45 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pci_device_id_override_only $32 offsetof(struct pci_device_id, override_only)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:47: 	DEVID(ccw_device_id);
# 47 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_ccw_device_id $16 sizeof(struct ccw_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:48: 	DEVID_FIELD(ccw_device_id, match_flags);
# 48 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ccw_device_id_match_flags $0 offsetof(struct ccw_device_id, match_flags)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:49: 	DEVID_FIELD(ccw_device_id, cu_type);
# 49 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ccw_device_id_cu_type $2 offsetof(struct ccw_device_id, cu_type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:50: 	DEVID_FIELD(ccw_device_id, cu_model);
# 50 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ccw_device_id_cu_model $6 offsetof(struct ccw_device_id, cu_model)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:51: 	DEVID_FIELD(ccw_device_id, dev_type);
# 51 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ccw_device_id_dev_type $4 offsetof(struct ccw_device_id, dev_type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:52: 	DEVID_FIELD(ccw_device_id, dev_model);
# 52 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ccw_device_id_dev_model $7 offsetof(struct ccw_device_id, dev_model)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:54: 	DEVID(ap_device_id);
# 54 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_ap_device_id $16 sizeof(struct ap_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:55: 	DEVID_FIELD(ap_device_id, dev_type);
# 55 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ap_device_id_dev_type $2 offsetof(struct ap_device_id, dev_type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:57: 	DEVID(css_device_id);
# 57 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_css_device_id $16 sizeof(struct css_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:58: 	DEVID_FIELD(css_device_id, type);
# 58 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_css_device_id_type $1 offsetof(struct css_device_id, type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:60: 	DEVID(serio_device_id);
# 60 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_serio_device_id $4 sizeof(struct serio_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:61: 	DEVID_FIELD(serio_device_id, type);
# 61 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_serio_device_id_type $0 offsetof(struct serio_device_id, type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:62: 	DEVID_FIELD(serio_device_id, proto);
# 62 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_serio_device_id_proto $3 offsetof(struct serio_device_id, proto)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:63: 	DEVID_FIELD(serio_device_id, id);
# 63 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_serio_device_id_id $2 offsetof(struct serio_device_id, id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:64: 	DEVID_FIELD(serio_device_id, extra);
# 64 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_serio_device_id_extra $1 offsetof(struct serio_device_id, extra)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:66: 	DEVID(acpi_device_id);
# 66 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_acpi_device_id $32 sizeof(struct acpi_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:67: 	DEVID_FIELD(acpi_device_id, id);
# 67 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_acpi_device_id_id $0 offsetof(struct acpi_device_id, id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:68: 	DEVID_FIELD(acpi_device_id, cls);
# 68 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_acpi_device_id_cls $24 offsetof(struct acpi_device_id, cls)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:69: 	DEVID_FIELD(acpi_device_id, cls_msk);
# 69 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_acpi_device_id_cls_msk $28 offsetof(struct acpi_device_id, cls_msk)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:71: 	DEVID(pnp_device_id);
# 71 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_pnp_device_id $16 sizeof(struct pnp_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:72: 	DEVID_FIELD(pnp_device_id, id);
# 72 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pnp_device_id_id $0 offsetof(struct pnp_device_id, id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:74: 	DEVID(pnp_card_device_id);
# 74 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_pnp_card_device_id $80 sizeof(struct pnp_card_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:75: 	DEVID_FIELD(pnp_card_device_id, devs);
# 75 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pnp_card_device_id_devs $16 offsetof(struct pnp_card_device_id, devs)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:77: 	DEVID(pcmcia_device_id);
# 77 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_pcmcia_device_id $80 sizeof(struct pcmcia_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:78: 	DEVID_FIELD(pcmcia_device_id, match_flags);
# 78 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pcmcia_device_id_match_flags $0 offsetof(struct pcmcia_device_id, match_flags)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:79: 	DEVID_FIELD(pcmcia_device_id, manf_id);
# 79 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pcmcia_device_id_manf_id $2 offsetof(struct pcmcia_device_id, manf_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:80: 	DEVID_FIELD(pcmcia_device_id, card_id);
# 80 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pcmcia_device_id_card_id $4 offsetof(struct pcmcia_device_id, card_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:81: 	DEVID_FIELD(pcmcia_device_id, func_id);
# 81 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pcmcia_device_id_func_id $6 offsetof(struct pcmcia_device_id, func_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:82: 	DEVID_FIELD(pcmcia_device_id, function);
# 82 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pcmcia_device_id_function $7 offsetof(struct pcmcia_device_id, function)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:83: 	DEVID_FIELD(pcmcia_device_id, device_no);
# 83 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pcmcia_device_id_device_no $8 offsetof(struct pcmcia_device_id, device_no)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:84: 	DEVID_FIELD(pcmcia_device_id, prod_id_hash);
# 84 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_pcmcia_device_id_prod_id_hash $12 offsetof(struct pcmcia_device_id, prod_id_hash)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:86: 	DEVID(of_device_id);
# 86 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_of_device_id $200 sizeof(struct of_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:87: 	DEVID_FIELD(of_device_id, name);
# 87 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_of_device_id_name $0 offsetof(struct of_device_id, name)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:88: 	DEVID_FIELD(of_device_id, type);
# 88 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_of_device_id_type $32 offsetof(struct of_device_id, type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:89: 	DEVID_FIELD(of_device_id, compatible);
# 89 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_of_device_id_compatible $64 offsetof(struct of_device_id, compatible)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:91: 	DEVID(vio_device_id);
# 91 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_vio_device_id $64 sizeof(struct vio_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:92: 	DEVID_FIELD(vio_device_id, type);
# 92 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_vio_device_id_type $0 offsetof(struct vio_device_id, type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:93: 	DEVID_FIELD(vio_device_id, compat);
# 93 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_vio_device_id_compat $32 offsetof(struct vio_device_id, compat)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:95: 	DEVID(input_device_id);
# 95 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_input_device_id $200 sizeof(struct input_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:96: 	DEVID_FIELD(input_device_id, flags);
# 96 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_flags $0 offsetof(struct input_device_id, flags)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:97: 	DEVID_FIELD(input_device_id, bustype);
# 97 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_bustype $8 offsetof(struct input_device_id, bustype)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:98: 	DEVID_FIELD(input_device_id, vendor);
# 98 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_vendor $10 offsetof(struct input_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:99: 	DEVID_FIELD(input_device_id, product);
# 99 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_product $12 offsetof(struct input_device_id, product)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:100: 	DEVID_FIELD(input_device_id, version);
# 100 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_version $14 offsetof(struct input_device_id, version)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:101: 	DEVID_FIELD(input_device_id, evbit);
# 101 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_evbit $16 offsetof(struct input_device_id, evbit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:102: 	DEVID_FIELD(input_device_id, keybit);
# 102 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_keybit $24 offsetof(struct input_device_id, keybit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:103: 	DEVID_FIELD(input_device_id, relbit);
# 103 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_relbit $120 offsetof(struct input_device_id, relbit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:104: 	DEVID_FIELD(input_device_id, absbit);
# 104 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_absbit $128 offsetof(struct input_device_id, absbit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:105: 	DEVID_FIELD(input_device_id, mscbit);
# 105 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_mscbit $136 offsetof(struct input_device_id, mscbit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:106: 	DEVID_FIELD(input_device_id, ledbit);
# 106 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_ledbit $144 offsetof(struct input_device_id, ledbit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:107: 	DEVID_FIELD(input_device_id, sndbit);
# 107 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_sndbit $152 offsetof(struct input_device_id, sndbit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:108: 	DEVID_FIELD(input_device_id, ffbit);
# 108 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_ffbit $160 offsetof(struct input_device_id, ffbit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:109: 	DEVID_FIELD(input_device_id, swbit);
# 109 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_input_device_id_swbit $176 offsetof(struct input_device_id, swbit)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:111: 	DEVID(eisa_device_id);
# 111 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_eisa_device_id $16 sizeof(struct eisa_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:112: 	DEVID_FIELD(eisa_device_id, sig);
# 112 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_eisa_device_id_sig $0 offsetof(struct eisa_device_id, sig)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:114: 	DEVID(parisc_device_id);
# 114 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_parisc_device_id $8 sizeof(struct parisc_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:115: 	DEVID_FIELD(parisc_device_id, hw_type);
# 115 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_parisc_device_id_hw_type $0 offsetof(struct parisc_device_id, hw_type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:116: 	DEVID_FIELD(parisc_device_id, hversion);
# 116 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_parisc_device_id_hversion $2 offsetof(struct parisc_device_id, hversion)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:117: 	DEVID_FIELD(parisc_device_id, hversion_rev);
# 117 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_parisc_device_id_hversion_rev $1 offsetof(struct parisc_device_id, hversion_rev)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:118: 	DEVID_FIELD(parisc_device_id, sversion);
# 118 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_parisc_device_id_sversion $4 offsetof(struct parisc_device_id, sversion)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:120: 	DEVID(sdio_device_id);
# 120 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_sdio_device_id $16 sizeof(struct sdio_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:121: 	DEVID_FIELD(sdio_device_id, class);
# 121 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_sdio_device_id_class $0 offsetof(struct sdio_device_id, class)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:122: 	DEVID_FIELD(sdio_device_id, vendor);
# 122 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_sdio_device_id_vendor $2 offsetof(struct sdio_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:123: 	DEVID_FIELD(sdio_device_id, device);
# 123 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_sdio_device_id_device $4 offsetof(struct sdio_device_id, device)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:125: 	DEVID(ssb_device_id);
# 125 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_ssb_device_id $6 sizeof(struct ssb_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:126: 	DEVID_FIELD(ssb_device_id, vendor);
# 126 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssb_device_id_vendor $0 offsetof(struct ssb_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:127: 	DEVID_FIELD(ssb_device_id, coreid);
# 127 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssb_device_id_coreid $2 offsetof(struct ssb_device_id, coreid)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:128: 	DEVID_FIELD(ssb_device_id, revision);
# 128 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssb_device_id_revision $4 offsetof(struct ssb_device_id, revision)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:130: 	DEVID(bcma_device_id);
# 130 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_bcma_device_id $6 sizeof(struct bcma_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:131: 	DEVID_FIELD(bcma_device_id, manuf);
# 131 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_bcma_device_id_manuf $0 offsetof(struct bcma_device_id, manuf)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:132: 	DEVID_FIELD(bcma_device_id, id);
# 132 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_bcma_device_id_id $2 offsetof(struct bcma_device_id, id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:133: 	DEVID_FIELD(bcma_device_id, rev);
# 133 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_bcma_device_id_rev $4 offsetof(struct bcma_device_id, rev)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:134: 	DEVID_FIELD(bcma_device_id, class);
# 134 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_bcma_device_id_class $5 offsetof(struct bcma_device_id, class)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:136: 	DEVID(virtio_device_id);
# 136 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_virtio_device_id $8 sizeof(struct virtio_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:137: 	DEVID_FIELD(virtio_device_id, device);
# 137 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_virtio_device_id_device $0 offsetof(struct virtio_device_id, device)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:138: 	DEVID_FIELD(virtio_device_id, vendor);
# 138 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_virtio_device_id_vendor $4 offsetof(struct virtio_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:140: 	DEVID(hv_vmbus_device_id);
# 140 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_hv_vmbus_device_id $24 sizeof(struct hv_vmbus_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:141: 	DEVID_FIELD(hv_vmbus_device_id, guid);
# 141 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_hv_vmbus_device_id_guid $0 offsetof(struct hv_vmbus_device_id, guid)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:143: 	DEVID(rpmsg_device_id);
# 143 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_rpmsg_device_id $40 sizeof(struct rpmsg_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:144: 	DEVID_FIELD(rpmsg_device_id, name);
# 144 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_rpmsg_device_id_name $0 offsetof(struct rpmsg_device_id, name)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:146: 	DEVID(i2c_device_id);
# 146 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_i2c_device_id $32 sizeof(struct i2c_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:147: 	DEVID_FIELD(i2c_device_id, name);
# 147 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_i2c_device_id_name $0 offsetof(struct i2c_device_id, name)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:149: 	DEVID(i3c_device_id);
# 149 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_i3c_device_id $16 sizeof(struct i3c_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:150: 	DEVID_FIELD(i3c_device_id, match_flags);
# 150 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_i3c_device_id_match_flags $0 offsetof(struct i3c_device_id, match_flags)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:151: 	DEVID_FIELD(i3c_device_id, dcr);
# 151 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_i3c_device_id_dcr $1 offsetof(struct i3c_device_id, dcr)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:152: 	DEVID_FIELD(i3c_device_id, manuf_id);
# 152 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_i3c_device_id_manuf_id $2 offsetof(struct i3c_device_id, manuf_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:153: 	DEVID_FIELD(i3c_device_id, part_id);
# 153 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_i3c_device_id_part_id $4 offsetof(struct i3c_device_id, part_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:154: 	DEVID_FIELD(i3c_device_id, extra_info);
# 154 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_i3c_device_id_extra_info $6 offsetof(struct i3c_device_id, extra_info)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:156: 	DEVID(slim_device_id);
# 156 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_slim_device_id $16 sizeof(struct slim_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:157: 	DEVID_FIELD(slim_device_id, manf_id);
# 157 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_slim_device_id_manf_id $0 offsetof(struct slim_device_id, manf_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:158: 	DEVID_FIELD(slim_device_id, prod_code);
# 158 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_slim_device_id_prod_code $2 offsetof(struct slim_device_id, prod_code)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:160: 	DEVID(spi_device_id);
# 160 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_spi_device_id $40 sizeof(struct spi_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:161: 	DEVID_FIELD(spi_device_id, name);
# 161 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_spi_device_id_name $0 offsetof(struct spi_device_id, name)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:163: 	DEVID(dmi_system_id);
# 163 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_dmi_system_id $344 sizeof(struct dmi_system_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:164: 	DEVID_FIELD(dmi_system_id, matches);
# 164 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_dmi_system_id_matches $16 offsetof(struct dmi_system_id, matches)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:166: 	DEVID(platform_device_id);
# 166 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_platform_device_id $32 sizeof(struct platform_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:167: 	DEVID_FIELD(platform_device_id, name);
# 167 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_platform_device_id_name $0 offsetof(struct platform_device_id, name)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:169: 	DEVID(mdio_device_id);
# 169 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_mdio_device_id $8 sizeof(struct mdio_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:170: 	DEVID_FIELD(mdio_device_id, phy_id);
# 170 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_mdio_device_id_phy_id $0 offsetof(struct mdio_device_id, phy_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:171: 	DEVID_FIELD(mdio_device_id, phy_id_mask);
# 171 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_mdio_device_id_phy_id_mask $4 offsetof(struct mdio_device_id, phy_id_mask)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:173: 	DEVID(zorro_device_id);
# 173 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_zorro_device_id $16 sizeof(struct zorro_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:174: 	DEVID_FIELD(zorro_device_id, id);
# 174 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_zorro_device_id_id $0 offsetof(struct zorro_device_id, id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:176: 	DEVID(isapnp_device_id);
# 176 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_isapnp_device_id $16 sizeof(struct isapnp_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:177: 	DEVID_FIELD(isapnp_device_id, vendor);
# 177 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_isapnp_device_id_vendor $4 offsetof(struct isapnp_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:178: 	DEVID_FIELD(isapnp_device_id, function);
# 178 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_isapnp_device_id_function $6 offsetof(struct isapnp_device_id, function)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:180: 	DEVID(ipack_device_id);
# 180 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_ipack_device_id $12 sizeof(struct ipack_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:181: 	DEVID_FIELD(ipack_device_id, format);
# 181 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ipack_device_id_format $0 offsetof(struct ipack_device_id, format)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:182: 	DEVID_FIELD(ipack_device_id, vendor);
# 182 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ipack_device_id_vendor $4 offsetof(struct ipack_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:183: 	DEVID_FIELD(ipack_device_id, device);
# 183 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ipack_device_id_device $8 offsetof(struct ipack_device_id, device)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:185: 	DEVID(amba_id);
# 185 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_amba_id $16 sizeof(struct amba_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:186: 	DEVID_FIELD(amba_id, id);
# 186 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_amba_id_id $0 offsetof(struct amba_id, id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:187: 	DEVID_FIELD(amba_id, mask);
# 187 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_amba_id_mask $4 offsetof(struct amba_id, mask)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:189: 	DEVID(mips_cdmm_device_id);
# 189 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_mips_cdmm_device_id $1 sizeof(struct mips_cdmm_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:190: 	DEVID_FIELD(mips_cdmm_device_id, type);
# 190 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_mips_cdmm_device_id_type $0 offsetof(struct mips_cdmm_device_id, type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:192: 	DEVID(x86_cpu_id);
# 192 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_x86_cpu_id $24 sizeof(struct x86_cpu_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:193: 	DEVID_FIELD(x86_cpu_id, feature);
# 193 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_x86_cpu_id_feature $8 offsetof(struct x86_cpu_id, feature)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:194: 	DEVID_FIELD(x86_cpu_id, family);
# 194 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_x86_cpu_id_family $2 offsetof(struct x86_cpu_id, family)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:195: 	DEVID_FIELD(x86_cpu_id, model);
# 195 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_x86_cpu_id_model $4 offsetof(struct x86_cpu_id, model)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:196: 	DEVID_FIELD(x86_cpu_id, vendor);
# 196 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_x86_cpu_id_vendor $0 offsetof(struct x86_cpu_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:198: 	DEVID(cpu_feature);
# 198 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_cpu_feature $2 sizeof(struct cpu_feature)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:199: 	DEVID_FIELD(cpu_feature, feature);
# 199 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_cpu_feature_feature $0 offsetof(struct cpu_feature, feature)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:201: 	DEVID(mei_cl_device_id);
# 201 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_mei_cl_device_id $64 sizeof(struct mei_cl_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:202: 	DEVID_FIELD(mei_cl_device_id, name);
# 202 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_mei_cl_device_id_name $0 offsetof(struct mei_cl_device_id, name)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:203: 	DEVID_FIELD(mei_cl_device_id, uuid);
# 203 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_mei_cl_device_id_uuid $32 offsetof(struct mei_cl_device_id, uuid)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:204: 	DEVID_FIELD(mei_cl_device_id, version);
# 204 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_mei_cl_device_id_version $48 offsetof(struct mei_cl_device_id, version)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:206: 	DEVID(rio_device_id);
# 206 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_rio_device_id $8 sizeof(struct rio_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:207: 	DEVID_FIELD(rio_device_id, did);
# 207 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_rio_device_id_did $0 offsetof(struct rio_device_id, did)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:208: 	DEVID_FIELD(rio_device_id, vid);
# 208 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_rio_device_id_vid $2 offsetof(struct rio_device_id, vid)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:209: 	DEVID_FIELD(rio_device_id, asm_did);
# 209 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_rio_device_id_asm_did $4 offsetof(struct rio_device_id, asm_did)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:210: 	DEVID_FIELD(rio_device_id, asm_vid);
# 210 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_rio_device_id_asm_vid $6 offsetof(struct rio_device_id, asm_vid)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:212: 	DEVID(ulpi_device_id);
# 212 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_ulpi_device_id $16 sizeof(struct ulpi_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:213: 	DEVID_FIELD(ulpi_device_id, vendor);
# 213 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ulpi_device_id_vendor $0 offsetof(struct ulpi_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:214: 	DEVID_FIELD(ulpi_device_id, product);
# 214 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ulpi_device_id_product $2 offsetof(struct ulpi_device_id, product)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:216: 	DEVID(hda_device_id);
# 216 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_hda_device_id $32 sizeof(struct hda_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:217: 	DEVID_FIELD(hda_device_id, vendor_id);
# 217 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_hda_device_id_vendor_id $0 offsetof(struct hda_device_id, vendor_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:218: 	DEVID_FIELD(hda_device_id, rev_id);
# 218 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_hda_device_id_rev_id $4 offsetof(struct hda_device_id, rev_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:219: 	DEVID_FIELD(hda_device_id, api_version);
# 219 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_hda_device_id_api_version $8 offsetof(struct hda_device_id, api_version)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:221: 	DEVID(sdw_device_id);
# 221 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_sdw_device_id $16 sizeof(struct sdw_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:222: 	DEVID_FIELD(sdw_device_id, mfg_id);
# 222 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_sdw_device_id_mfg_id $0 offsetof(struct sdw_device_id, mfg_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:223: 	DEVID_FIELD(sdw_device_id, part_id);
# 223 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_sdw_device_id_part_id $2 offsetof(struct sdw_device_id, part_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:224: 	DEVID_FIELD(sdw_device_id, sdw_version);
# 224 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_sdw_device_id_sdw_version $4 offsetof(struct sdw_device_id, sdw_version)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:225: 	DEVID_FIELD(sdw_device_id, class_id);
# 225 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_sdw_device_id_class_id $5 offsetof(struct sdw_device_id, class_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:227: 	DEVID(fsl_mc_device_id);
# 227 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_fsl_mc_device_id $18 sizeof(struct fsl_mc_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:228: 	DEVID_FIELD(fsl_mc_device_id, vendor);
# 228 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_fsl_mc_device_id_vendor $0 offsetof(struct fsl_mc_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:229: 	DEVID_FIELD(fsl_mc_device_id, obj_type);
# 229 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_fsl_mc_device_id_obj_type $2 offsetof(struct fsl_mc_device_id, obj_type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:231: 	DEVID(tb_service_id);
# 231 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_tb_service_id $40 sizeof(struct tb_service_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:232: 	DEVID_FIELD(tb_service_id, match_flags);
# 232 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_tb_service_id_match_flags $0 offsetof(struct tb_service_id, match_flags)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:233: 	DEVID_FIELD(tb_service_id, protocol_key);
# 233 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_tb_service_id_protocol_key $4 offsetof(struct tb_service_id, protocol_key)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:234: 	DEVID_FIELD(tb_service_id, protocol_id);
# 234 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_tb_service_id_protocol_id $16 offsetof(struct tb_service_id, protocol_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:235: 	DEVID_FIELD(tb_service_id, protocol_version);
# 235 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_tb_service_id_protocol_version $20 offsetof(struct tb_service_id, protocol_version)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:236: 	DEVID_FIELD(tb_service_id, protocol_revision);
# 236 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_tb_service_id_protocol_revision $24 offsetof(struct tb_service_id, protocol_revision)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:238: 	DEVID(typec_device_id);
# 238 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_typec_device_id $16 sizeof(struct typec_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:239: 	DEVID_FIELD(typec_device_id, svid);
# 239 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_typec_device_id_svid $0 offsetof(struct typec_device_id, svid)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:241: 	DEVID(tee_client_device_id);
# 241 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_tee_client_device_id $16 sizeof(struct tee_client_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:242: 	DEVID_FIELD(tee_client_device_id, uuid);
# 242 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_tee_client_device_id_uuid $0 offsetof(struct tee_client_device_id, uuid)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:244: 	DEVID(wmi_device_id);
# 244 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_wmi_device_id $48 sizeof(struct wmi_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:245: 	DEVID_FIELD(wmi_device_id, guid_string);
# 245 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_wmi_device_id_guid_string $0 offsetof(struct wmi_device_id, guid_string)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:247: 	DEVID(mhi_device_id);
# 247 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_mhi_device_id $40 sizeof(struct mhi_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:248: 	DEVID_FIELD(mhi_device_id, chan);
# 248 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_mhi_device_id_chan $0 offsetof(struct mhi_device_id, chan)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:250: 	DEVID(auxiliary_device_id);
# 250 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_auxiliary_device_id $40 sizeof(struct auxiliary_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:251: 	DEVID_FIELD(auxiliary_device_id, name);
# 251 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_auxiliary_device_id_name $0 offsetof(struct auxiliary_device_id, name)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:253: 	DEVID(ssam_device_id);
# 253 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_ssam_device_id $16 sizeof(struct ssam_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:254: 	DEVID_FIELD(ssam_device_id, match_flags);
# 254 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssam_device_id_match_flags $0 offsetof(struct ssam_device_id, match_flags)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:255: 	DEVID_FIELD(ssam_device_id, domain);
# 255 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssam_device_id_domain $1 offsetof(struct ssam_device_id, domain)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:256: 	DEVID_FIELD(ssam_device_id, category);
# 256 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssam_device_id_category $2 offsetof(struct ssam_device_id, category)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:257: 	DEVID_FIELD(ssam_device_id, target);
# 257 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssam_device_id_target $3 offsetof(struct ssam_device_id, target)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:258: 	DEVID_FIELD(ssam_device_id, instance);
# 258 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssam_device_id_instance $4 offsetof(struct ssam_device_id, instance)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:259: 	DEVID_FIELD(ssam_device_id, function);
# 259 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ssam_device_id_function $5 offsetof(struct ssam_device_id, function)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:261: 	DEVID(dfl_device_id);
# 261 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_dfl_device_id $16 sizeof(struct dfl_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:262: 	DEVID_FIELD(dfl_device_id, type);
# 262 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_dfl_device_id_type $0 offsetof(struct dfl_device_id, type)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:263: 	DEVID_FIELD(dfl_device_id, feature_id);
# 263 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_dfl_device_id_feature_id $2 offsetof(struct dfl_device_id, feature_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:265: 	DEVID(ishtp_device_id);
# 265 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_ishtp_device_id $24 sizeof(struct ishtp_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:266: 	DEVID_FIELD(ishtp_device_id, guid);
# 266 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_ishtp_device_id_guid $0 offsetof(struct ishtp_device_id, guid)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:268: 	DEVID(cdx_device_id);
# 268 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_cdx_device_id $20 sizeof(struct cdx_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:269: 	DEVID_FIELD(cdx_device_id, vendor);
# 269 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_cdx_device_id_vendor $0 offsetof(struct cdx_device_id, vendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:270: 	DEVID_FIELD(cdx_device_id, device);
# 270 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_cdx_device_id_device $2 offsetof(struct cdx_device_id, device)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:271: 	DEVID_FIELD(cdx_device_id, subvendor);
# 271 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_cdx_device_id_subvendor $4 offsetof(struct cdx_device_id, subvendor)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:272: 	DEVID_FIELD(cdx_device_id, subdevice);
# 272 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_cdx_device_id_subdevice $6 offsetof(struct cdx_device_id, subdevice)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:273: 	DEVID_FIELD(cdx_device_id, class);
# 273 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_cdx_device_id_class $8 offsetof(struct cdx_device_id, class)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:274: 	DEVID_FIELD(cdx_device_id, class_mask);
# 274 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_cdx_device_id_class_mask $12 offsetof(struct cdx_device_id, class_mask)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:275: 	DEVID_FIELD(cdx_device_id, override_only);
# 275 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_cdx_device_id_override_only $16 offsetof(struct cdx_device_id, override_only)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:277: 	DEVID(vchiq_device_id);
# 277 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_vchiq_device_id $32 sizeof(struct vchiq_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:278: 	DEVID_FIELD(vchiq_device_id, name);
# 278 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_vchiq_device_id_name $0 offsetof(struct vchiq_device_id, name)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:280: 	DEVID(coreboot_device_id);
# 280 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->SIZE_coreboot_device_id $16 sizeof(struct coreboot_device_id)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:281: 	DEVID_FIELD(coreboot_device_id, tag);
# 281 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c" 1
	
.ascii "->OFF_coreboot_device_id_tag $0 offsetof(struct coreboot_device_id, tag)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/scripts/mod/devicetable-offsets.c:284: }
#NO_APP
	xorl	%eax, %eax	#
	jmp	__x86_return_thunk
	.size	main, .-main
	.ident	"GCC: (Gentoo 15.2.1_p20251108-r1 p2) 15.2.1 20251108"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	1f - 0f
	.long	4f - 1f
	.long	5
0:
	.string	"GNU"
1:
	.align 8
	.long	0xc0000002
	.long	3f - 2f
2:
	.long	0x1
3:
	.align 8
4:
