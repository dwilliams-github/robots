;
; sonar.s
;
; Implement an asynchronous driver for the Devantech SRF04 ultrasonic
; range finder and the Handyboard. For information on the SRF04, see:
;
;	http://www.acroname.com/robotics/parts/R93-SRF04.html
;	http://www.robot-electronics.co.uk/htm/srf04.shtml
;
; The following connections are assumed: the trigger line
; is connected to digital "input" 2 on header J2. The echo
; line is connected to digital input 0 on header J2.
;
; After initialization, a range is stored at global address "SonarRange"
; every 64 milliseconds.
;
	.include "mc68hc11.control.s"
	.include "mc68hc11.vector.s"
;
	.section .data
	.global SonarRange
SonarRange:
	.word	0		; Here is where the answer is tossed
StartTime:
	.word	0		; The time at which the pulse was sent
;
;
	.section .text
;
; ===============
; SonarInit
; ===============
;
	.global SonarInit
SonarInit:
	LDX	#REGS
;
; Set the DDRA7 bit of the PACTL register. This switches port
; A bit 7 to output (also labeled as "PA1"). On the handyboard,
; PA1 is connected to digital "input" number 3 on header J2.
; This will be the trigger for our sonar pulse.
;
	BSET	PACTL,X	#0b10000000
;
; Set EDG3B and EDG3A bits on the TCTL2 control register
; to capture input on the falling edge only of digital input
; TIC3. On the handyboard, TIC3 is connected to digital input
; number 0 on header J2. This will be used to record the time
; the sonic echo returns.
;
	BSET	TCTL2,X	#0b00000010
	BCLR	TCTL2,X	#0b00000001
;
; Install our interrupt routine
;
	LDY	#VECTOR_BASE
	LDD	#SonarInterrupt
	STD	TIC3INT,Y
;
; Set interrupt enable bit
;
	BSET	TMSK1,X #0b00000001
;
; Install timer routine
;
	LDD	#SonarSample
	JMP	TimerInstallUser
;
; ---------------------
; SonarSample
; To be called at 1 kHz
;
; Initiate sonar sample every 64 milliseconds
;
	.global SonarSample
SonarSample:
;
; Check clock, and return for 63 out of 64 calls
;
	LDAA	*(TimerClock+1)		; Load timer clock
	ANDA	#0x3f			; Check 6 lower bits (2^6 = 64)
	BEQ	Fire			; If zero, do something
	RTS

Fire:
	LDX	#REGS
;
; Send command for a sonic pulse by setting and
; then clearing bit 7 of PORTA. The pulse must be at
; least 10 microseconds long, or 20 clock cycles.
; Spend this time recording start time
;
	BSET	PORTA,X	#0b10000000		; Start pulse
;
	NOP					; Kill 4 clocks
	NOP
;	
	LDY	#StartTime			; 5 clocks: Storage address
	LDD	TCNT,X				; 5 clocks: Load current time
	STD	0,Y				; 6 clocks: Store away
;	
	BCLR	PORTA,X	#0b10000000		; Lower pulse
	RTS
;
; ---------------------
; SonarInterrupt: record TIC3 time, subtract start time,
; and store result in global address. Make sure the interrupt
; is cleared before returning.
;
SonarInterrupt:
	LDX	#REGS
	LDY	#SonarRange
	
	LDD	TIC3,X
	SUBD	2,Y
	STD	0,Y

	BCLR	TFLG1,X	#0b11111110
	
	RTI
