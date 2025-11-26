	.file	"bounds.c"
# GNU C11 (Gentoo 15.2.1_p20251108-r1 p2) version 15.2.1 20251108 (x86_64-pc-linux-gnu)
#	compiled by GNU C version 15.2.1 20251108, GMP version 6.3.0, MPFR version 4.2.2, MPC version 1.3.1, isl version none
# GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072
# options passed: -mno-sse -mno-mmx -mno-sse2 -mno-3dnow -mno-avx -mno-sse4a -m64 -mno-80387 -mno-fp-ret-in-387 -mpreferred-stack-boundary=3 -mskip-rax-setup -march=x86-64 -mtune=generic -mno-red-zone -mcmodel=kernel -mstack-protector-guard-reg=gs -mstack-protector-guard-symbol=__ref_stack_chk_guard -mindirect-branch=thunk-extern -mindirect-branch-register -mindirect-branch-cs-prefix -mfunction-return=thunk-extern -mharden-sls=all -mrecord-mcount -mfentry -O2 -std=gnu11 -p -fshort-wchar -funsigned-char -fno-common -fno-PIE -fno-strict-aliasing -fcf-protection=branch -falign-jumps=1 -falign-loops=1 -fno-asynchronous-unwind-tables -fno-jump-tables -fpatchable-function-entry=16,16 -fno-delete-null-pointer-checks -fno-allow-store-data-races -fstack-protector-strong -ftrivial-auto-var-init=zero -fzero-init-padding-bits=all -fno-stack-clash-protection -fno-inline-functions-called-once -fmin-function-alignment=16 -fstrict-flex-arrays=3 -fno-strict-overflow -fstack-check=no -fconserve-stack -fno-builtin-wcslen -foffload-options=-fno-stack-protector -foffload-options=-fcf-protection=none
	.text
	.section	.text.startup,"ax",@progbits
	.align 16
	.globl	main
	.section	__patchable_function_entries,"awo",@progbits,.LPFE217
	.align 8
	.quad	.LPFE217
	.section	.text.startup
.LPFE217:
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
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c:19: 	DEFINE(NR_PAGEFLAGS, __NR_PAGEFLAGS);
#APP
# 19 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c" 1
	
.ascii "->NR_PAGEFLAGS $25 __NR_PAGEFLAGS"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c:20: 	DEFINE(MAX_NR_ZONES, __MAX_NR_ZONES);
# 20 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c" 1
	
.ascii "->MAX_NR_ZONES $5 __MAX_NR_ZONES"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c:22: 	DEFINE(NR_CPUS_BITS, order_base_2(CONFIG_NR_CPUS));
# 22 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c" 1
	
.ascii "->NR_CPUS_BITS $13 order_base_2(CONFIG_NR_CPUS)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c:24: 	DEFINE(SPINLOCK_SIZE, sizeof(spinlock_t));
# 24 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c" 1
	
.ascii "->SPINLOCK_SIZE $4 sizeof(spinlock_t)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c:26: 	DEFINE(LRU_GEN_WIDTH, order_base_2(MAX_NR_GENS + 1));
# 26 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c" 1
	
.ascii "->LRU_GEN_WIDTH $3 order_base_2(MAX_NR_GENS + 1)"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c:27: 	DEFINE(__LRU_REFS_WIDTH, MAX_NR_TIERS - 2);
# 27 "/var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c" 1
	
.ascii "->__LRU_REFS_WIDTH $2 MAX_NR_TIERS - 2"	#
# 0 "" 2
# /var/tmp/portage/sys-kernel/gentoo-kernel-bin-6.17.9/work/linux-6.17/kernel/bounds.c:35: }
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
