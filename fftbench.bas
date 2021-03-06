' Heaters FFT Benchmark
' ---------------------
' made by Andy Schenk Mar 2011

 #FFT_SIZE  = 1024
 #LOG2_SIZE = 10

 dim bx[#FFT_SIZE]
 dim by[#FFT_SIZE]
 dim starttime, endtime
 dim i,k,f,revi,tx,ty, magn
 dim k1,k2,k3,a,b,c,d,flSize,wIndex
 dim noFlights,b0,b1,
 dim level,flight,bfly,flIndex

cod
 serout(0)
 serstr("fft_bench v1.0\n")
 fillInput()
 starttime = cnt
 decimate()
 butterflies()
 endtime = cnt
 prntSpectrum()
 serstr("1024 point bit reversal and butterfly\n")
 serstr("run time = ")
 t2 = clkfreq() / 1000
' t2 = 80_000  'time with 5MHz crystal
 t1 = endtime-starttime/t2
 t$ = str$(t1) + "ms\n"
 serstr(t$)
 serinp()
 end

sub fillInput
 k=0: repeat
   t1 = k*3 // 16 << 1
   bx[k] = peekw(t1+@input) ~16 / 4
   t1 = k*5 // 16 << 1
   bx[k] = peekw(t1+@input) ~16 / 4 + bx[k]
   t1 = 4096/8
   if k&1 > 0
     bx[k] = bx[k] + t1
   else
     bx[k] = bx[k] - t1
   endif
   bx[k] = bx[k] + t1
   by[k] = 0
 k+1: until k == #FFT_SIZE
endsub

sub decimate
 i=0: repeat
   t1 = 32-#LOG2_SIZE
   revi = i >< t1
   if i < revi
     tx=bx[i]: ty=by[i]
     bx[i] = bx[revi]
     by[i] = by[revi]
     bx[revi] = tx
     by[revi] = ty
   endif
 i+1: until i == #FFT_SIZE
endsub

sub butterflies
 flSize=1
 noFlights = #FFT_SIZE >> 1
 level=0: repeat
   flIndex = 0
   flight=0: repeat
     wIndex=0
     bfly=0: repeat
       b0 = flIndex + bfly
       b1 = b0 + flSize
       a = bx[b1]
       b = by[b1]
       c = peekw(wIndex<<1+@wx) ~16
       d = peekw(wIndex<<1+@wy) ~16
       k1 = c+d * a ~> 12
       k2 = a+b * d ~> 12
       k3 = b-a * c ~> 12
       tx = k1 - k2
       ty = k1 + k3
       k1 = bx[b0]
       k2 = by[b0]
       bx[b1] = k1 - tx
       by[b1] = k2 - ty
       bx[b0] = k1 + tx
       by[b0] = k2 + ty
       wIndex + noFlights
     bfly+1: until bfly >= flSize
     flIndex + flSize + flSize
   flight+1: until flight >= noFlights
   flSize << 1
   noFlights >> 1
 level+1: until level == #LOG2_SIZE
endsub

sub prntSpectrum
 serstr("Freq.    Magnitude\n")
 f=0: repeat
   t1 = bx[f] / #FFT_SIZE
   t2 = by[f] / #FFT_SIZE
   t3=t1*t1: t1=t2*t2
   magn = sqr(t1 + t3)
   if magn > 0
     t$ = hex$(f,8) + chr$(32)+ hex$(magn,8) + chr$(13)
     serstr(t$)
   endif
 f+1: until f*2 > #FFT_SIZE
endsub

dat
input
 word 4096,3784,2896,1567,0, -1567, -2896, -3784
 word -4096, -3784, -2896, -1567,0,1567,2896,3784

wx
 word  04095, 04094, 04094, 04094, 04093, 04093, 04092, 04091
 word  04090, 04088, 04087, 04085, 04083, 04081, 04079, 04077
 word  04075, 04072, 04070, 04067, 04064, 04061, 04057, 04054
 word  04050, 04046, 04042, 04038, 04034, 04030, 04025, 04021
 word  04016, 04011, 04006, 04000, 03995, 03989, 03984, 03978
 word  03972, 03966, 03959, 03953, 03946, 03939, 03932, 03925
 word  03918, 03911, 03903, 03896, 03888, 03880, 03872, 03864
 word  03855, 03847, 03838, 03829, 03820, 03811, 03802, 03792
 word  03783, 03773, 03763, 03753, 03743, 03733, 03723, 03712
 word  03701, 03691, 03680, 03668, 03657, 03646, 03634, 03623
 word  03611, 03599, 03587, 03575, 03563, 03550, 03537, 03525
 word  03512, 03499, 03486, 03473, 03459, 03446, 03432, 03418
 word  03404, 03390, 03376, 03362, 03348, 03333, 03318, 03304
 word  03289, 03274, 03258, 03243, 03228, 03212, 03197, 03181
 word  03165, 03149, 03133, 03117, 03100, 03084, 03067, 03051
 word  03034, 03017, 03000, 02983, 02965, 02948, 02930, 02913
 word  02895, 02877, 02859, 02841, 02823, 02805, 02787, 02768
 word  02750, 02731, 02712, 02693, 02674, 02655, 02636, 02617
 word  02597, 02578, 02558, 02539, 02519, 02499, 02479, 02459
 word  02439, 02419, 02398, 02378, 02357, 02337, 02316, 02295
 word  02275, 02254, 02233, 02211, 02190, 02169, 02148, 02126
 word  02105, 02083, 02061, 02040, 02018, 01996, 01974, 01952
 word  01930, 01908, 01885, 01863, 01841, 01818, 01796, 01773
 word  01750, 01728, 01705, 01682, 01659, 01636, 01613, 01590
 word  01567, 01543, 01520, 01497, 01473, 01450, 01426, 01403
 word  01379, 01355, 01332, 01308, 01284, 01260, 01236, 01212
 word  01188, 01164, 01140, 01116, 01092, 01067, 01043, 01019
 word  00994, 00970, 00946, 00921, 00897, 00872, 00848, 00823
 word  00798, 00774, 00749, 00724, 00700, 00675, 00650, 00625
 word  00600, 00575, 00551, 00526, 00501, 00476, 00451, 00426
 word  00401, 00376, 00351, 00326, 00301, 00276, 00251, 00226
 word  00200, 00175, 00150, 00125, 00100, 00075, 00050, 00025
wy
 word  00000, -0025, -0050, -0075, -0100, -0125, -0150, -0175
 word  -0200, -0226, -0251, -0276, -0301, -0326, -0351, -0376
 word  -0401, -0426, -0451, -0476, -0501, -0526, -0551, -0576
 word  -0600, -0625, -0650, -0675, -0700, -0724, -0749, -0774
 word  -0798, -0823, -0848, -0872, -0897, -0921, -0946, -0970
 word  -0995, -1019, -1043, -1067, -1092, -1116, -1140, -1164
 word  -1188, -1212, -1236, -1260, -1284, -1308, -1332, -1355
 word  -1379, -1403, -1426, -1450, -1473, -1497, -1520, -1543
 word  -1567, -1590, -1613, -1636, -1659, -1682, -1705, -1728
 word  -1750, -1773, -1796, -1818, -1841, -1863, -1885, -1908
 word  -1930, -1952, -1974, -1996, -2018, -2040, -2062, -2083
 word  -2105, -2126, -2148, -2169, -2190, -2212, -2233, -2254
 word  -2275, -2295, -2316, -2337, -2357, -2378, -2398, -2419
 word  -2439, -2459, -2479, -2499, -2519, -2539, -2558, -2578
 word  -2597, -2617, -2636, -2655, -2674, -2693, -2712, -2731
 word  -2750, -2768, -2787, -2805, -2823, -2841, -2859, -2877
 word  -2895, -2913, -2930, -2948, -2965, -2983, -3000, -3017
 word  -3034, -3051, -3067, -3084, -3100, -3117, -3133, -3149
 word  -3165, -3181, -3197, -3212, -3228, -3243, -3258, -3274
 word  -3289, -3304, -3318, -3333, -3348, -3362, -3376, -3390
 word  -3404, -3418, -3432, -3446, -3459, -3473, -3486, -3499
 word  -3512, -3525, -3537, -3550, -3563, -3575, -3587, -3599
 word  -3611, -3623, -3634, -3646, -3657, -3668, -3680, -3691
 word  -3701, -3712, -3723, -3733, -3743, -3753, -3763, -3773
 word  -3783, -3792, -3802, -3811, -3820, -3829, -3838, -3847
 word  -3855, -3864, -3872, -3880, -3888, -3896, -3903, -3911
 word  -3918, -3925, -3932, -3939, -3946, -3953, -3959, -3966
 word  -3972, -3978, -3984, -3989, -3995, -4000, -4006, -4011
 word  -4016, -4021, -4025, -4030, -4034, -4038, -4043, -4046
 word  -4050, -4054, -4057, -4061, -4064, -4067, -4070, -4072
 word  -4075, -4077, -4079, -4081, -4083, -4085, -4087, -4088
 word  -4090, -4091, -4092, -4093, -4093, -4094, -4094, -4094
 word  -4094, -4094, -4094, -4094, -4093, -4093, -4092, -4091
 word  -4090, -4088, -4087, -4085, -4083, -4081, -4079, -4077
 word  -4075, -4072, -4070, -4067, -4064, -4061, -4057, -4054
 word  -4050, -4046, -4042, -4038, -4034, -4030, -4025, -4021
 word  -4016, -4011, -4006, -4000, -3995, -3989, -3984, -3978
 word  -3972, -3966, -3959, -3953, -3946, -3939, -3932, -3925
 word  -3918, -3911, -3903, -3896, -3888, -3880, -3872, -3863
 word  -3855, -3847, -3838, -3829, -3820, -3811, -3802, -3792
 word  -3783, -3773, -3763, -3753, -3743, -3733, -3723, -3712
 word  -3701, -3691, -3680, -3668, -3657, -3646, -3634, -3623
 word  -3611, -3599, -3587, -3575, -3562, -3550, -3537, -3525
 word  -3512, -3499, -3486, -3473, -3459, -3446, -3432, -3418
 word  -3404, -3390, -3376, -3362, -3347, -3333, -3318, -3304
 word  -3289, -3274, -3258, -3243, -3228, -3212, -3197, -3181
 word  -3165, -3149, -3133, -3117, -3100, -3084, -3067, -3050
 word  -3034, -3017, -3000, -2983, -2965, -2948, -2930, -2913
 word  -2895, -2877, -2859, -2841, -2823, -2805, -2787, -2768
 word  -2749, -2731, -2712, -2693, -2674, -2655, -2636, -2617
 word  -2597, -2578, -2558, -2539, -2519, -2499, -2479, -2459
 word  -2439, -2419, -2398, -2378, -2357, -2337, -2316, -2295
 word  -2275, -2254, -2233, -2211, -2190, -2169, -2148, -2126
 word  -2105, -2083, -2061, -2040, -2018, -1996, -1974, -1952
 word  -1930, -1908, -1885, -1863, -1841, -1818, -1796, -1773
 word  -1750, -1728, -1705, -1682, -1659, -1636, -1613, -1590
 word  -1567, -1543, -1520, -1497, -1473, -1450, -1426, -1403
 word  -1379, -1355, -1332, -1308, -1284, -1260, -1236, -1212
 word  -1188, -1164, -1140, -1116, -1092, -1067, -1043, -1019
 word  -0994, -0970, -0946, -0921, -0897, -0872, -0848, -0823
 word  -0798, -0774, -0749, -0724, -0700, -0675, -0650, -0625
 word  -0600, -0575, -0551, -0526, -0501, -0476, -0451, -0426
 word  -0401, -0376, -0351, -0326, -0301, -0276, -0251, -0225
 word  -0200, -0175, -0150, -0125, -0100, -0075, -0050, -0025
'