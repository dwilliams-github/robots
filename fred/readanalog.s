;
; Test analog input 6
;
	.include "mc68hc11.control.s"
;
	.section .text
	.global ReadAnalog6
ReadAnalog6:
	PSHX
	PSHA
	LDX	#REGS
	LDAA	#0
	SEI
	STAA	ADCTL,x
	
Wait:
	LDAA	ADCTL,X
	ANDA	#0x80
	BEQ	Wait
	
	CLI
	LDAA	ADR1,X
	STAA	Analog6
	
	PULA
	PULX
	RTS
;
	.section .data
	.global Analog6
Analog6:
	.byte	0
