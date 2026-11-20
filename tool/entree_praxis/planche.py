# planche.py <maquette.png> <application.png> <sortie.png> [tel|large]
# Pose la maquette (ecran seul, sans le cadre du telephone) et l'application cote a cote.
import sys
from PIL import Image
def ecran(im, fmt):
    im=im.convert("RGB"); w,h=im.size; px=im.load()
    def sombre(p): return p[0]<40 and p[1]<40 and p[2]<60
    xs=[x for x in range(w) if sum(sombre(px[x,y]) for y in range(0,h,4))>h/4/3]
    ys=[y for y in range(h) if sum(sombre(px[x,y]) for x in range(0,w,4))>w/4/3]
    if not xs or not ys: return im
    l,r,t,b=min(xs),max(xs),min(ys),max(ys)
    lw,lh=(390,844) if fmt=="tel" else (1200,760)
    m=12 if fmt=="tel" else 10
    k=(r-l+1)/(lw+2*m)
    d=int(round(m*k))
    return im.crop((l+d,t+d,r+1-d,b+1-d))
def main():
    a,b,out=sys.argv[1:4]; fmt=sys.argv[4] if len(sys.argv)>4 else "tel"
    H=844 if fmt=="tel" else 760
    m=ecran(Image.open(a),fmt); m=m.resize((int(m.width*H/m.height),H),Image.LANCZOS)
    p=Image.open(b).convert("RGB"); p=p.resize((int(p.width*H/p.height),H),Image.LANCZOS)
    g=24; o=Image.new("RGB",(m.width+p.width+3*g,H+2*g),(255,255,255))
    o.paste(m,(g,g)); o.paste(p,(m.width+2*g,g)); o.save(out)
main()
