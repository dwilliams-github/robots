;
; PWM motor driver
;
; Based in part on code from interactive c, created by
;           Randy Sargent
;           Fred Martin
;           Anne Wright
; and from a port of the handyboard library, created by
;           Curt Mills
;           Ken Hornstein
;           Carlos Puchol
; and probably others
;
	.section .data
;
; Bit encoded motor control byte. This is the value
; that would be stored at address 0x7000 to activate
; the motors. The actual writing is done by the
; interrupt routine.
;
; Bit definitions:
;        0-3   - If set, motor runs backwards
;        4-7   - Enable motors 0-3
;
PWMControl:
	.byte	0
;
; Current pwm bit encoded words, one for each motor, rotated
; at 1 kHz by the interrupt routine
;
	.align 2
PWMValues:
	.word 0
	.word 0
	.word 0
	.word 0
;
	.section .text
;
; Starting values for the 16 bit PWM bit encoded words
;
PWMTable:
	.word	0b0000000000000000	; 0/16
	.word	0b0000000000000001	; 1/16
	.word	0b0000000100000001	; 2/16
	.word	0b0000100001000010	; 3/16
	.word	0b0001000100010001	; 4/16
	.word	0b0010001001001001	; 5/16
	.word	0b0100100100101001	; 6/16
	.word	0b0101001010101010	; 7/16
	.word	0b0101010101010101	; 8/16
	.word	0b1010101010101011	; 9/16
	.word	0b0101011010101011	; 10/16
	.word	0b1101110110110110	; 11/16
	.word	0b1110111011101110	; 12/16
	.word	0b1110111011101111	; 13/16
	.word	0b1110111111101111	; 14/16
	.word	0b1111111011111111	; 15/16
	.word	0b1111111111111111	; 16/16
;
; ==============
; PWMInit
; ==============
; Initialize
;
	.global PWMInit
PWMInit:
;
; Stop motors and clear control
;
	CLR	0x7000
	CLR	PWMControl
;
; Install timer interrupt
;
	LDD	#PWMInterrupt
	JMP 	TimerInstallUser
;
; ==============
; PWMKillNow
; ==============
; Immediately stop the motors (don't wait for interrupt)
;
	.global PWMKillNow
PWMKillNow:
	CLR	PWMControl		; Do this first, in case of an interrupt
	CLR	0x7000
	RTS
;
; ==============
; PWMOnFree
; ==============
; Call PWMOn from c code, with signature:
;         void PWMOnFree( unsigned char encoding, unsigned char speed );
;
	.global PWMOnFree
PWMOnFree:
	TBA				; First parameter is in register B
	TSX
	LDAB	4,X			; Second parameter on stack

;	BRA PWMOn			; Do stuff
;
; ==============
; PWMOn
; ==============
; Turn on a set of motors to a specific speed and direction.
; Does not turn off any motors.
;      Register A: bit encoding: same as PWMControl
;      Register B: speed, from 0 to 15
;
; Destroys register X, A, and B
;
	.global PWMOn
PWMOn:
;
; Get index into PWM table and store in Y
;
	CMPB	#0x0f			; Set at max or higher?
	BLO	FindIndex		; No, calculate index
	LDX	#PWMTable+15*2		; Yes, set index to Max speed
	BRA	Disable
	
FindIndex:
	LDX	#PWMTable		; Top of table
	ROLB				; Multiply B by 2
	ABX				; Add to X
;
; Disable motors first. This will prevent our interrupt
; routine from doing something strange before we are done
;
Disable:
	TAB				; We're done with B: go ahead and reuse
	ANDB	#0xf0			; Mask of enable bits
	EORB	#0xf0			; Invert
	ANDB	PWMControl		; Set enabled motors off
	STAB	PWMControl
;
; If we were asked for a "speed" of zero, return now
;
	CMPX	#PWMTable
	BNE	TestMotor0
;
; Test each motor in turn
;
TestMotor0:
	BITA	#0b00010000		; Motor 0 to be enabled?
	BEQ	TestMotor1
	
	LDAB	0,X			; Copy appropriate speed word
	STAB	PWMValues
	LDAB	1,X
	STAB	PWMValues+1
TestMotor1:
	BITA	#0b00100000		; Motor 1 to be enabled?
	BEQ	TestMotor2
	
	LDAB	0,X
	STAB	PWMValues+2		; Copy appropriate speed word
	LDAB	1,X
	STAB	PWMValues+3
TestMotor2:
	BITA	#0b01000000		; Motor 2 to be enabled?
	BEQ	TestMotor3
	
	LDAB	0,X
	STAB	PWMValues+4		; Copy appropriate speed word
	LDAB	1,X
	STAB	PWMValues+5
TestMotor3:
	BITA	#0b10000000		; Motor 3 to be enabled?
	BEQ	Enable
	
	LDAB	0,X
	STAB	PWMValues+6		; Copy appropriate speed word
	LDAB	1,X
	STAB	PWMValues+7
;
; Enable motors and set direction
;
Enable:
	ORAA	PWMControl		; Set the motor control
	STAA	PWMControl
	RTS
;
; Our interrupt routine
;
	.global PWMInterupt
PWMInterrupt:
	SEI				; Disable interrupts
	LDAA	PWMControl		; Load control
	
Motor0:
	BITA	#0b00010000		; Check enable of motor 0
	BEQ	Motor1			; Don't bother if it is off
	
	XGDX				; Save A register in X
	LDD	PWMValues		; Load control word
	LSLD				; Shift
	BCC	Motor0Off		
	
	ADDD	#1			; Put rotated bit back into D
	STD	PWMValues		; Store shifted control word
	XGDX				; Return A register
	BRA	Motor1
	
Motor0Off:
	STD	PWMValues		; But shifted control word back
	XGDX				; Return A register
	ANDA	#0b11101111		; Clear motor 0 bit
	
Motor1:
	BITA	#0b00100000		; Check enable of motor 1
	BEQ	Motor2			; Don't bother if it is off
	
	XGDX				; Save A register in X
	LDD	PWMValues+2		; Load control word
	LSLD				; Shift
	BCC	Motor1Off		
	
	ADDD	#1			; Put rotated bit back into D
	STD	PWMValues+2		; Store shifted control word
	XGDX				; Return A register
	BRA	Motor2
	
Motor1Off:
	STD	PWMValues+2		; But shifted control word back
	XGDX				; Return A register
	ANDA	#0b11011111		; Clear motor 1 bit

Motor2:
	BITA	#0b01000000		; Check enable of motor 2
	BEQ	Motor3			; Don't bother if it is off
	
	XGDX				; Save A register in X
	LDD	PWMValues+4		; Load control word
	LSLD				; Shift
	BCC	Motor2Off		
	
	ADDD	#1			; Put rotated bit back into D
	STD	PWMValues+4		; Store shifted control word
	XGDX				; Return A register
	BRA	Motor3
	
Motor2Off:
	STD	PWMValues+4		; But shifted control word back
	XGDX				; Return A register
	ANDA	#0b10111111		; Clear motor 2 bit

Motor3:
	BITA	#0b10000000		; Check enable of motor 3
	BEQ	Store			; Don't bother if it is off
	
	XGDX				; Save A register in X
	LDD	PWMValues+6		; Load control word
	LSLD				; Shift
	BCC	Motor3Off		
	
	ADDD	#1			; Put rotated bit back into D
	STD	PWMValues+6		; Store shifted control word
	XGDX				; Return A register
	BRA	Store
	
Motor3Off:
	STD	PWMValues+6		; But shifted control word back
	XGDX				; Return A register
	ANDA	#0b01111111		; Clear motor 3 bit
;
; Store into motor address
;
Store:
	STAA	0x7000			; Motor address

	CLI
	RTS
