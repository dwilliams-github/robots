# Robots

This project is an entirely self-contained program for a robot
I designed and built from scratch, sometime around 2001.
I still have the actual robot, but haven't turned it on in years.
It is very primitive by modern standards, using a CPU that cannot
even support the simplest operating system. Thus, the code I wrote
ran on the bare CPU (it was the "operating system" in a sense).

I've long forgotten the details, but after a quick look at the
code, it's easy to reconstruct what I did.

It's a simple CPU, so it wasn't hard to write an execution loop
for the main process, and put background tasks (motor movement,
sensor reading) into a simple timer interrupt routine. The main
loop and logic were written in c (using a cross-compiler). The
drivers and interrupt routines were written in macro assembly.
To save memory, I wrote my own LCD output routine, so that the
robot can print messages, but without the overhead of a formal
"printf" library. For debugging, I used the db11 remote debugger.

Code was created on a MacOS 9 system. A USB-to-serial cable was
used to talk to the robot. It looks like I tinkered a bit to get
the boot loader to work.

The motor and LCD drivers used bits and pieces of code borrowed
from other sources. It looks like I wrote the code for the sonar
range finder myself from scratch.