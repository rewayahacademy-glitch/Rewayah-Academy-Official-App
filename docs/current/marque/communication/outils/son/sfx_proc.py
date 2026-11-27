"""SFX proceduraux sans instrument : bruit filtre, modeles physiques simples. numpy+scipy seulement."""
import sys,time,numpy as np,soundfile as sf
from scipy import signal
SR=48000; out=sys.argv[1]; rng=np.random.default_rng(7)
def env(n,a,r,curve=2.0):
    t=np.linspace(0,1,n); pk=a
    return np.where(t<pk,(t/pk)**curve,((1-t)/(1-pk))**curve)
def sweep_bp(x,f0,f1,q=1.2,hop=256):
    # passe-bande dont la frequence glisse (bloc par bloc, etat conserve)
    y=np.zeros_like(x); zi=np.zeros(2); n=len(x)
    for i in range(0,n,hop):
        f=f0*(f1/f0)**(i/n); b,a=signal.iirpeak(f/(SR/2),q) if False else signal.butter(1,[f/1.6/(SR/2),min(f*1.6/(SR/2),0.99)],'band')
        seg,zi=signal.lfilter(b,a,x[i:i+hop],zi=zi); y[i:i+hop]=seg
    return y
def norm(x,peak=0.7): return x/np.max(np.abs(x)+1e-9)*peak
def stereo(l,r): return np.stack([l,r],1)
t0=time.time()
# 1 whoosh : bruit rose-ish, filtre glissant, enveloppe asymetrique (pic a 70 %), leger doppler stereo
n=int(0.6*SR); nz=rng.standard_normal(n); nz=signal.lfilter(*signal.butter(1,3000/(SR/2)),nz)
w=sweep_bp(nz,300,5000)*env(n,0.7,0,2.5); pan=np.linspace(0.2,0.8,n)
sf.write(f"{out}/sfx_whoosh.wav",norm(stereo(w*(1-pan),w*pan)),SR)
# 2 porte lourde : grincement = impulsions stick-slip excitees dans des resonances de bois + choc grave
n=int(1.6*SR); t=np.arange(n)/SR; rate=18+50*np.sin(np.pi*t/1.6)**2; ph=np.cumsum(rate)/SR
imp=(np.diff(np.floor(ph),prepend=0)>0).astype(float)*(0.6+0.4*rng.random(n))
cr=sum(signal.lfilter(*signal.iirpeak(f/(SR/2),Q),imp) for f,Q in [(310,25),(540,30),(910,22),(1480,18)])
cr=cr*env(n,0.5,0,1.2); th_n=int(0.5*SR); tt=np.arange(th_n)/SR
thud=np.sin(2*np.pi*(70*tt-25*tt**2))*np.exp(-tt*14)+0.3*signal.lfilter(*signal.butter(2,400/(SR/2)),rng.standard_normal(th_n))*np.exp(-tt*30)
door=np.concatenate([norm(cr,0.5),norm(thud,0.8)])
sf.write(f"{out}/sfx_porte.wav",stereo(door,door),SR)
# 3 lumiere, version NON tonale : souffle d'air aigu qui s'ouvre (passe-haut glissant) + grain scintillant
n=int(2.5*SR); nz=rng.standard_normal(n); air=sweep_bp(nz,1500,9000)*env(n,0.6,0,1.5)
grains=np.zeros(n)
for _ in range(220):
    p=int(rng.random()**0.6*(n-2000)); g=rng.standard_normal(600)*np.hanning(600); grains[p:p+600]+=signal.lfilter(*signal.butter(2,[6000/(SR/2),14000/(SR/2)],'band'),g)*rng.random()
lum=norm(air,0.5)+norm(grains,0.25)*env(n,0.5,0,1.0)
sf.write(f"{out}/sfx_lumiere_air.wav",norm(stereo(lum,np.roll(lum,37))),SR)
# 4 lumiere, version TONALE (ZONE GRISE : son a hauteur definie, sans instrument) : bruit dans des resonateurs accordes
res=sum(signal.lfilter(*signal.iirpeak(f/(SR/2),120),nz) for f in [440,660,880,1320])
sf.write(f"{out}/sfx_lumiere_tonale_ZONE_GRISE.wav",norm(stereo(res*env(n,0.6,0,1.5),np.roll(res,53)*env(n,0.6,0,1.5))),SR)
# 5 room tone : bruit brun tres bas
n=int(5*SR); br=np.cumsum(rng.standard_normal(n)); br=signal.lfilter(*signal.butter(2,[60/(SR/2),1200/(SR/2)],'band'),br)
sf.write(f"{out}/sfx_roomtone.wav",norm(stereo(br,np.roll(br,4001)),0.05),SR)
print("5 SFX generes en %.2fs"%(time.time()-t0))
