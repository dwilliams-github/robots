;
; travel
;
; Mid-level motor driver that uses shaft encoders to control
; the distance of travel and speed of two motors. Watches digital inputs
; for any number of switches that will immediately halt movement.
;
	.section .data
	.align 2
TravelData:
;
; Number 1 kHz clock ticks since beginning of movement. To allow long
; movements, this value is stored in two words.
;
Ticks:
	.word	0			; Least significant word
	.word	0			; Most significant word
;
; The number of shaft transitions (on to off, or off to on) for
; each wheel since the beginning of movement. We only allow up
; to 64K shaft transitions per movement.
;
Shaft:
	.word	0			; Motor 0
	.word	0			; Motor 1
;
; The number of 1 kHz clock ticks since the beginning of movement
; but before the first transition, for each wheel. We assume that
; the motors are fast enough to do this within 64 seconds.
;
StartTicks:
	.word	0			; Motor 0
	.word	0			; Motor 1
;
; The target number of ticks desired
;
Target:
	.word	0			; Both motors
;
; Control byte:
;    0x00 = standby: last request succeeded
;    0x10 = failed: last request failed due to bumper interrupt
;    0x30 = stopped: user request to stop early
;    0x50 = error: last request failed due to program error
;
;    0x01 = request: interrupt routine should start movement.
;                    control words will be cleared by interrupt routine
;    0x03 = active: movement in progress
;
Control:
	.byte	0
;
; Last encoder state. Bit 0 if set if the motor shaft encoder was
; up the last time it was checked. Likewise for Bit 1 and motor 1.
;
LastEncoder:
	.byte 	0
;
	.section .text
;
; ===============
; TravelInit
; ===============
;
; Install timer interrupt service routine
;
	.global TravelInit
TravelInit:
	LDX	#TravelData
	CLR	(Control-TravelData),X		; Clear control byte
	
	LDD	TravelInterrupt
	JMP	TimerInstallUser
;
;
;
TravelInterrupt:
	LDX	#TravelData
	LDA	(Control-TravelData),X		; Load control byte
	BITA	#1				; Are we active?
	BNE	CheckInit
	RTS					; Nope
;
; Check for a request. If there is one, we initialize
; everything, but wait for the following interrupt before
; actually moving
;
CheckInit:
	CMPA	#0x01				; Request?
	BNE	CheckSwitch			; Nope
	
	LDD	#0				; Clear counters
	STD	(Ticks-TravelData),X
	STD	(Ticks-TravelData+2),X
	STD	(Shaft-TravelData),X
	STD	(Shaft-TravelData+2),X
	STD	(StartTicks-TravelData),X
	STD	(StartTicks-TravelData+2),X
	
	LDD	#0x300F				; Turn on motors
	JSR	PWMOn
	
	LDA	#0x03				; Set control
	STA	(Control-TravelData),X
	RTS
;
; Check bumpers
;	
CheckSwitch:
;	LDY	#7000
;	LDA	0,Y				; Load digital input
;	ANDA	

;
; Use PWM on the motors
;
Pulse:
	JSR	PWMInterrupt			; Pulse motors

;
; Increment our 1 kHz counter
;	
TickIncrement:
	LDY	(Ticks-TravelData),X		; Increment ticks
	INY
	STY	(Ticks-TravelData),X
	BNE	CheckTransition
	
	LDY	(Ticks-TravelData+2),X		; Overflow
	INY
	STY	(Ticks-TravelData+2),X
	
CheckTransition: