;
; mc68hc11 interrupt vectors
;
VECTOR_BASE 	=	0xbf00		; Base address (in special test mode)

SCIINT		=	0xD6	; SCI serial system
SPIINT		=	0xD8	; SPI serial system
PAIINT  	=	0xDA	; Pulse Accumulator Input Edge
PAOVINT 	=	0xDC	; Pulse Accumulator Overflow
TOINT		=	0xDE	; Timer Overflow
TOC5INT		=	0xE0	; Timer Output Compare 5
TOC4INT		=	0xE2	; Timer Output Compare 4
TOC3INT		=	0xE4	; Timer Output Compare 3
TOC2INT		=	0xE6	; Timer Output Compare 2
TOC1INT		=	0xE8	; Timer Output Compare 1
TIC3INT		=	0xEA	; Timer Input Capture 3
TIC2INT		=	0xEC	; Timer Input Capture 2
TIC1INT		=	0xEE	; Timer Input Capture 1
RTIINT		=	0xF0	; Real Time Interrupt
IRQINT		=	0xF2	; IRQ External Interrupt
XIRQINT		=	0xF4	; XIRQ External Interrupt
SWIINT		=	0xF6	; Software Interrupt
BADOPINT 	=	0xF8	; Illegal Opcode Trap Interrupt
NOCOPINT 	=	0xFA	; COP Failure (Reset)
CMEINT		=	0xFC	; COP Clock Monitor Fail (Reset)
RESETINT 	=	0xFE	; RESET Interrupt
