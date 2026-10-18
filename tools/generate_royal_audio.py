"""Original Royal Hall synthesis, CC0. Optional NumPy authoring; runtime uses local WAVs."""
from pathlib import Path
import numpy as np,wave,json
R=Path(__file__).resolve().parents[1]/'assets/audio';SR=22050;rng=np.random.default_rng(511832);stats={}
def write(name,a,loop=False):
 a=np.nan_to_num(a)
 if max(abs(a))>.75:a=a*.75/max(abs(a))
 if loop:a[-1]=a[0]
 pcm=np.round(np.clip(a,-.99,.99)*32767).astype('<i2')
 with wave.open(str(R/(name+'.wav')),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
 stats[name]={'samples':len(a),'seconds':len(a)/SR,'peak':float(abs(a).max()),'rms':float(np.sqrt(np.mean(a*a))),'loop':loop,'join_step':float(abs(a[-1]-a[0]))}
def noise(n,s=1):
 a=rng.normal(size=n)
 return np.convolve(a,np.ones(s)/s,'same') if s>1 else a
def bell(freq,duration=2.8):
 t=np.arange(int(duration*SR))/SR
 return sum(amp*np.sin(2*np.pi*freq*ratio*t)*np.exp(-t*damp) for ratio,amp,damp in [(1,.16,1.7),(2.01,.055,2.5),(3.94,.025,3.5)])*(1-np.exp(-t*90))
def event(a,start,b):np.add.at(a,(int(start*SR)+np.arange(len(b)))%len(a),b)
D=24;t=np.arange(int(D*SR))/SR;q=lambda f:round(f*D)/D
pale=np.zeros_like(t)
for f,amp in [(65.406,.07),(130.813,.035),(195.998,.018)]:pale+=amp*np.sin(2*np.pi*q(f)*t)*(.8+.2*np.cos(2*np.pi*t/D))
chords=[(130.813,155.563,195.998),(103.826,130.813,155.563),(87.307,103.826,130.813),(97.999,130.813,146.832)]
for j,ch in enumerate(chords):
 dist=(t-(j*6+3)+D/2)%D-D/2;env=np.where(abs(dist)<6,.5+.5*np.cos(np.pi*dist/6),0)
 for f in ch:pale+=.035*env*(np.sin(2*np.pi*q(f)*t)+.2*np.sin(2*np.pi*q(f*2)*t))
# An original quiet, descending answer; no existing song or sampled material.
for start,f in [(1,523.251),(3.25,466.164),(5.5,391.995),(9,311.127),(12.75,349.228),(15,391.995),(18,293.665),(21,261.626)]:event(pale,start,bell(f)*.55)
write('royal_music',pale,True)
dark=.065*np.sin(2*np.pi*q(32.703)*t)+.035*np.sin(2*np.pi*q(138.591)*t)*(.5+.5*np.sin(2*np.pi*t/6))
for start in np.arange(0,24,1.5):
 u=np.arange(int(.8*SR))/SR
 pulse=(np.sin(2*np.pi*(45*u+20*(1-np.exp(-u*9))/9))*.16+noise(len(u),14)*.035)*np.exp(-u*7)*(1-np.exp(-u*200))
 event(dark,start,pulse)
write('royal_revelation',dark,True)
D=12;n=SR*D;t=np.arange(n)/SR;f=np.fft.rfftfreq(n,1/SR);spec=(rng.normal(size=len(f))+1j*rng.normal(size=len(f)))*np.exp(-f/1800)*(1-np.exp(-f/65));amb=np.fft.irfft(spec,n);amb=amb/(np.std(amb)+1e-12)*.027
amb+=.018*np.sin(2*np.pi*48*t)*(.75+.25*np.cos(2*np.pi*t/D));write('royal_ambience',amb,True)
for name,dur in [('royal_door',1.3),('royal_mirror',.85),('royal_seal',.95),('dialogue_tick',.045),('illusion_distort',1.6),('revelation_finish',1.8),('royal_passage',1.4)]:
 u=np.arange(int(dur*SR))/SR;v=u/dur
 if name=='royal_door':a=(noise(len(u),20)*.18+.08*np.sin(2*np.pi*(58*u+7*u*u)))*np.sin(np.pi*v)**1.3
 elif name=='royal_mirror':a=(.10*np.sin(2*np.pi*(820*u-190*u*u))+.04*np.sin(2*np.pi*1230*u))*np.sin(np.pi*v)**2
 elif name=='royal_seal':a=sum(.07*np.sin(2*np.pi*f*u) for f in [261.626,391.995,523.251])*np.sin(np.pi*v)*np.exp(-u*1.4)
 elif name=='dialogue_tick':a=.022*np.sin(2*np.pi*660*u)*np.sin(np.pi*v)**2+.01*noise(len(u),3)*np.sin(np.pi*v)**2
 elif name=='illusion_distort':a=(noise(len(u),11)*.22+.10*np.sin(2*np.pi*(100*u-25*u*u))+.05*np.sin(2*np.pi*203*u))*(np.sin(np.pi*v)**1.5)
 elif name=='revelation_finish':a=sum(.065*np.sin(2*np.pi*f*u)*np.exp(-u*(1.2+i*.2)) for i,f in enumerate([130.813,261.626,311.127,391.995,523.251]))*(1-np.exp(-u*35))
 else:a=(noise(len(u),23)*.1+.065*np.sin(2*np.pi*65.406*u)+.05*np.sin(2*np.pi*(293.665*u+45*u*u)))*np.sin(np.pi*v)**1.3
 fade=int(.04*SR);a[:min(fade,len(a))]*=np.linspace(0,1,min(fade,len(a)));a[-min(fade,len(a)):]*=np.linspace(1,0,min(fade,len(a)));write(name,a)
(R/'ROYAL_AUDIO_ANALYSIS.json').write_text(json.dumps(stats,indent=2)+'\n')
