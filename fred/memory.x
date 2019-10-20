/*
 | Memory layout of handyboard
 |
 | 32k external memory mapped to 0x8000 to 0xffff
 |
 | Note that the handyboard runs in "special test mode". This means that
 | the interrupt vector table that normally resides at ffc0 is moved
 | to bfc0-bfff. This fragments the external memory.
 |
 | This map also assumes the EEPROM is turned off. Since the handyboard
 | has battery backup, there is no reason to use the EEPROM.
 |
 | The mc68hc11a series actually has 256 bytes in page0. However,
 | for this special application, we need to reserve some of this
 | for the LCD display routines. So we allow the compiler to use only
 | 0xa0 = 160 bytes
 |
 | Program (text) from 0x8000 to 0xbf00
 | Data           from 0xc000 to 0xe000
 | Stack starts at 0xffff and can grow by 0x2000 before colliding
*/

MEMORY
{
	page0 (rwx) : ORIGIN = 0x0, LENGTH = 0x80
	user0 (rwx) : ORIGIN = 0x80, LENGTH = 0x80
	text (rx)   : ORIGIN = 0x8000, LENGTH = 0x3f00
	data        : ORIGIN = 0xc000, LENGTH = 0x2000
}

PROVIDE (_stack = 0xffff - 1);