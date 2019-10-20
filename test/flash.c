int main()
{
	int i, j, k;

	volatile unsigned char *led = (unsigned char *)0x1000;

	for(i=0;i<100000;++i) {
		*led = 0x40;
		for(j=0;j<100*i;++j) {;}
		*led = 0x00;
		for(j=0;j<100*i;++j) {;}
	}	
	
	for(;;) {;}
}
