"""Original B1 audio, CC0. Optional authoring: NumPy; committed WAVs need no dependency."""
from pathlib import Path
import numpy as np
import wave,json
R=Path(__file__).resolve().parents[1]/'assets/audio';SR=22050;rng=np.random.default_rng(511831);stats={}
def save(name,a,loop=False):
 a=np.asarray(a);a=np.clip(a,-.75,.75)
 if loop:a[-1]=a[0]
 pcm=(a*32767).astype('<i2')
 with wave.open(str(R/(name+'.wav')),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
 stats[name]={'seconds':len(a)/SR,'peak':float(abs(a).max()),'rms':float(np.sqrt(np.mean(a*a))),'loop':loop,'join_step':float(abs(a[-1]-a[0]))}
# A circular Fourier-noise wind bed, plus distant non-melodic bird/wood calls.
D=16;n=SR*D;t=np.arange(n)/SR;f=np.fft.rfftfreq(n,1/SR)
spectrum=(rng.normal(size=len(f))+1j*rng.normal(size=len(f)))*np.exp(-f/2100)*(1-np.exp(-f/90))
wind=np.fft.irfft(spectrum,n);wind=wind/(np.std(wind)+1e-10)*.075
wind*=.55+.25*np.cos(2*np.pi*t/D)+.12*np.cos(2*np.pi*3*t/D)
for start,freq in [(3.1,510),(9.6,390),(13.7,650)]:
 u=np.arange(int(1.3*SR))/SR
 call=(np.sin(2*np.pi*(freq*u+22*np.sin(u*3)))+.25*np.sin(2*np.pi*freq*1.49*u))*np.sin(np.pi*u/1.3)**2*.018
 idx=int(start*SR);np.add.at(wind,(idx+np.arange(len(call)))%n,call)
save('forest_ambience',wind,True)
u=np.arange(int(.13*SR))/SR
noise=rng.normal(size=len(u));noise=np.convolve(noise,np.ones(6)/6,'same')
a=(noise*.09+np.sin(2*np.pi*84*u)*.025)*np.exp(-u*32)*(1-np.exp(-u*600));a[-100:]*=np.linspace(1,0,100);save('footstep',a)
u=np.arange(int(.85*SR))/SR;a=sum(np.sin(2*np.pi*f*u)*np.exp(-u*(3+k))*.11 for k,f in enumerate([587.33,880,1174.66]));a*=1-np.exp(-u*90);a[-1000:]*=np.linspace(1,0,1000);save('rune',a)
u=np.arange(int(.45*SR))/SR;a=(np.sin(2*np.pi*(220*u-80*u*u))+.3*rng.normal(size=len(u)))*np.sin(np.pi*u/.45)**2*.10;save('wrong_order',a)
(R/'FOREST_AUDIO_ANALYSIS.json').write_text(json.dumps(stats,indent=2)+'\n')
