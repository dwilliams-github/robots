;;;-----------------------------------------
;;; Start MC68HC11 gcc assembly output
;;; gcc compiler 3.0.1
;;; Command:	/usr/local/lib/gcc-lib/m6811-elf/3.0.1/cc1 -lang-c -D__GNUC__=3 -D__GNUC_MINOR__=0 -D__GNUC_PATCHLEVEL__=1 -Dmc68hc1x -D__mc68hc1x__ -D__mc68hc1x -D__CHAR_UNSIGNED__ -D__NO_INLINE__ -D__STDC_HOSTED__=1 -D__HAVE_SHORT_INT__ -D__INT__=16 -D__INT_MAX__=32767 -Dmc6811 -DMC6811 -Dmc68hc11 flash.c -quiet -dumpbase flash.c -m68hc11 -mshort -o flash.s
;;; Compiled:	Sat Sep  1 17:35:22 2001
;;; (META)compiled by GNU C version Apple DevKit-based CPP 6.0alpha.
;;;-----------------------------------------
	.file	"flash.c"
	.sect	.text
	.globl	main
	.type	main,@function
main:
	ldx	*_.frame
	pshx
	tsx
	xgdx
	addd	#-10
	xgdx
	txs
	sts	*_.frame
	ldx	*_.d1
	pshx
	ldd	#4096
	ldx	*_.frame
	std	7,x
	ldy	*_.frame
	clr	2,y
	clr	1,y
.L2:
	ldx	*_.frame
	ldx	1,x
	cpx	#99
	ble	.L5
	bra	.L3
.L5:
	ldy	*_.frame
	ldx	7,y
	ldab	#64
	stab	0,x
	clr	4,y
	clr	3,y
.L6:
	ldy	*_.frame
	ldx	1,y
	pshx
	pula
	pulb
	asld
	std	9,y
	ldd	9,y
	stx	*_.tmp
	addd	*_.tmp
	std	9,y
	ldd	9,y
	asld
	asld
	asld
	asld
	asld
	std	*_.d1
	addd	9,y
	std	9,y
	ldd	9,y
	stx	*_.tmp
	addd	*_.tmp
	ldx	*_.frame
	cpd	3,x
	bgt	.L8
	bra	.L7
.L8:
	ldy	*_.frame
	ldd	3,y
	addd	#1
	ldx	*_.frame
	std	3,x
	bra	.L6
.L7:
	ldy	*_.frame
	ldx	7,y
	clr	0,x
	ldx	*_.frame
	clr	4,x
	clr	3,x
.L10:
	ldy	*_.frame
	ldx	1,y
	pshx
	pula
	pulb
	asld
	std	9,y
	ldd	9,y
	stx	*_.tmp
	addd	*_.tmp
	std	9,y
	ldd	9,y
	asld
	asld
	asld
	asld
	asld
	std	*_.d1
	addd	9,y
	std	9,y
	ldd	9,y
	stx	*_.tmp
	addd	*_.tmp
	ldx	*_.frame
	cpd	3,x
	bgt	.L12
	ldd	1,y
	addd	#1
	std	1,x
	bra	.L2
.L12:
	ldy	*_.frame
	ldd	3,y
	addd	#1
	ldx	*_.frame
	std	3,x
	bra	.L10
.L3:
	pulx
	stx	*_.d1
	tsx
	xgdx
	addd	#10
	xgdx
	txs
	pulx
	stx	*_.frame
	rts
.Lfe1:
	.size	main,.Lfe1-main
	.ident	"GCC: (GNU) 3.0.1"
