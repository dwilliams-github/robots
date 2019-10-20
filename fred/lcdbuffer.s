;
; LcdBuffer
;
; Implement memory area that is buffered to the LCD
;
LCDCMD_QUERYBUSY = 4
LCDCMD_ASCII     = 2
;
; Our buffer, which we'll boldly make global.
; It would be a bad thing if an application writes
; beyond its length
;
	.section .data
	.align 2
	.global LCDBuffer
LCDBuffer:
	.fill	0x20, 1, 0
;
; LCDCursorPos
;
; Current position of cursor
;	0x00 - 0x0f	place on first line
;       0x10		off right side of first line
;	0x20 - 0x2f	place on second line
;	0x30		off right side of second line
LCDCursorPos:
	.byte	0
;
;
;
	.section .text
;
; =============
; LCDBufferInit
; =============
; Install LCDBuffer 1 kHz interrupt
;
	.global LCDBufferInit
LCDBufferInit:
;
; Clear buffer
;
	LDAA	#' '				; Fill with spaces, not zeros!
	LDX	#LCDBuffer
ClearBuffer:
	STAA	0,X
	INX
	CPX	#(LCDBuffer+0x20)
	BNE	ClearBuffer
;
; Install interrupt and return
;
	LDD	#LCDBufferInterrupt	
	JMP	TimerInstallUser
;
; =============
; LCDBufferInterrupt
; =============
LCDBufferInterrupt:
;
; Update spinning wheel
;
	LDAA	TimerClock+1
	LSRA
	LSRA
	ANDA	#0x03
	STAA	LCDBuffer+0x1f
;
; Check if LCD is busy. If so, wait until next time.
;
	LDAA	#LCDCMD_QUERYBUSY		; Busy?
	JSR	LCDdriver
	ANDA	#0x80
	BEQ	CheckBuffer			; No: go on
	RTS					; Yes: return now
CheckBuffer:
;
; Fetch cursor position
;
	LDAB	LCDCursorPos			; Cursor position
	CMPB	#0x10				; 0x10 is overflow
	BHI	SecondLine			; We must be on the 2nd line		
	BEQ	OffTop				; We have overflowing on 1st line
	
	LDX	#LCDBuffer			; First line: set base address
	BRA	WriteCharacter
OffTop:
;
; We've fallen off the top right edge. 
; Set cursor to lower right, and set counter to 20
;
	LDD	#0x00C0
	JSR	LCDdriver
	LDAA	#0x20
	STAA	LCDCursorPos
	RTS
SecondLine:
	CMPB	#0x30				; Indication of second overflow
	BNE	NotOffBottom
;
; We've fallen off the bottom right edge. 
; Home cursor, and set counter to zero
;
	LDD	#0x0002
	JSR	LCDdriver
	CLR	LCDCursorPos
	RTS
NotOffBottom:
;
; Character on 2nd row
;
	LDX	#(LCDBuffer-0x10);		; Second line: set base address minus 0x10
WriteCharacter:
;
; Write character
;
	ABX					; Add cursor position to buffer address

	INCB					; Increment cursor position
	STAB	LCDCursorPos			; 	and store it

	LDAB	0,X				; Fetch character
;	LDAB	#0x21
	LDAA	#LCDCMD_ASCII			; Command is "WRITE"
	JMP	LCDdriver			; Write it to the LCD and return
	