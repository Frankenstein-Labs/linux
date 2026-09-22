SHELL := /bin/bash
.DEFAULT_GOAL := help
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
KERNEL_REPO := https://github.com/Frankenstein-Labs/linux.git
KERNEL_SRC := $(ROOT)/..
KERNEL_BUILD := $(ROOT)/build/kernel
ROOTFS := $(ROOT)/rootfs
ARTIFACTS := $(ROOT)/artifacts
KERNEL_IMAGE := $(KERNEL_BUILD)/arch/x86/boot/bzImage
ISO := $(ARTIFACTS)/cortex-os.iso
.PHONY: help kernel rootfs initramfs run iso run-iso run-iso-uefi clean
help:
	@printf '%s\n' 'CORTEX OS prototype targets:' '  make kernel     Clone/configure/build the Frankenstein-Labs kernel' '  make rootfs     Bootstrap Debian trixie and install KDE Plasma' '  make initramfs  Build a minimal initramfs that switches to rootfs' '  make run        Boot the assembled disk image in QEMU' '  make iso         Build BIOS/UEFI hybrid ISO' '  make run-iso     Boot the ISO in BIOS-mode QEMU' '  make run-iso-uefi Boot the ISO in UEFI-mode QEMU' '  make clean       Remove generated build outputs (not source)'
kernel:
	$(ROOT)/scripts/build-kernel.sh "$(KERNEL_REPO)" "$(KERNEL_SRC)" "$(KERNEL_BUILD)" "$(KERNEL_IMAGE)"
rootfs:
	$(ROOT)/scripts/build-rootfs.sh "$(ROOTFS)"
initramfs: kernel rootfs
	$(ROOT)/scripts/build-initramfs.sh "$(ROOTFS)" "$(KERNEL_BUILD)" "$(ARTIFACTS)"
run: initramfs
	$(ROOT)/scripts/run-qemu.sh "$(KERNEL_IMAGE)" "$(ARTIFACTS)/initramfs.cpio.gz" "$(ROOTFS)"
iso: initramfs
	$(ROOT)/scripts/build-iso.sh
run-iso: iso
	$(ROOT)/scripts/run-iso-qemu.sh "$(ISO)"
run-iso-uefi: iso
	QEMU_UEFI=1 $(ROOT)/scripts/run-iso-qemu.sh "$(ISO)"
clean:
	rm -rf "$(KERNEL_BUILD)" "$(ARTIFACTS)" "$(ROOTFS)"
