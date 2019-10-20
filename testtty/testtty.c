#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>

main()
{
	char stuff;
	int i,j;
	int tty = open("/dev/tty.KeyUSA28X623.1", O_RDWR);
	
	if (tty < 0) {
		printf( "Failure! tty = %d\n", tty );
		return;
	}
	
	for(i=0;i<10;++i) {
		printf( "Press return for test: " );
		scanf("%c",&stuff);
		
		j = write(tty,"fred",4);
		
		printf( "Written %d\n", j );
	}
	
	close(tty);
}
