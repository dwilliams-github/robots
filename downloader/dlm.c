/* Downloader for 6811 code S-records */

/* IBM-PC Mix Power C version
   for Mini board by Fred Martin

   Macintosh version by Fred Martin

   from a program originally written by Henry Q. Minsky
   and subsequently modified by Randy Sargent  
*/

#define PC

#define VERSION_HI 2
#define VERSION_LO 4

/*

  V1.0 February 10, 1992:
    first version

  V1.1 February 15, 1992:
    added "-delay" flag

  V1.2 February 28, 1992:
    deleted "-delay"; modified eeboot code to echo each character
    after eeprom burn

  V1.3 March 9, 1992:
    allowed Motorola S19 record to be named with ".hex" suffix in
    addition to ".s19"

  V1.4 March 25, 1992:
    added flags to allow downloading to a board with a normal serial
    line circuit

  V2.0 April 13, 1992:
    re-wrote bootstrap routine for "intelligent" eeprom burn
    added "-be" (bulk erase) flag to erase whole eeprom before download
    
  V2.0 Macintosh  July 10, 1992:
    ported to Mac OS

  V2.1 July 24, 1992
    added "-ram" flag for download to Forth board

  V2.11 July 25, 1992
    fixed downloader to enable extended addressing

  V2.12 July 27, 1992
    put back old downloader when dl'ing to EEPROM:  doesn't frob PORTD bits

  V2.4 June 8, 1995
    added -256 and -512 options
*/

/*

    Mini board has hardware echo of all characters;
    does not have additional 6811 firmware echo during bootstrap
     download mode.

*/

#include <stdio.h>
#include <string.h>
#include <time.h>
#ifdef MAC
#include <console.h>
#endif
#ifdef PC
#include <bios.h>
#endif

#ifdef PC
int debug_serial= 0;

int com_port= 0;	/* PC:  0==COM1; 1==COM2 */
			/* Mac: '0'== modem, '1'== printer */

int bs_feedback= 1;	/* if true, expect serial 6811 echo during 
                           bootstrap sequence */

int hardware_echo= 0;
	/* if true, expect serial hardware to echo
                           characters during normal download */

int close_port= 0;		/* if true, close serial port when exiting */

int gBootLength= 512;

#endif
#ifdef MAC
extern int debug_serial;
extern int com_port;
extern int bs_feedback;
extern int hardware_echo;
extern int close_port;
#endif

int dl_to_ram= 1;	/* if true, download to RAM not EEPROM */

int bulk_erase= 0;	/* if true, bulk erase eeprom before download */

char filename[128];
char filenamea[128];
char filenameb[128];

char bootstring[9][80];

/* prototypes */
void usage();
void verbose_usage();
void usleep(long);

#ifdef MAC
/* needs 'stricmp' routine */
int stricmp(char *s1, char *s2)
{
	int i;
	
	for (i=0; s1[i] && s2[i]; i++) {
		if ((unsigned char)s1[i] > (unsigned char)s2[i]) return 1;
		if ((unsigned char)s1[i] < (unsigned char)s2[i]) return -1;
	}
	
	if (!(s1[i] | s2[i])) return 0;
	
	if (s1[i]) return 1;
	else return 0;
}
#endif

void init_bootstring_ram(void)
{
    strcpy(bootstring[0], "S12300008e00ff4fb710358625b7103cce10001f2e80fc1d282086b0a72b860ca72d8d2b24");
    strcpy(bootstring[1], "S123002020fc7f00ed2004860197ed8d5f167d00ed27048d102006183c8d5f1838081809f2");
    strcpy(bootstring[2], "S123004026e939188fe700a600202d863e8d298d3b817327f6368d2c8f8d29188f32817280");
    strcpy(bootstring[3], "S123006027e581702732815727bd815027b48142273f817727cd863f3cce10001f2e80fc01");
    strcpy(bootstring[4], "S1230080a72f38398d06368d031632393cce10001f2e20fca62f3839188fe10027a9a60074");
    strcpy(bootstring[5], "S12300a043d7ee94ee270486168d2386028d1f20968606b7103bb7103f8a01b7103b183cdc");
    strcpy(bootstring[6], "S12300c09dde18387f103b188f8602ce103fb7103be7008a01b7103b8d0a7f103b3918ce45");
    strcpy(bootstring[7], "S11000e06f9a200418ce0b29180926fc394c");
    strcpy(bootstring[8], "S9030000FC");
}

void init_bootstring_eeprom(void)
{
    strcpy(bootstring[0], "S12300008E00FF4FB71035CE10001F2E80FC1D282086B0A72B860CA72D8D2B20FC7F00E84F");
    strcpy(bootstring[1], "S12300202004860197E88D5F167D00E827048D102006183C8D5F183808180926E939188F95");
    strcpy(bootstring[2], "S1230040E700A600202D863E8D298D3B817327F6368D2C8F8D29188F32817227E58170274B");
    strcpy(bootstring[3], "S123006032815727BD815027B48142273F817727CD863F3CCE10001F2E80FCA72F38398D51");
    strcpy(bootstring[4], "S123008006368D031632393CCE10001F2E20FCA62F3839188FE10027A9A60043D7E994E9C8");
    strcpy(bootstring[5], "S12300A0270486168D2386028D1F20968606B7103BB7103F8A01B7103B183C9DD918387F21");
    strcpy(bootstring[6], "S12300C0103B188F8602CE103FB7103BE7008A01B7103B8D0A7F103B3918CE6F9A2004184A");
    strcpy(bootstring[7], "S10B00E0CE0B29180926FC3996");
    strcpy(bootstring[8], "S9030000FC");
}

/***************************************************************/
/* The 6811 is in bootstrap mode, so send a 0xFF at 1200 baud. */
/* Then send 256 bytes of program. These will be loaded in     */
/* starting at 0x00, and each byte will be echoed              */
/***************************************************************/

/**************/
/* BREAKPOINT */
/**************/

#ifdef PC
void breakpoint(void)
{
    if (bioskey(1)) { /* not zero if key ready */
        int key= bioskey(0) & 0xff;
        if (key == 27 || key == 3) exit(1);
    }
}
#endif

#ifdef PC
/*******************/
/* SERIAL ROUTINES */
/*******************/

#define BIOSCOM_INIT	0
#define BIOSCOM_WRITE   1
#define BIOSCOM_READ    2
#define BIOSCOM_STATUS	3

#define BAUD_1200	0x80
#define BAUD_9600	0xE0

#define	EIGHT_BITS	0x03

#define	DATA_READY	0x100
#define	DATA_SET_READY	0x20

void serial_init_1200(void)
{
    int status;

    status= bioscom(BIOSCOM_INIT, BAUD_1200 | EIGHT_BITS, com_port);
    if (debug_serial) printf("\tCOM%1d initialized; status= %#.4x\n",
                             com_port+1, status);
/*
    if (!(status & DATA_SET_READY)) {
        printf("Serial line not ready on COM%1d, exiting\n", com_port+1);
        exit(1);
    }
*/
}

void serial_init_9600(void)
{
    int status;

    status= bioscom(BIOSCOM_INIT, BAUD_9600 | EIGHT_BITS, com_port);
    if (debug_serial) printf("\tCOM%1d initialized; status= %#.4x\n",
    			     com_port+1, status);
/*
    if (!(status & DATA_SET_READY)) {
        printf("Serial line not ready on COM%1d, exiting\n", com_port+1);
        exit(1);
    }
*/
}

int serial_getchar(void)
{
    int ret;
    while (1) {
        breakpoint();
        if (bioscom(BIOSCOM_STATUS, 0, com_port) & DATA_READY) { /* data ready */
            ret = bioscom(BIOSCOM_READ, 0, com_port);
            if (debug_serial) printf("read char >%04x< from serial\n", ret);
            return ret & 0xFF;
        }
    }
}

/* returns -1 if not ready */
int serial_getchar_nowait(void)
{
    if (!(bioscom(BIOSCOM_STATUS, 0, com_port) & DATA_READY)) return -1;
    else return serial_getchar();
}

void serial_putchar(int c)
{
    if (debug_serial) printf("write char %02x to serial\n", c);
    bioscom(BIOSCOM_WRITE, (char)c, com_port);
}

void serial_putchar_getecho(int c)
{
    int i;

    serial_putchar(c);
    if (hardware_echo) {
        if (debug_serial) printf("discarding echo ");
        if (c != (i= serial_getchar()))	{ /* hardware echoes the char */
            printf("Serial line echo error (wanted %02x, got %02x)\n",
                   c, i);
            exit(1);
        }
    }
}


/* reads chars until there are no more; returns value of last char read */
int serial_getlast_char(void)
{
    int ch;
    int got_one= 0;

    if (debug_serial) printf("  Flushing to last char: ");
try_again:
    while (bioscom(BIOSCOM_STATUS, 0, com_port) & DATA_READY) {
        ch= bioscom(BIOSCOM_READ, 0, com_port);
        if (debug_serial) printf("read >%04x< ", ch);
        got_one= 1;
    }
    breakpoint();
    if (!got_one) goto try_again;

    if (debug_serial) printf("Returning >%02x<.\n", ch);
    return ch & 0xFF;
}

/* reads chars until there are no more */
void serial_flush(void)
{
    if (debug_serial) printf("  Flushing serial port: ");
    while (bioscom(BIOSCOM_STATUS, 0, com_port) & DATA_READY) {
        int ch= bioscom(BIOSCOM_READ, 0, com_port);
        if (debug_serial) printf(" >%04x< ", ch);
    }
    if (debug_serial) printf("Done.\n");
}

#endif

/* send 's' until get prompt, 1 if successful, 0 if not */
int synch_with_board(void)
{
    int j;

    serial_putchar('s');
    serial_putchar('s');
    serial_putchar('s');
    serial_putchar('s');
    serial_putchar('s');

    printf("Synchronizing with board...");
    for (j=0; j<20; j++) {
        int ch, lch;

        /* get characters until the last one; return the last valid char */
        while (1) {
/*            usleep(55000L); */
            lch= serial_getchar_nowait();
            if (lch == -1) break;
            ch = lch;
        }

        if (ch == '>') {
                serial_flush();
                break;
        }
        serial_putchar('s');

        printf("."); fflush(stdout);
        usleep(55000L);
    }
    if (j == 20) {
        printf("failed.\n");
        return 0;
    } else {
        printf("OK\n");
        return 1;
    }
}

#ifdef MAC
#define USLEEP_CLOCK CLOCKS_PER_SEC
#endif
#ifdef PC
#define USLEEP_CLOCK CLK_TCK
#endif

void usleep(long usec)
{
    clock_t finish;

    finish= clock() + (usec * (long)USLEEP_CLOCK) / 1000000L;

    while (clock() < finish);
}

/*****************/
/* HEX FUNCTIONS */
/*****************/

int hex_to_int(char ch)
{
  if ('0' <= ch && ch <= '9') return ch - '0';
  if ('a' <= ch && ch <= 'f') return ch - 'a' + 10;
  if ('A' <= ch && ch <= 'F') return ch - 'A' + 10;
  printf("Illegal hex digit >%c<\n", ch);
  return 0;
}

int decode_hex(char *str, int index)
{
   int hi,lo;
   char chi,clo;
   chi = str[index];
   clo = str[index+1];
   hi = hex_to_int(chi);
   lo = hex_to_int(clo);
   return (hi*16)+lo;
   }

void parsearg(int argc, char *argv[])
{
    int i= 1;

    if (argc == 1) usage();

    while (i < argc) {

        if (!stricmp(argv[i], "-debug")) {
            debug_serial= 1;
            printf("Turning serial debugging on\n");
            i++;
            continue;
        }

        if (!stricmp(argv[i], "-port")) {
            char *port= argv[i+1];
#ifdef PC
            if (!stricmp(port, "com1")) {
                printf("Using COM1\n");
                com_port= 0;
            } else if (!stricmp(port, "com2")) {
                printf("Using COM2\n");
                com_port= 1;
            }
#endif
#ifdef MAC            
            if (!stricmp(port, "modem")) {
                printf("Using modem port\n");
                com_port= 0;
            } else if (!stricmp(port, "printer")) {
                printf("Using printer port\n");
                com_port= 1;
            }
#endif
            else {
                printf("Unsupported com port `%s'\n\n", port);
                usage();
            }
            i+=2;
            continue;
        }

        if (!stricmp(argv[i], "-mb")) {
            bs_feedback= 0;
            hardware_echo= 1;
            printf("Turning bootstrap feedback off, hardware echo on\n");
            i++;
            continue;
        }
        
        if (!stricmp(argv[i], "-ram")) {
        	dl_to_ram= 1;
        	printf("Downloading to RAM\n");
        	i++;
        	continue;
        }
        
        if (!stricmp(argv[i], "-eeprom")) {
        	dl_to_ram= 0;
        	printf("Downloading to EEPROM\n");
        	i++;
        	continue;
        }
        
        if (!stricmp(argv[i], "-close")) {
        	close_port= 1;
        	printf("Will close serial port on exit\n");
        	i++;
        	continue;
		}
		
        if (!stricmp(argv[i], "-ns")) {
            bs_feedback= 1;
            hardware_echo= 0;
            printf("Turning bootstrap feedback on, hardware echo off\n");
            i++;
            continue;
        }

        if (!stricmp(argv[i], "-be")) {
            bulk_erase= 1;
            i++;
            continue;
        }
        
        if (!stricmp(argv[i], "-die")) {
#ifdef MAC
        	serial_cleanup();
#endif
        	exit(0);
        }
        
        if (!stricmp(argv[i], "-help") ||
            !stricmp(argv[i], "-h") ||
            !stricmp(argv[i], "?") ||
            !stricmp(argv[i], "-?")) {
                usage();
        } 
        
#ifdef PC
		if (!stricmp(argv[i], "-256")) 
		{
			gBootLength= 256;
			i++;
			continue;
		}
		if (!stricmp(argv[i], "-512"))
		{
			gBootLength= 512;
			i++;
			continue;
		}
		
#endif

        i++;
    }

    /* mandatory first arg:  filename to download */
    {
        char *suffix= strchr(argv[1],'.');
        strcpy(filename, argv[1]);
        if (!suffix) {
            strcpy(filenamea, filename);
            strcat(filenamea, ".s19");
            strcpy(filenameb, filename);
            strcat(filenameb, ".hex");
        } else if (!stricmp(suffix+1, "asm")) {
            printf("Can't download a .asm file\n");
            usage();
        } else if (!stricmp(suffix+1, "s19") &&
                   !stricmp(suffix+1, "hex")) {
            printf("You should be downloading a .s19 file or a .hex file\n");
            usage();
        }
    }

}

void usage(void)
{
#ifdef PC
    printf("usage:  dlm filename[.s19|.hex] [-port COM1|COM2] [-mb] [-ns] [-be]\n");
#endif
#ifdef MAC
	printf("usage:  dlm filename[.s19|.hex] [-port modem|printer] [-mb] [-ns] [-be]\n");
#endif
    printf("            [-close] [-debug] [-help]\n\n");

#ifdef PC
    printf("\t-port COM1 or -port COM2   use specified serial port\n");
    printf("\t                           (defaults to COM%1d)\n\n", com_port+1);
#endif
#ifdef MAC
	printf("\t-port modem                use specified serial port\n");
	printf("\t-port printer              (defaults to %s port)\n\n",
	       com_port ? "printer" : "modem");
#endif

    printf("\t-mb                        assume Mini Board serial connection\n");
    printf("\t                           (hardware echo of transmitted characters,\n");
    printf("\t                           except during bootstrap; defaults off)\n\n");

    printf("\t-ns                        assume normal serial connection\n");
    printf("\t                           (defaults on)\n\n");

    printf("\t-be                        bulk erase EEPROM at start of download\n");
    printf("\t                           (faster if many bytes have changed;\n");
    printf("\t                           defaults %s)\n\n", bulk_erase ? "on" : "off");

    printf("\t-ram, -eeprom              download to RAM or EEPROM\n");
    printf("\t                           (defaults to %s)\n\n", dl_to_ram ? "RAM" : "EEPROM");

#ifdef MAC
    printf("\t-close                     close serial driver on exit (defaults %s)\n\n",
           close_port ? "on" : "off");
#endif

#ifdef PC
	printf("\t-256                       use 256-byte bootloader\n");
	printf("\t-512                       use 512-byte bootloader\n");
	printf("\t                           (defaults to -%d)\n\n", gBootLength);
#endif	

    printf("\t-help                      prints these instructions\n");

    exit(-1);
}

void verbose_usage()
{
    printf("To connect your computer to the Mini Board, build a custom modular-jack-to-\n");
    printf("DB-style connector according to the following diagram:\n\n");

    printf("                         +------+    \n");
    printf("                      +--+      +--+  \n");
    printf("  (front view      +--+            +--+\n");
    printf("   of adapter's    |                  |\n");
    printf("   RJ11 jack;      |                  |\n");
    printf("   wires protrude  |                  |\n");
    printf("   from the back.) |                  |\n");
    printf("                   | #  #  #  #  #  # |      'NC' means no connection.\n");
    printf("                   | #  #  #  #  #  # |\n");
    printf("                   +-#--#--#--#--#--#-+\n");
    printf("            	    NC  |  |  |  | NC\n");
#ifdef PC
    printf("            	        |  |  |  |    ++--+  <-tied together\n");
    printf("  COMPUTER STYLE        |   \\/   |   / |  |                 \n");
    printf("                        |    |   |  /  |  |               ADAPTER TYPE \n");
    printf("    IBM-XT              2    7   3  5  6  20       25-pin female to RJ11 jack\n");
    printf("    IBM-AT              3    5   2  4  6  8         9-pin female to RJ11 jack\n");
    printf("\n");
    printf("                     DB CONNECTOR PIN NUMBERING\n");
    printf("\n");
    printf("One end of the adapter (the DB-9 or DB-25 end) plugs into your computer's\n");
    printf("serial port; the other end connects to the Mini Board via normal phone cable.\n");
#endif
#ifdef MAC
    printf("    COMPUTER STYLE      |   \\/   |               ADAPTER TYPE  \n");
    printf("                        |    |   |          \n");
    printf("  Mac + 'modem' cable   2    7   3          25-pin female to RJ11 jack\n");
    printf(" Mac + 'printer' cable  3    7   2          25-pin female to RJ11 jack\n");
    printf("\n");
    printf("                  DB CONNECTOR PIN NUMBERING\n");
	printf("\n");
	printf("Plug completed adapter into printer or modem cable and then plug into Mac.\n");
	printf("Either cable/adapter assembly can be used in either 'printer' or 'modem' port.\n");
	printf("Connect modular jack end of adapter to Mini Board with normal phone cable.\n");
#endif
    exit(0);
}

void main(int argc, char *argv[])
{
    char line_in[256];

    int byte_count, data_byte, return_byte, i, j;
    int total_bytes, startaddh, startaddl;
    int bs_ix=0;
#ifdef MAC
	OSErr err;
#endif
#ifdef PC
	int err;
#endif

    FILE *userstream;
    
#ifdef MAC
/*
	console_options.txSize= 10;
	console_options.left= 0;
*/
#endif

    printf("DLM:  6811 File Downloader with Intelligent EEPROM burn by Fred Martin\n");
    printf("portions (C) 1992 by Randy Sargent\n");

#ifdef PC
    printf("Version %d.%d %s %s\n\n", VERSION_HI, VERSION_LO, __DATE__, __TIME__);
#endif
#ifdef MAC
	printf("Macintosh Version %d.%d\n\n", VERSION_HI, VERSION_LO);
#endif

#ifdef MAC
	argc= ccommand(&argv);
	csetmode(C_RAW, stdin);
#endif

    parsearg(argc, argv);

	if (dl_to_ram == 0)
	    init_bootstring_eeprom();
	else
		init_bootstring_ram();

    total_bytes=0;

    /* open user's pgm */
    if ((userstream = fopen(filename,"r")) == NULL)
      if ((userstream = fopen(filenamea,"r")) == NULL)
        if ((userstream = fopen(filenameb,"r")) == NULL) {
        printf("Couldn't open user program %s, %s, or %s\n",filename, filenamea, filenameb);
        usage();
        } else {
            strcpy(filename, filenameb);
        }
    else {
        strcpy(filename, filenamea);
    }

    printf("Downloading %s, press ESC to abort\n",filename);

    /* initialize 1200 baud port 8 bits no parity */
    if (err= serial_init_1200()) {
    	fprintf(stderr, "Unable to initialize serial port for 1200 baud.\n");
#ifdef MAC
    	fprintf(stderr, "Please check that Appletalk is disabled for the port you would like to use.\n");
#endif
    	exit(err);
    }

    printf("Downloading eeprom loader to RAM at 1200 baud...");

    /* send initial 0xff */
    serial_putchar(0xff);

    while (1) {
        strcpy(line_in, bootstring[bs_ix++]);
        if ((line_in[0] == 'S') && (line_in[1] == '9')) break;

        byte_count = (decode_hex(line_in,2) - 3);

        /* loop sending data bytes from the s-record */
        for (i = 0; i < byte_count; i++) {
        	breakpoint();
            data_byte = decode_hex(line_in,(2*i)+8);
            serial_putchar(data_byte);
            if (bs_feedback) serial_getchar();
          getanother:
            if (serial_getchar_nowait() != -1) {
            	if (debug_serial) fprintf(stderr, "Extra char on serial input\n");
            	goto getanother;
            }
            if (!(total_bytes % 32)) printf("\n");
            printf("."); fflush(stdout);
            total_bytes++;
        }
    }
    /* now send 256-byte_count 0's to fill the rest of ram */

    while (total_bytes < gBootLength) {
    	breakpoint();
        serial_putchar(0);
        if (bs_feedback) serial_getchar();
      getanother2:
        if (serial_getchar_nowait() != -1) {
            if (debug_serial) fprintf(stderr, "Extra char on serial input\n");
            goto getanother2;
        }
        if (!(total_bytes % 32)) printf("\n");
        printf("_"); fflush(stdout);
        total_bytes++;
    }

    printf("\n%d total bytes (boot loader done)\n\n", total_bytes);

    /* now download the user prog */

    /* initialize 9600 baud port 8 bits no parity */
    usleep(110000L);	/* wait for last char to transmit */

#ifdef MAC
    serial_cleanup();
#endif
	
    if (err= serial_init_9600()) {
    	fprintf(stderr, "Unable to initialize serial port for 9600 baud\n");
    	exit(err);
    }

    /* synchronize */
    if (!synch_with_board()) {
#ifdef MAC
    	serial_cleanup();
#endif
    	exit(0);
    }

    if (bulk_erase) {
        printf("Bulk erasing EEPROM..."); fflush(stdout);
        serial_putchar_getecho('B');
        serial_putchar_getecho(0);
        serial_putchar_getecho(0);
        serial_putchar_getecho(0);
        serial_putchar_getecho(0xF5); /* config register */

        /* board should send prompt now */
        if (serial_getchar() != '>') {
            printf("Board synchronization error. \n");
            exit(1);
        } else printf("OK\n");
    }

    printf("Sending %s at 9600 baud\n", filename);
    total_bytes= 0;

    while (fgets(line_in,256,userstream) != NULL) {
        if ((line_in[0] == 'S') && (line_in[1] == '9')) break;

        byte_count = decode_hex(line_in,2) - 3;
        startaddh = decode_hex(line_in,4);
        startaddl = decode_hex(line_in,6);

        /* use block download to EEPROM mode */
        if (dl_to_ram == 0)
	        serial_putchar_getecho('P');
	    else
	    	serial_putchar_getecho('W');

        serial_putchar_getecho(startaddh);
        serial_putchar_getecho(startaddl);
        serial_putchar_getecho(0);		/* count hi */
        serial_putchar_getecho(byte_count);

        /* loop sending data bytes from the s-record */
        for (i = 0; i < byte_count; i++) {
            data_byte = decode_hex(line_in,(2*i)+8);
            serial_putchar_getecho(data_byte);
            return_byte= serial_getchar();
            if (data_byte != return_byte) {
                printf("Board memory error:  wanted %02x, got %02x at address %04x\n",
                       data_byte, return_byte, (startaddh<<8)+startaddl+i);
            }

            total_bytes++;
            if (!(total_bytes % 16)) {printf("."); fflush(stdout);}
        }

        /* board should send prompt now */
        if (serial_getchar() != '>') {
            printf("Board synchronization error. \n");
            exit(1);
        } else if (debug_serial) {fprintf(stderr, "\tBOARD PROMPT\n");}

    }

    printf("\nUser program downloaded successfully.\n");
    fclose(userstream);

#ifdef MAC
	serial_cleanup();
#endif

    exit(0);
}
