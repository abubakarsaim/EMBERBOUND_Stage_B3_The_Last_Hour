"""Generate original EMBERBOUND A3 audio. Optional authoring dependency: Python + NumPy.
Runtime uses the committed WAVs and has no Python dependency. No samples are downloaded.
"""
from pathlib import Path
import numpy as np
import wave,json
ROOT=Path(__file__).resolve().parents[1]/'assets/audio';ROOT.mkdir(parents=True,exist_ok=True)
SR=22050;RNG=np.random.default_rng(583861);TAU=2*np.pi
stats={}
def write(name,a,loop=False):
 a=np.nan_to_num(a);peak=float(np.max(np.abs(a)))
 if peak>.78:a=a*(.78/peak)
 # Loops are intentionally circular; identical endpoints remove a splice step.
 if loop:a[-1]=a[0]
 pcm=np.round(np.clip(a,-.99,.99)*32767).astype('<i2')
 with wave.open(str(ROOT/(name+'.wav')),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes(pcm.tobytes())
 stats[name]={'samples':len(a),'seconds':len(a)/SR,'peak':float(np.max(np.abs(a))),'rms':float(np.sqrt(np.mean(a*a))),'loop':loop,'join_step':float(abs(a[-1]-a[0]))}
def noise(n,smooth=1):
 a=RNG.normal(0,1,n)
 if smooth>1:a=np.convolve(a,np.ones(smooth)/smooth,mode='same')
 return a
def fade(a,in_s=.008,out_s=.08):
 ni=min(len(a),int(in_s*SR));no=min(len(a),int(out_s*SR))
 a[:ni]*=np.linspace(0,1,ni);a[-no:]*=np.linspace(1,0,no);return a
def add_event(a,start,event):
 idx=int(start*SR)
 # Circularly place tails, so the beginning already contains last-bar reverberation.
 inds=(idx+np.arange(len(event)))%len(a);np.add.at(a,inds,event)
def metallic(freq,dur=2.7):
 t=np.arange(int(dur*SR))/SR
 return sum(np.sin(TAU*freq*r*t)*np.exp(-t*d)*amp for r,d,amp in [(1,1.4,.25),(2.01,2.2,.10),(3.98,3.7,.05)])*(1-np.exp(-t*40))
# Eight bars at 80 BPM. All sustained oscillator cycles and modulations repeat in 24 s.
D=24.0;t=np.arange(int(D*SR))/SR
q=lambda f:round(f*D)/D
explore=np.zeros_like(t)
for f,amp in [(73.416,.12),(110,.035),(146.832,.026)]:
 explore+=amp*np.sin(TAU*q(f)*t)*(0.86+.14*np.cos(TAU*t/D))
chords=[(146.832,174.614,220.0),(116.541,146.832,174.614),(97.999,116.541,146.832),(110.0,146.832,164.814)]
for k,chord in enumerate(chords):
 center=k*6+3;dist=(t-center+D/2)%D-D/2;env=np.where(abs(dist)<6,.5+.5*np.cos(np.pi*dist/6),0)
 for i,f in enumerate(chord):
  string=np.sin(TAU*q(f)*t+.008*np.sin(TAU*3*t/D))+.26*np.sin(TAU*q(f*2)*t)+.10*np.sin(TAU*q(f*3)*t)
  explore+=env*string*.036/(1+i*.18)
for start,f in [(1.5,440),(6,349.228),(10.5,293.665),(15,391.995),(19.5,329.628),(22.5,293.665)]:
 add_event(explore,start,metallic(f)*.28)
# A very sparse plucked, lute-like four-note answer.
for start,f in [(3,293.665),(4.5,349.228),(12,261.626),(13.5,220)]:
 tt=np.arange(int(SR*1.4))/SR
 pluck=(np.sin(TAU*f*tt)+.3*np.sin(TAU*f*2*tt)+.1*np.sin(TAU*f*3*tt))*np.exp(-tt*4)*(1-np.exp(-tt*150))
 add_event(explore,start,pluck*.055)
write('exploration',explore,True)
pursuit=np.zeros_like(t)
for k in range(32):
 tt=np.arange(int(.7*SR))/SR
 drum=(np.sin(TAU*(48*tt+32*(1-np.exp(-tt*11))/11))*np.exp(-tt*9)+noise(len(tt),9)*np.exp(-tt*22)*.13)
 add_event(pursuit,k*.75,drum*(.22 if k%4==0 else .13))
 if k%2:
  tt=np.arange(int(.2*SR))/SR;tap=noise(len(tt),3)*np.exp(-tt*32)*.07
  add_event(pursuit,k*.75+.375,tap)
pursuit+=.05*np.sin(TAU*q(36.708)*t)*(0.7+0.3*np.cos(TAU*t*32/D))
pursuit+=.025*np.sin(TAU*q(155.563)*t)*(.5+.5*np.sin(TAU*t*4/D))
write('pursuit',pursuit,True)
# Periodic band-limited noise for a circular, non-clicking fire loop.
n=len(t[:int(4*SR)]);freq=np.fft.rfftfreq(n,1/SR);spec=(RNG.normal(size=len(freq))+1j*RNG.normal(size=len(freq)))
spec*=np.exp(-freq/4800)*(1-np.exp(-freq/170));fire=np.fft.irfft(spec,n=n);fire=fire/(np.std(fire)+1e-9)*.085
for k in range(34):
 tt=np.arange(int(.065*SR))/SR;pop=noise(len(tt),2)*np.exp(-tt*100)*(1-np.exp(-tt*1500))*.15
 add_event(fire,RNG.uniform(0,4),pop)
write('fire_loop',fire,True)
dur=1.35;tt=np.arange(int(SR*dur))/SR
whoosh=noise(len(tt),5)*(tt/.12)*np.exp(-tt*10)*1.6
crackle=noise(len(tt),2)*np.exp(-np.maximum(0,tt-.18)*2.4)*.045
ignition=whoosh+crackle+.05*np.sin(TAU*(90*tt+40*tt*tt))*np.exp(-tt*7)
for start in [.17,.29,.43,.61,.83,1.03]:
 popt=np.arange(int(.04*SR))/SR;pop=noise(len(popt))*np.exp(-popt*140)*.18
 idx=int(start*SR);ignition[idx:idx+len(pop)]+=pop
write('ignition',fade(ignition))
# Related spectral palette for shadow and time, with restrained transient levels.
for name,duration in [('charge',.8),('launch',.34),('impact',.5),('freeze',.75),('time_end',.45),('low_flame',.55),('gate',1.2),('success',1.6),('checkpoint',.7),('failure',1.2)]:
 tt=np.arange(int(duration*SR))/SR;u=tt/duration
 if name=='charge':a=(.15*np.sin(TAU*(70*tt+170*tt*tt))+.13*noise(len(tt),12))*u**1.8
 elif name=='launch':a=(noise(len(tt),4)*.3+.12*np.sin(TAU*(120*tt-90*tt*tt)))*np.exp(-tt*10)
 elif name=='impact':a=(noise(len(tt),8)*.36+.18*np.sin(TAU*(61*tt+20*(1-np.exp(-tt*12))/12)))*np.exp(-tt*9)
 elif name=='freeze':a=(.12*np.sin(TAU*(720*tt-180*tt*tt))+.07*np.sin(TAU*1079*tt)+noise(len(tt),10)*.08)*np.sin(np.pi*u)*np.exp(-tt*1.5)
 elif name=='time_end':a=(.10*np.sin(TAU*(360*tt+280*tt*tt))+.04*noise(len(tt),6))*np.sin(np.pi*u)
 elif name=='low_flame':a=.12*np.sin(TAU*110*tt)*np.sin(np.pi*u)**2*(.5+.5*np.cos(TAU*4*tt))
 elif name=='gate':a=(noise(len(tt),20)*.22+.08*np.sin(TAU*55*tt))*np.sin(np.pi*u)*np.exp(-tt*1.5)+.08*np.sin(TAU*293.665*tt)*np.exp(-tt*2)*np.sin(np.pi*u)
 elif name=='success':
  a=np.zeros_like(tt)
  for offset,f in [(0,293.665),(.16,349.228),(.32,440),(.48,587.33)]:
   v=np.maximum(0,tt-offset);a+=.10*np.sin(TAU*f*v)*np.exp(-v*3)*(1-np.exp(-v*30))*(tt>=offset)
 elif name=='checkpoint':a=(.10*np.sin(TAU*293.665*tt)+.06*np.sin(TAU*440*tt))*np.sin(np.pi*u)*np.exp(-tt*2)
 else:a=(.16*np.sin(TAU*(110*tt-18*tt*tt))+.09*np.sin(TAU*73.416*tt))*np.sin(np.pi*u)*np.exp(-tt*1.5)
 write(name,fade(a))
(ROOT/'AUDIO_ANALYSIS.json').write_text(json.dumps(stats,indent=2)+'\n')
print('Generated',len(stats),'original WAVs;',sum((ROOT/(k+'.wav')).stat().st_size for k in stats),'bytes')
