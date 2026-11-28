import time,sys
from supertonic import TTS
t=time.time(); tts=TTS(auto_download=True); print("load+download %.1fs"%(time.time()-t))
try: print("voices", tts.voice_style_names)
except Exception as e: print("voices?",e)
T={"fr":"Bonjour, je suis Praxis, l'assistant de Rewayah Academy. Aujourd'hui, je vous explique comment fonctionne une classe, en trente secondes.",
"en":"Hello, I am Praxis, the assistant of Rewayah Academy. Today I will show you how a class works, in thirty seconds.",
"ar":"مرحبا، أنا براكسيس، مساعد أكاديمية رواية. اليوم أشرح لكم كيف يعمل الفصل في ثلاثين ثانية."}
for v in ["F1","M1"]:
    st=tts.get_voice_style(voice_name=v)
    for l,x in T.items():
        t=time.time(); wav,dur=tts.synthesize(x,voice_style=st,lang=l); d=time.time()-t
        tts.save_audio(wav,f"{sys.argv[1]}/supertonic_{l}_{v}.wav"); print(v,l,"synth %.2fs audio %.2fs RTF %.3f"%(d,float(dur[0]),d/float(dur[0])))
