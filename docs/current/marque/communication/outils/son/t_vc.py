import sys,time,soundfile as sf,numpy as np
from pedalboard import Pedalboard, PitchShift, HighpassFilter, Compressor, HighShelfFilter, Reverb, Limiter
a,sr=sf.read(sys.argv[1],dtype='float32'); t=time.time()
b=Pedalboard([HighpassFilter(120),PitchShift(4),HighShelfFilter(6000,3.0),Compressor(-18,3,5,80),Reverb(room_size=0.08,wet_level=0.06,dry_level=1.0),Limiter(-1.0)])
o=b(a,sr); sf.write(sys.argv[2],o,sr); print("pedalboard chain %.2fs for %.2fs audio"%(time.time()-t,len(a)/sr))
