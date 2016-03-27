'----------------------------------------------------------------------------------------------------------------------
'
' fft_bench.spin
'
' A simple FFT implmentation for use as a micro-controller benchmark. This is an in-place
' Radix-2 Decimation In Time FFT using fixed point arithmetic.
'
' The intention is to use the algorithm presented here as a basis for implementations
' in other languages, C, BASIC etc, by which comaprisons between competing languages and systems
' can be made.
'
' When reimplementing this benchmark in other languages please honour the intention of
' this benchmark by following the algorithm as closely as possible.
'
' This FFT was developed from the description by Douglas L. Jones at
' http://cnx.org/content/m12016/latest/.
' It is written as a direct implementation of the discussion and diagrams on that page
' with an emphasis on clarity and ease of understanding rather than speed.
'
' Michael Rychlik. 2011-02-27
'
' This file is released under the terms of the MIT license. See below.
'
' Credits:
'
'     A big thank you to Dave Hein for clearing up some issues during a great FFT debate on
'     the Parallax Inc Propller discussion forum:
'     http://forums.parallax.com/showthread.php?127306-Fourier-for-dummies-under-construction
'
' History:
'
' 2011-02-27    v1.0  Initial version.
'
'----------------------------------------------------------------------------------------------------------------------
OBJ
    'Set your platform configuration in userdef.spin
    'Ideally, your userdefs.spin can live in the library path,
    'and you can simply remove a new package's userdefs.spin
    'to enable your own definitions.
    def  : "userdefs.spin"

    'User interface port
    ser  : "FullDuplexSerialPlus"
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
CON
    _clkmode      = def#_clkmode
    _xinfreq      = def#_xinfreq

    'Specify size of FFT buffer here with length and log base 2 of the length.
    'N.B. Changing this will require changing the "twiddle factor" tables.
    '     and may also require changing the fixed point format (if going bigger)
    FFT_SIZE      = 1024
    LOG2_FFT_SIZE = 10
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
VAR
    'cos and sin parts of the signal to be analysed
    'Result is written back to here.
    'Just write input sammles to bx and zero all by.
    long bx[FFT_SIZE]
    long by[FFT_SIZE]
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
PUB fft_bench | startTime, endTime
    'Start the terminal
    ser.start(def#conRxPin, def#conTxPin, def#conMode, def#conBaud)
    ser.str(string("fft_bench v1.0"))
    newline

    'Input some data
    fillInput

    'Start benchmark timer
    startTime := cnt

    'Radix-2 Decimation In Time, the bit-reversal step.
    decimate

    'The actual Fourier transform work.
    butterflies

    'Stop benchmark timer
    endTime := cnt

    'Print resulting spectrum
    printSpectrum

    ser.str(string("1024 point bit-reversal and butterfly run time = "))
    ser.dec((endTime - startTime) / (clkfreq / 1000000))
    ser.str(string("us"))
    newline
    repeat
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
PRI printSpectrum  | f, real, imag, magnitude
'Spectrum is available in first half of the buffers after FFT.
    ser.str(string("Freq.    Magnitude"))
    newline
    repeat f from 0 to (FFT_SIZE / 2)
        'Frequency magnitde is square root of cos part sqaured plus sin part squared
        real := bx[f] / FFT_SIZE
        imag := by[f] / FFT_SIZE
        magnitude := ^^((real * real) + (imag * imag))

        if magnitude <> 0
            ser.hex(f, 8)
            ser.tx(32)
            ser.hex(magnitude, 8)
            newline
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
PRI fillInput | k
'Fill buffer bx with samples of of an imput signal and clear by.
    repeat k from 0 to (FFT_SIZE - 1)
        'Two frequencies of the waveform defined in input
        bx[k] := (~~input[(3*k) // 16] / 4)
        bx[k] += (~~input[(5*k) // 16] / 4)

        'The highest frequency
        if (k & 1)
          bx[k] += (4096 / 8)
        else
          bx[k] += (-4096 / 8)

        'A DC level
        bx[k] += (4096 / 8)

        'Clear Y array.
        by[k] := 0
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
PRI newline
    ser.tx(13)
    ser.tx(10)
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
DAT
'For testing define 16 samples  of an input wave form here.
input word 4096, 3784, 2896, 1567, 0, -1567, -2896, -3784, -4096, -3784, -2896, -1567, 0, 1567, 2896, 3784
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
PRI decimate | i, revi, tx1, ty1
'Radix-2 decimation in time.
'Moves every sample of bx and by to a postion given by
'reversing the bits of its original array index.
    repeat i from 0 to FFT_SIZE - 1
        revi := i >< LOG2_FFT_SIZE
        if i < revi
            tx1 := bx[i]
            ty1 := by[i]

            bx[i] := bx[revi]
            by[i] := by[revi]

            bx[revi] := tx1
            by[revi] := ty1
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
PRI butterflies | k1, k2, k3, a, b, c, d, flightSize, noFlights, b0, b1, {
} wIndex, level, flight, butterfly, flightIndex, tx, ty
'Apply FFT butterflies to N complex samples in buffers bx and by, in time decimated order!
'Resulting FFT is produced in bx and by in the correct order.
    flightSize := 1
    noFlights := FFT_SIZE >> 1

    'Loop though the decimation levels
    repeat level from 0 to LOG2_FFT_SIZE - 1
        flightIndex := 0
        'Loop through each flight on a level.
        repeat flight from 0 to noFlights - 1
            wIndex := 0
            'Loop through butterflies within a flight.
            repeat butterfly from 0 to flightSize - 1
                b0 := flightIndex + butterfly
                b1 := b0 + flightSize

                'At last...the butterfly.
                a := bx[b1]                 'Get X[b1]
                b := by[b1]

                c := ~~wx[wIndex]           'Get W[wIndex]
                d := ~~wy[wIndex]

                k1 := (a * (c + d))~> 12    'Somewhat optimized complex multiply
                k2 := (d * (a + b))~> 12    '    T = X[b1] * W[wIndex]
                k3 := (c * (b - a))~> 12

                tx := k1 - k2
                ty := k1 + k3

                k1 := bx[b0]
                k2 := by[b0]
                bx[b1] := k1 - tx           'X[b1] = X[b0] * T
                by[b1] := k2 - ty

                bx[b0] := k1 + tx           'X[b0] = X[b0] * T
                by[b0] := k2 + ty

                wIndex += noFlights
            'endRepeat
            flightIndex += (flightSize << 1)
        'endRepeat
        flightSize <<= 1
        noFlights >>= 1
    'endRepeat
'endPub
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
DAT
wx  word  04095, 04094, 04094, 04094, 04093, 04093, 04092, 04091, 04090, 04088, 04087, 04085, 04083, 04081, 04079, 04077
    word  04075, 04072, 04070, 04067, 04064, 04061, 04057, 04054, 04050, 04046, 04042, 04038, 04034, 04030, 04025, 04021
    word  04016, 04011, 04006, 04000, 03995, 03989, 03984, 03978, 03972, 03966, 03959, 03953, 03946, 03939, 03932, 03925
    word  03918, 03911, 03903, 03896, 03888, 03880, 03872, 03864, 03855, 03847, 03838, 03829, 03820, 03811, 03802, 03792
    word  03783, 03773, 03763, 03753, 03743, 03733, 03723, 03712, 03701, 03691, 03680, 03668, 03657, 03646, 03634, 03623
    word  03611, 03599, 03587, 03575, 03563, 03550, 03537, 03525, 03512, 03499, 03486, 03473, 03459, 03446, 03432, 03418
    word  03404, 03390, 03376, 03362, 03348, 03333, 03318, 03304, 03289, 03274, 03258, 03243, 03228, 03212, 03197, 03181
    word  03165, 03149, 03133, 03117, 03100, 03084, 03067, 03051, 03034, 03017, 03000, 02983, 02965, 02948, 02930, 02913
    word  02895, 02877, 02859, 02841, 02823, 02805, 02787, 02768, 02750, 02731, 02712, 02693, 02674, 02655, 02636, 02617
    word  02597, 02578, 02558, 02539, 02519, 02499, 02479, 02459, 02439, 02419, 02398, 02378, 02357, 02337, 02316, 02295
    word  02275, 02254, 02233, 02211, 02190, 02169, 02148, 02126, 02105, 02083, 02061, 02040, 02018, 01996, 01974, 01952
    word  01930, 01908, 01885, 01863, 01841, 01818, 01796, 01773, 01750, 01728, 01705, 01682, 01659, 01636, 01613, 01590
    word  01567, 01543, 01520, 01497, 01473, 01450, 01426, 01403, 01379, 01355, 01332, 01308, 01284, 01260, 01236, 01212
    word  01188, 01164, 01140, 01116, 01092, 01067, 01043, 01019, 00994, 00970, 00946, 00921, 00897, 00872, 00848, 00823
    word  00798, 00774, 00749, 00724, 00700, 00675, 00650, 00625, 00600, 00575, 00551, 00526, 00501, 00476, 00451, 00426
    word  00401, 00376, 00351, 00326, 00301, 00276, 00251, 00226, 00200, 00175, 00150, 00125, 00100, 00075, 00050, 00025
wy  word  00000, -0025, -0050, -0075, -0100, -0125, -0150, -0175, -0200, -0226, -0251, -0276, -0301, -0326, -0351, -0376
    word  -0401, -0426, -0451, -0476, -0501, -0526, -0551, -0576, -0600, -0625, -0650, -0675, -0700, -0724, -0749, -0774
    word  -0798, -0823, -0848, -0872, -0897, -0921, -0946, -0970, -0995, -1019, -1043, -1067, -1092, -1116, -1140, -1164
    word  -1188, -1212, -1236, -1260, -1284, -1308, -1332, -1355, -1379, -1403, -1426, -1450, -1473, -1497, -1520, -1543
    word  -1567, -1590, -1613, -1636, -1659, -1682, -1705, -1728, -1750, -1773, -1796, -1818, -1841, -1863, -1885, -1908
    word  -1930, -1952, -1974, -1996, -2018, -2040, -2062, -2083, -2105, -2126, -2148, -2169, -2190, -2212, -2233, -2254
    word  -2275, -2295, -2316, -2337, -2357, -2378, -2398, -2419, -2439, -2459, -2479, -2499, -2519, -2539, -2558, -2578
    word  -2597, -2617, -2636, -2655, -2674, -2693, -2712, -2731, -2750, -2768, -2787, -2805, -2823, -2841, -2859, -2877
    word  -2895, -2913, -2930, -2948, -2965, -2983, -3000, -3017, -3034, -3051, -3067, -3084, -3100, -3117, -3133, -3149
    word  -3165, -3181, -3197, -3212, -3228, -3243, -3258, -3274, -3289, -3304, -3318, -3333, -3348, -3362, -3376, -3390
    word  -3404, -3418, -3432, -3446, -3459, -3473, -3486, -3499, -3512, -3525, -3537, -3550, -3563, -3575, -3587, -3599
    word  -3611, -3623, -3634, -3646, -3657, -3668, -3680, -3691, -3701, -3712, -3723, -3733, -3743, -3753, -3763, -3773
    word  -3783, -3792, -3802, -3811, -3820, -3829, -3838, -3847, -3855, -3864, -3872, -3880, -3888, -3896, -3903, -3911
    word  -3918, -3925, -3932, -3939, -3946, -3953, -3959, -3966, -3972, -3978, -3984, -3989, -3995, -4000, -4006, -4011
    word  -4016, -4021, -4025, -4030, -4034, -4038, -4043, -4046, -4050, -4054, -4057, -4061, -4064, -4067, -4070, -4072
    word  -4075, -4077, -4079, -4081, -4083, -4085, -4087, -4088, -4090, -4091, -4092, -4093, -4093, -4094, -4094, -4094
    word  -4094, -4094, -4094, -4094, -4093, -4093, -4092, -4091, -4090, -4088, -4087, -4085, -4083, -4081, -4079, -4077
    word  -4075, -4072, -4070, -4067, -4064, -4061, -4057, -4054, -4050, -4046, -4042, -4038, -4034, -4030, -4025, -4021
    word  -4016, -4011, -4006, -4000, -3995, -3989, -3984, -3978, -3972, -3966, -3959, -3953, -3946, -3939, -3932, -3925
    word  -3918, -3911, -3903, -3896, -3888, -3880, -3872, -3863, -3855, -3847, -3838, -3829, -3820, -3811, -3802, -3792
    word  -3783, -3773, -3763, -3753, -3743, -3733, -3723, -3712, -3701, -3691, -3680, -3668, -3657, -3646, -3634, -3623
    word  -3611, -3599, -3587, -3575, -3562, -3550, -3537, -3525, -3512, -3499, -3486, -3473, -3459, -3446, -3432, -3418
    word  -3404, -3390, -3376, -3362, -3347, -3333, -3318, -3304, -3289, -3274, -3258, -3243, -3228, -3212, -3197, -3181
    word  -3165, -3149, -3133, -3117, -3100, -3084, -3067, -3050, -3034, -3017, -3000, -2983, -2965, -2948, -2930, -2913
    word  -2895, -2877, -2859, -2841, -2823, -2805, -2787, -2768, -2749, -2731, -2712, -2693, -2674, -2655, -2636, -2617
    word  -2597, -2578, -2558, -2539, -2519, -2499, -2479, -2459, -2439, -2419, -2398, -2378, -2357, -2337, -2316, -2295
    word  -2275, -2254, -2233, -2211, -2190, -2169, -2148, -2126, -2105, -2083, -2061, -2040, -2018, -1996, -1974, -1952
    word  -1930, -1908, -1885, -1863, -1841, -1818, -1796, -1773, -1750, -1728, -1705, -1682, -1659, -1636, -1613, -1590
    word  -1567, -1543, -1520, -1497, -1473, -1450, -1426, -1403, -1379, -1355, -1332, -1308, -1284, -1260, -1236, -1212
    word  -1188, -1164, -1140, -1116, -1092, -1067, -1043, -1019, -0994, -0970, -0946, -0921, -0897, -0872, -0848, -0823
    word  -0798, -0774, -0749, -0724, -0700, -0675, -0650, -0625, -0600, -0575, -0551, -0526, -0501, -0476, -0451, -0426
    word  -0401, -0376, -0351, -0326, -0301, -0276, -0251, -0225, -0200, -0175, -0150, -0125, -0100, -0075, -0050, -0025
'----------------------------------------------------------------------------------------------------------------------

'----------------------------------------------------------------------------------------------------------------------
'    This file is distributed under the terms of the The MIT License as follows:
'
'    Copyright (c) 2011 Michael Rychlik
'
'    Permission is hereby granted, free of charge, to any person obtaining a copy
'    of this software and associated documentation files (the "Software"), to deal
'    in the Software without restriction, including without limitation the rights
'    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
'    copies of the Software, and to permit persons to whom the Software is
'    furnished to do so, subject to the following conditions:
'
'    The above copyright notice and this permission notice shall be included in
'    all copies or substantial portions of the Software.
'
'    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
'    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
'    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
'    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
'    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
'    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
'    THE SOFTWARE.
'----------------------------------------------------------------------------------------------------------------------
'The end.

