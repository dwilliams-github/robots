;
; timer.s
;
; Implement 1 kHz interrupt service
;
; Based in part on interactive C pcode
;
	.include "mc68hc11.control.s"
	.include "mc68hc11.vector.s"
;
; Our interrupt service vector table, with space for up to 20 routines
;
MAX_ROUTINE = 20;
;
; Timer data
;
	.section .data
TimerRoutines:
	.fill 	MAX_ROUTINE, 2, 0		; Subroutine call table
	
	.section .user0
	.global TimerClock
TimerClock:
	.word 	0				; lower byte of 32 bit clock
	.word 	0				; upper byte of 32 bit clock

;
; ===========
; TimerInit
; ===========
; Install interrupt service routine
;
	.section .text
	.global TimerInit
TimerInit:
	SEI					; Disable interrupts

	CLR	*TimerClock
	CLR	*TimerClock+2
;
; Zero the process table
;
	LDX 	#TimerRoutines
ZeroTable:
	CLR 	0,x				
	INX
	CPX 	#(TimerRoutines+2*MAX_ROUTINE)
	BNE 	ZeroTable
;
; Install system timer interrupt
;	
	LDX 	#VECTOR_BASE
	LDD 	#TimerInterrupt
	STD 	TOC4INT,X			; Load interrupt routine
;
; Configure timing control
;		
	LDX 	#REGS
	CLR	TMSK2,X 			; Initialize timing control to default
	
	BSET	TFLG1,X #0b00010000		; clear pending flag
	BSET	TMSK1,X #0b00010000		; enable interrupt
	
	CLI					; enable interrupts
	RTS
;
; ===============
; TimerInstallUser
; ===============
; Install a user timer routine
;
; Register D should contain the address of the user routine
; that will be invoked at 1 kHz. This routine should return
; with an ordinary RTS. 
;
; A zero value of X on return indicates success.
; A non-zero value on return indicates failure (table is full)
;
	.global TimerInstallUser
TimerInstallUser:
	LDX 	#TimerRoutines
CallTableSearch:
	TST	0,X				
	BNE	SlotFull		; Zero indicates no routine
	INX
	TST	0,X
	BNE	SlotFull
;
; Empty spot found: fill it
;
	DEX
	STD	0,X
	LDX	#0			; Indicate success
	RTS				; Finished!
SlotFull:
	INX
	CPX 	#(TimerRoutines+2*MAX_ROUTINE)
	BNE 	CallTableSearch
;
; If we are here, our table is full!!!
;
	LDX	#1
	RTS
	
	
; ===============
; TimerInterrupt
; ===============

TimerInterrupt:
;
; Re-enable interrupt for next time
;	
	LDX	#REGS
	LDD	#2000			; 1 millisecond
	ADDD	TOC4,X			; Add to current time
	STD	TOC4,X			; Put back
	BCLR	TFLG1,X #0b11101111	; Clear interrupt flag
;
; Increment our own 1 kHz 32 bit clock
;
	LDX	TimerClock		; Timer lower byte
	INX
	STX	TimerClock
	BNE	TimerUnder		; Overflow
	LDX	TimerClock+2		; Timer upper byte
	INX
	STX	TimerClock+2
TimerUnder:
;
; Call interrupt service routines
;
	LDX 	#TimerRoutines
CallTable:
	LDY	0,X				
	BEQ	NoRoutine		; Zero indicates no routine
	PSHX				; Save register
	JSR	0,Y			; Call user routine
	PULX
NoRoutine:
	INX
	INX
	CPX 	#(TimerRoutines+2*MAX_ROUTINE)
	BNE 	CallTable
;
	RTI
