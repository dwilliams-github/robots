;
; mc68hc11 control registers
;
REGS    =     0x1000

PORTA   =     0x00   ; Port A data register
RESV1   =     0x01   ; Reserved
PIOC    =     0x02   ; Parallel I/O Control register
PORTC   =     0x03   ; Port C latched data register
PORTB   =     0x04   ; Port B data register
PORTCL  =     0x05   ;
DDRC    =     0x07   ; Data Direction register for port C
PORTD   =     0x08   ; Port D data register
DDRD    =     0x09   ; Data Direction register for port D
PORTE   =     0x0A   ; Port E data register
CFORC   =     0x0B   ; Timer Compare Force Register
OC1M    =     0x0C   ; Output Compare 1 Mask register
OC1D    =     0x0D   ; Output Compare 1 Data register

; Two-Byte Registers (High,Low -- Use Load & Store Double to access)
TCNT    =     0x0E   ; Timer Count Register
TIC1    =     0x10   ; Timer Input Capture register 1
TIC2    =     0x12   ; Timer Input Capture register 2
TIC3    =     0x14   ; Timer Input Capture register 3
TOC1    =     0x16   ; Timer Output Compare register 1
TOC2    =     0x18   ; Timer Output Compare register 2
TOC3    =     0x1A   ; Timer Output Compare register 3
TOC4    =     0x1C   ; Timer Output Compare register 4
TI4O5   =     0x1E   ; Timer Input compare 4 or Output compare 5 register

TCTL1   =     0x20   ; Timer Control register 1
TCTL2   =     0x21   ; Timer Control register 2
TMSK1   =     0x22   ; main Timer interrupt Mask register 1
TFLG1   =     0x23   ; main Timer interrupt Flag register 1
TMSK2   =     0x24   ; misc Timer interrupt Mask register 2
TFLG2   =     0x25   ; misc Timer interrupt Flag register 2
PACTL   =     0x26   ; Pulse Accumulator Control register
PACNT   =     0x27   ; Pulse Accumulator Count register
SPCR    =     0x28   ; SPI Control Register
SPSR    =     0x29   ; SPI Status Register
SPDR    =     0x2A   ; SPI Data Register
BAUD    =     0x2B   ; SCI Baud Rate Control Register
SCCR1   =     0x2C   ; SCI Control Register 1
SCCR2   =     0x2D   ; SCI Control Register 2
SCSR    =     0x2E   ; SCI Status Register
SCDR    =     0x2F   ; SCI Data Register
ADCTL   =     0x30   ; A/D Control/status Register
ADR1    =     0x31   ; A/D Result Register 1
ADR2    =     0x32   ; A/D Result Register 2
ADR3    =     0x33   ; A/D Result Register 3
ADR4    =     0x34   ; A/D Result Register 4
BPROT   =     0x35   ; Block Protect register
RESV2   =     0x36   ; Reserved
RESV3   =     0x37   ; Reserved
RESV4   =     0x38   ; Reserved
OPTION  =     0x39   ; system configuration Options
COPRST  =     0x3A   ; Arm/Reset COP timer circuitry
PPROG   =     0x3B   ; EEPROM Programming register
HPRIO   =     0x3C   ; Highest Priority Interrupt and misc.
INIT    =     0x3D   ; RAM and I/O Mapping Register
TEST1   =     0x3E   ; factory Test register
CONFIG  =     0x3F   ; Configuration Control Register
