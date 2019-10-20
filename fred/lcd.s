;
; LCD driver for handyboard
;
; Adapted from "Interactive C" 
; by Randy Sargent, Fred Martin, and Anne Wright
;
	.include "mc68hc11.control.s"
;
LCDCMD_QUERYBUSY = 4
LCDCMD_ASCII 	 = 2
LCDCMD_CMD 	 = 0
;
; ==================
; LCDPrintString
; ==================
; Print the null terminated string pointed to by X
; Very slow!
;
	.section .text
	.global LCDPrintString
LCDPrintString:
	LDD	#0x0002
	JSR	LCDdriver

	LDAA	#2
psloop:
	LDAB	0,X
	BEQ	psloopdone
	JSR	LCDdriver
	INX
	BRA	psloop
psloopdone:
	RTS
;
; =========================
; LCDInit
; =========================
;
; Initialize LCD
;
	.global LCDinit
LCDinit:
	BSR	LCDLoadDriver

	LDD	#0x0038		; 8-bit operation, 2-line display
	JSR	LCDdriver

	LDAB	#0b00001100	; display on, cursor & blink off
	JSR	LCDdriver

	BSR	LCDLoadChars	; Load custom characters

LCDcls:
	LDD	#0x0001		; home and clear screen
	JSR	LCDdriver
	LDAB	#0x06		; set to increment char loc & cursor pos
	JSR	LCDdriver
	LDAB	#0x8F		; put cursor just to right of view window
	JSR	LCDdriver

	RTS
;
; This is a bit of a hack! Copy code to chip ram (0xa0 -- 0xff).
; We could link the code directly to this location, but then
; we would have no simple way to download it (since it would overwrite
; our talker)
;
LCDLoadDriver:
	LDX	#LCDdriverTemplate
	LDY	#LCDdriver
LCDloop:
	LDAA	0,X
	STAA	0,Y
	INX
	INY
	CPX	#LCDenddriverTemplate
	BNE	LCDloop
	RTS
;
; Install custom characters into the LCD controller
;
LCDLoadChars:
	LDD	#0x0040
	JSR	LCDdriver
	
	LDAA	#2
	LDX	#LCDchars
LCDLoadCharLoop:
	LDAB	0,X
	JSR	LCDdriver
	INX	
	CPX	#LCDcharsEnd
	BNE	LCDLoadCharLoop
	
	RTS
;
; Some custom characters
; We're allowed to define up to 16 characters
;
LCDchars:
	.byte	0b00000000
	.byte	0b00001110
	.byte	0b00001110
	.byte	0b00000100
	.byte	0b00000100
	.byte	0b00001110
	.byte	0b00001110
	.byte	0b00000000

	.byte	0b00000000
	.byte	0b00001100
	.byte	0b00011100
	.byte	0b00011100
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00000110
	.byte	0b00000000

	.byte	0b00000000
	.byte	0b00000000
	.byte	0b00010001
	.byte	0b00011111
	.byte	0b00011111
	.byte	0b00010001
	.byte	0b00000000
	.byte	0b00000000

	.byte	0b00000000
	.byte	0b00000110
	.byte	0b00000111
	.byte	0b00000111
	.byte	0b00011100
	.byte	0b00011100
	.byte	0b00001100
	.byte	0b00000000
LCDcharsEnd:

;
; ===========
; LCDdriver
; ===========
; Not to be called here, but rather at address LCDdriver!
; Register A = command, B = data, to be given to LCD
;
; The following code is compiled and linked in one place
; and then copied to on chip ram. This is necessary because
; parts of it runs in single chip mode.
;
; Note that this means we need to be careful with the stack!
;
LCDdriverTemplate:
	PSHX
	LDX	#REGS

	SEI				; disable interrupts
	BCLR	HPRIO,X #0b00100000	; put into single chip mode
	BCLR	PORTA,X #0b00010000	; turn off LCD E line

	CLR	DDRC,X			; make port C input

; if A is query command, just check LCD for busy-ness
	CMPA	#LCDCMD_QUERYBUSY
	BNE	LCDBusy

	LDAA	#1
	STAA	PORTB,X			; read operation from LCD

	BSET	PORTA,X #0b00010000	; frob LCD on
	LDAA	PORTC,X			; get status
	BCLR	PORTA,X #0b00010000	; frob LCD off

	BRA	LCDdriverexit		; exit

LCDBusy:
	STAA	LCDtempbyte		; save A
	LDAA	#1
	STAA	PORTB,X			; read operation from LCD

	BSET	PORTA,X #0b00010000	; frob LCD on
	LDAA	PORTC,X			; get status
	BCLR	PORTA,X #0b00010000	; frob LCD off

	ANDA	#0x80			; bit 7 is busy flag
	BNE	LCDBusy

	DEC	DDRC,X			; make port C output (set value to 0xff)

	LDAA	LCDtempbyte
	STAA	PORTB,X		; high byte is control
	STAB	PORTC,X		; low byte is data

	BSET	PORTA,X #0b00010000
	NOP				; give the LCD a little time
	BCLR	PORTA,X #0b00010000	; frob LCD

LCDdriverexit:
	BSET	HPRIO,X #0b00100000	; put into expanded chip mode

	PULX

LCDdriverCLI:
	CLI				; enable interrupts
	RTS				; return to monitor command loop

LCDenddriverTemplate:
;
; The place in zero page ram to hold the driver routine
;
	.section user0
	.global LCDdriver
LCDdriver:
	.fill (LCDenddriverTemplate-LCDdriverTemplate), 1, 0
LCDtempbyte:
	.byte 0
