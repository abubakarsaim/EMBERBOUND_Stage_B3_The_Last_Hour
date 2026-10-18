"""Original B3 synthesis, CC0. No samples or existing melodies. Runtime uses local WAVs."""
from pathlib import Path
import numpy as np,wave,json
R=Path(__file__).resolve().parents[1]/'assets/audio';SR=22050;rng=np.random.default_rng(703071);stats={}
def write(name,a,loop=False):
 a=np.nan_to_num(a);peak=max(abs(a))
 if peak>.74:a*=.74/peak
 if loop:a[-1]=a[0]
 else:
  m=min(int(.025*SR),len(a)//2);a[:m]*=np.linspace(0,1,m);a[-m:]*=np.linspace(1,0,m)
 pcm=np.round(a*32767).astype('<i2')
 with wave.open(str(R/(name+'.wav')),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
 stats[name]={'seconds':len(a)/SR,'peak':float(abs(a).max()),'rms':float(np.sqrt(np.mean(a*a))),'loop':loop,'join_step':float(abs(a[-1]-a[0]))}
def noise(n,s=8):return np.convolve(rng.normal(size=n),np.ones(s)/s,'same')
def add(a,at,b):np.add.at(a,(int(at*SR)+np.arange(len(b)))%len(a),b)
def bell(f,d=2.5):
 u=np.arange(int(d*SR))/SR
 return sum(v*np.sin(2*np.pi*f*r*u)*np.exp(-u*k) for r,v,k in [(1,.15,1.6),(2.01,.04,2.7),(3.93,.02,3.5)])*(1-np.exp(-u*80))
D=24;t=np.arange(SR*D)/SR;q=lambda f:round(f*D)/D
clock=np.zeros_like(t);battle=np.zeros_like(t);rescue=np.zeros_like(t);dawn=np.zeros_like(t)
for f,v in [(55,.075),(110,.035),(164.814,.022)]:clock+=v*np.sin(2*np.pi*q(f)*t)*(.75+.25*np.cos(2*np.pi*t/D))
for k in range(48):
 u=np.arange(int(.095*SR))/SR;tick=(noise(len(u),2)*.026+.035*np.sin(2*np.pi*(1350 if k%2 else 980)*u))*np.exp(-u*55)
 add(clock,k*.5,tick)
minor=[(110,130.813,164.814),(87.307,110,130.813),(97.999,123.471,146.832),(82.407,110,130.813)]
major=[(130.813,164.814,195.998),(97.999,130.813,164.814),(110,146.832,174.614),(97.999,130.813,195.998)]
for j,chord in enumerate(minor):
 d=(t-(j*6+3)+D/2)%D-D/2;env=np.where(abs(d)<6,.5+.5*np.cos(np.pi*d/6),0)
 for f in chord:
  clock+=.032*env*np.sin(2*np.pi*q(f)*t)
  battle+=.029*env*(np.sin(2*np.pi*q(f*2)*t)+.15*np.sin(2*np.pi*q(f*3)*t))
  rescue+=.034*env*np.sin(2*np.pi*q(f*2)*t)
for at,f in [(0,440),(4,391.995),(7.5,329.628),(12,293.665),(16,261.626),(21,220)]:add(clock,at,bell(f)*.4)
for at in np.arange(0,24,.75):
 u=np.arange(int(.55*SR))/SR;kick=(.17*np.sin(2*np.pi*(43*u+16*(1-np.exp(-u*14))/14))+.045*noise(len(u),15))*np.exp(-u*8)*(1-np.exp(-u*120));add(battle,at,kick)
for at,f in [(1,329.628),(4.5,293.665),(8,261.626),(12,220),(16.5,261.626),(20,293.665)]:add(rescue,at,bell(f)*.55)
for j,chord in enumerate(major):
 d=(t-(j*6+3)+D/2)%D-D/2;env=np.where(abs(d)<6,.5+.5*np.cos(np.pi*d/6),0)
 for f in chord:dawn+=.052*env*(np.sin(2*np.pi*q(f)*t)+.28*np.sin(2*np.pi*q(f*2)*t)+.10*np.sin(2*np.pi*q(f*3)*t))
for at,f in [(0,261.626),(2.5,329.628),(5,391.995),(8,523.251),(12,493.883),(15,440),(18,391.995),(21,523.251)]:add(dawn,at,bell(f)*.5)
write('hour_clock',clock,True);write('hour_battle',battle,True);write('hour_rescue',rescue,True);write('hour_dawn',dawn,True)
for name,dur in [('anchor_break',1.1),('core_expose',.7),('core_hit',.9),('clock_sweep',1.6),('time_pulse',1.7),('prison_open',1.8),('flame_return',2.6),('clock_awaken',3.0),('boss_fall',2.3),('clock_lock',.35)]:
 u=np.arange(int(dur*SR))/SR;v=u/dur
 if name=='anchor_break':a=(noise(len(u),12)*.12+sum(.07*np.sin(2*np.pi*f*u)*np.exp(-u*2.4) for f in [110,220,329.628]))*np.sin(np.pi*v)**.5
 elif name=='core_expose':a=sum(.06*np.sin(2*np.pi*f*u) for f in [523.251,783.991,1046.502])*np.sin(np.pi*v)*np.exp(-u*1.5)
 elif name=='core_hit':a=(.12*np.sin(2*np.pi*(90*u+12*u*u))+.06*noise(len(u),7)+.04*np.sin(2*np.pi*659.255*u))*np.exp(-u*3)*(1-np.exp(-u*100))
 elif name=='clock_sweep':a=(noise(len(u),9)*.18+.08*np.sin(2*np.pi*(150*u-40*u*u)))*np.sin(np.pi*v)**2
 elif name=='time_pulse':a=(.10*np.sin(2*np.pi*(300*u-55*u*u))+.045*np.sin(2*np.pi*79*u))*np.sin(np.pi*v)**1.4
 elif name=='prison_open':a=sum(.065*np.sin(2*np.pi*f*u)*np.exp(-u*(1.1+i*.2)) for i,f in enumerate([261.626,329.628,391.995,523.251]))*(1-np.exp(-u*30))
 elif name=='flame_return':a=(.08*noise(len(u),24)+sum(.055*np.sin(2*np.pi*f*u) for f in [130.813,261.626,391.995]))*np.sin(np.pi*v)**1.8
 elif name=='clock_awaken':a=bell(130.813,3)+bell(261.626,3)*.7+bell(391.995,3)*.4
 elif name=='boss_fall':a=(.15*np.sin(2*np.pi*(65*u-11*u*u))+.16*noise(len(u),18))*np.sin(np.pi*v)**1.2
 else:a=(.06*noise(len(u),4)+.07*np.sin(2*np.pi*174.614*u))*np.exp(-u*12)*np.sin(np.pi*v)
 write(name,a)
(R/'B3_AUDIO_ANALYSIS.json').write_text(json.dumps(stats,indent=2)+'\n')
print('B3_AUDIO_CREATED',len(stats))
