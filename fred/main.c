#include <string.h>

extern unsigned char LCDBuffer;
extern unsigned short SonarRange;
extern unsigned short TimerClock;
extern unsigned char Analog6;

unsigned char t1, t2;

void PWMOnFree( unsigned char encoding, unsigned char speed );
void PWMKillNow();

int main()
{
	long i, j;
	char *hello = "hello";
	volatile unsigned char *led = (unsigned char *)0x1000;
	volatile unsigned char *dig = (unsigned char *)0x7000;
	unsigned char digRead;
	unsigned char anaRead;
	unsigned char *lcd = &LCDBuffer;
	
	volatile unsigned char *options = (unsigned char *)0x1039;
	
	*options |= 0x80;	/* Turn on analog ports */
	
	LCDinit();
	TimerInit();
	LCDBufferInit();
	PWMInit();
	SonarInit();
	
	strncpy( lcd, "test ???????? ??", 13 );
	
	i = 0;
	for(;;) {
		i++;
		
		if (1==1) {
			unsigned short sonar = SonarRange;

			unsigned char a0 = sonar&0xf;
			unsigned char a1 = (sonar>>4)&0xf;
			unsigned char a2 = (sonar>>8)&0xf;
			unsigned char a3 = (sonar>>12);
			
			lcd[21] = a0 < 10 ? '0'+a0 : 'A'+a0-10;
			lcd[20] = a1 < 10 ? '0'+a1 : 'A'+a1-10;
			lcd[19] = a2 < 10 ? '0'+a2 : 'A'+a2-10;
			lcd[18] = a3 < 10 ? '0'+a3 : 'A'+a3-10;

			i=0;
		}
		
		digRead = *dig;
		
		for(j=0;j<8;++j) {
			lcd[5+j] = (digRead&(1<<j)) ? 'X' : '.';
		} 
		
		asm volatile ( "jsr ReadAnalog6" );
		
		anaRead = Analog6;
		
		{
			unsigned char a1 = anaRead&0xf;
			unsigned char a2 = (anaRead>>4)&0xf;
			
			lcd[15] = a1 < 10 ? '0'+a1 : 'A'+a1-10;
			lcd[14] = a2 < 10 ? '0'+a2 : 'A'+a2-10;
		}
		
		if ((digRead&(1<<7)) == 0) {
			lcd[16] = 'S';
			
			PWMOnFree(0x30,0x08);
		}
		
		if ((digRead&(1<<6)) == 0) {
			lcd[16] = '.';
			
			PWMKillNow();
		}
	}	
}
