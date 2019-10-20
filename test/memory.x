/*
 | Memory layout of handyboard
 |
 | Memory is fragmented by interrupt vector at bfc0 to bfff
 | EPROM sits... where? configurable? Is it enabled?
 |
 | Program (text) from 0x8000 to 0xbf00
 | Data           from 0xc000 to 0xe000
*/

MEMORY
{
	page0 (rwx) : ORIGIN = 0x0, LENGTH = 256
	text (rx)   : ORIGIN = 0x8000, LENGTH = 0x3f00
	data        : ORIGIN = 0xc000, LENGTH = 0x2000
}

PROVIDE (_stack = 0xf800 - 1);