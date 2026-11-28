import time, sys, soundfile as sf
from kokoro_onnx import Kokoro
t=time.time(); k=Kokoro(sys.argv[1]+"/kokoro-v1.0.onnx", sys.argv[1]+"/voices-v1.0.bin"); print("load %.2fs"%(time.time()-t))
tests=[("fr","ff_siwis","fr-fr","Bonjour, je suis Praxis, l'assistant de Rewayah Academy. Aujourd'hui, je vous explique comment fonctionne une classe, en trente secondes."),
("en","af_heart","en-us","Hello, I am Praxis, the assistant of Rewayah Academy. Today I will show you how a class works, in thirty seconds.")]
for tag,v,lang,txt in tests:
    t=time.time(); a,sr=k.create(txt,voice=v,speed=1.0,lang=lang); d=time.time()-t
    sf.write(f"{sys.argv[2]}/kokoro_{tag}.wav",a,sr); print(tag,v,"synth %.2fs audio %.2fs RTF %.2f sr %d"%(d,len(a)/sr,d/(len(a)/sr),sr))
print(sorted(k.get_voices()))
