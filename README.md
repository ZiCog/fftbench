fftbench
========

A parallel integer only FFT for multi-core micro-controllers like the Parallax Propeller or XMOS devices.

Implementations in various languages are provided.

Muliple cores are used where possible, up to 16, thanks to OpenMP.

Compile the C version like so:

    $ gcc -Wall -fopenmp -O3 -o fftbench fftbench.c

Or without OpenMP like so:

    $ gcc -Wall -O3 -o fftbench fftbench.c

This may not be the smartest, fastest implementation but it has been used in benchmarking compilers/MCUs 
like GCC and Catalina C for the Propeller, Propeller Spin and PASM, XC for XMOS and so on.
