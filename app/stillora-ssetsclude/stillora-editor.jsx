const { useState, useRef, useEffect, useCallback } = React;

/* ============================================================ tokens */
const C = {
  onyx:'#020617', surface:'#0b1326', low:'#131b2e', mid:'#171f33',
  high:'#222a3d', higher:'#2d3449',
  stroke:'rgba(218,226,253,.10)', strokeB:'rgba(218,226,253,.18)',
  on:'#dae2fd', dim:'#8b93ac', dimmer:'#5d667e',
  violet:'#7c3aed', violetB:'#d2bbff', indigo:'#312e81', gold:'#facc15',
};

const FORMATS = [
  { id:'reels',   name:'Reels · TikTok · Stories', w:1080, h:1920, ratio:'9:16', kind:'Vertical'  },
  { id:'shorts',  name:'YouTube Shorts',           w:1080, h:1920, ratio:'9:16', kind:'Vertical'  },
  { id:'yt',      name:'YouTube Long Video',       w:1920, h:1080, ratio:'16:9', kind:'Landscape' },
  { id:'square',  name:'Square Post',              w:1080, h:1080, ratio:'1:1',  kind:'Square'     },
  { id:'original',name:'Original Image Size',      w:0,    h:0,     ratio:'—',    kind:'Original'  },
];

const SAMPLES = [
  'linear-gradient(135deg,#7c3aed,#312e81 60%,#0b1326)',
  'linear-gradient(135deg,#facc15,#7c3aed)',
  'linear-gradient(135deg,#22d3ee,#312e81)',
  'linear-gradient(160deg,#f472b6,#7c3aed,#1e1b4b)',
];

/* ============================================================ icons */
const I = {
  play:(p)=> <svg width={p?.s||16} height={p?.s||16} viewBox="0 0 16 16" fill="none"><path d="M4 3l9 5-9 5V3z" fill="currentColor"/></svg>,
  pause:(p)=> <svg width={p?.s||16} height={p?.s||16} viewBox="0 0 16 16" fill="none"><rect x="4" y="3" width="3" height="10" rx="1" fill="currentColor"/><rect x="9" y="3" width="3" height="10" rx="1" fill="currentColor"/></svg>,
  image:(p)=> <svg width={p?.s||20} height={p?.s||20} viewBox="0 0 20 20" fill="none"><rect x="2.5" y="3.5" width="15" height="13" rx="2.5" stroke="currentColor" strokeWidth="1.4"/><circle cx="7" cy="8" r="1.6" fill="currentColor"/><path d="M3.5 14l4-4 3.5 3 2.5-2.5 3 3.5" stroke="currentColor" strokeWidth="1.4" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  video:(p)=> <svg width={p?.s||20} height={p?.s||20} viewBox="0 0 20 20" fill="none"><rect x="2" y="5" width="11" height="10" rx="2.5" stroke="currentColor" strokeWidth="1.4"/><path d="M13 9l5-2.5v7L13 11" stroke="currentColor" strokeWidth="1.4" fill="none" strokeLinejoin="round"/></svg>,
  audio:(p)=> <svg width={p?.s||18} height={p?.s||18} viewBox="0 0 18 18" fill="none"><path d="M3 7v4M6 5v8M9 3v12M12 6v6M15 8v2" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/></svg>,
  check:(p)=> <svg width={p?.s||16} height={p?.s||16} viewBox="0 0 16 16" fill="none"><path d="M3 8.5l3.2 3.2L13 5" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  down:(p)=> <svg width={p?.s||16} height={p?.s||16} viewBox="0 0 16 16" fill="none"><path d="M8 2v8m0 0L4.5 6.5M8 10l3.5-3.5M3 13h10" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  plus:(p)=> <svg width={p?.s||16} height={p?.s||16} viewBox="0 0 16 16" fill="none"><path d="M8 3v10M3 8h10" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round"/></svg>,
  x:(p)=> <svg width={p?.s||12} height={p?.s||12} viewBox="0 0 12 12" fill="none"><path d="M3 3l6 6M9 3l-6 6" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round"/></svg>,
  spark:(p)=> <svg width={p?.s||16} height={p?.s||16} viewBox="0 0 16 16" fill="none"><path d="M8 1l1.6 4.4L14 7l-4.4 1.6L8 13l-1.6-4.4L2 7l4.4-1.6L8 1z" fill="currentColor"/></svg>,
};

/* logo mark */
const Mark = ({s=30}) => (
  <svg width={s} height={s} viewBox="0 0 116 116" fill="none">
    <rect x="8" y="8" width="100" height="100" rx="26" fill="#7c3aed"/>
    <path d="M48 41.5 L78 58 L48 74.5 Z" fill="#fff"/>
    <circle cx="40" cy="41" r="3.4" fill="#facc15"/>
  </svg>
);

const fmt = (s)=> `${Math.floor(s/60)}:${String(Math.floor(s%60)).padStart(2,'0')}`;

/* ============================================================ App */
function App(){
  const [media, setMedia] = useState([]);       // {id,type,src}  image|video
  const [audio, setAudio] = useState(null);      // {name}
  const [format, setFormat] = useState('reels');
  const [framing, setFraming] = useState('fill');
  const [durMode, setDurMode] = useState('10');  // '10' | '30' | 'audio'
  const [slideSec, setSlideSec] = useState(3);
  const [playing, setPlaying] = useState(false);
  const [t, setT] = useState(0);                 // 0..1 progress
  const [exporting, setExporting] = useState(false);
  const [progress, setProgress] = useState(0);
  const [done, setDone] = useState(false);
  const [drag, setDrag] = useState(null);

  const imgInput = useRef(), audInput = useRef(), raf = useRef();

  const F = FORMATS.find(f=>f.id===format);
  const isVideo = media.some(m=>m.type==='video');
  const duration = durMode==='audio' ? (audio?12:10) : Number(durMode) ||
    (media.length>1 ? media.length*slideSec : 10);

  /* ---- media handlers ---- */
  const addFiles = (files, type) => {
    const arr = [...files].filter(Boolean).map(f=>({
      id:Math.random().toString(36).slice(2), type,
      src: f ? URL.createObjectURL(f) : null, name:f?.name
    }));
    if(type==='audio'){ setAudio({name:arr[0]?.name||'soundtrack.mp3'}); return; }
    setMedia(m => type==='video' ? arr.slice(0,1) : [...m, ...arr]);
    setDone(false);
  };
  const addSample = (g)=>{ setMedia(m=>[...m,{id:Math.random().toString(36).slice(2),type:'image',grad:g}]); setDone(false); };
  const removeMedia = (id)=> setMedia(m=>m.filter(x=>x.id!==id));

  /* ---- playback ---- */
  useEffect(()=>{
    if(!playing){ cancelAnimationFrame(raf.current); return; }
    let start=null, base=t;
    const tick=(ts)=>{
      if(start===null) start=ts;
      let nt = base + (ts-start)/1000/duration;
      if(nt>=1){ nt=0; start=ts; base=0; }
      setT(nt); raf.current=requestAnimationFrame(tick);
    };
    raf.current=requestAnimationFrame(tick);
    return ()=>cancelAnimationFrame(raf.current);
  },[playing,duration]);

  /* ---- export ---- */
  const runExport = ()=>{
    if(!media.length) { imgInput.current?.click(); return; }
    setExporting(true); setDone(false); setProgress(0);
    let p=0;
    const iv=setInterval(()=>{
      p += Math.random()*9 + 3;
      if(p>=100){ p=100; clearInterval(iv); setProgress(100);
        setTimeout(()=>{ setExporting(false); setDone(true); }, 480); }
      else setProgress(p);
    }, 130);
  };

  /* current slide index for multi-image */
  const slideIdx = media.length>1 ? Math.min(media.length-1, Math.floor(t*media.length)) : 0;
  const cur = media[slideIdx];

  /* preview frame sizing */
  const box = {w:340,h:560};
  let pw,ph;
  if(F.id==='original'){ pw = media.length? 300: 300; ph = 360; }
  else {
    const r = F.w/F.h;
    if(r>=1){ pw=Math.min(box.w,520); ph=pw/r; } else { ph=Math.min(box.h,560); pw=ph*r; }
  }

  return (
    <div style={S.shell}>
      {/* ---------- top bar ---------- */}
      <header style={S.topbar}>
        <div style={{display:'flex',alignItems:'center',gap:11}}>
          <Mark s={30}/>
          <span style={S.word}>Stillora</span>
          <span style={S.byline}>by Tecno Blocks</span>
        </div>
        <div style={{display:'flex',alignItems:'center',gap:10}}>
          <span style={S.draftPill}><span style={{width:6,height:6,borderRadius:9,background:C.gold,display:'inline-block'}}/>Draft autosaved</span>
          <button style={S.ghostBtn}>Help</button>
        </div>
      </header>

      <div style={S.body}>
        {/* ============== LEFT : controls ============== */}
        <div style={S.left}>
          <div style={S.kicker}><I.spark s={13}/> New render</div>
          <h1 style={S.h1}>Image to share-ready video</h1>
          <p style={S.sub}>Drop a photo, a stack of images, or a clip — add audio, pick a format, export a clean MP4 in seconds.</p>

          {/* STEP 1 — media */}
          <Section n="1" title="Add your media" hint={media.length?`${media.length} item${media.length>1?'s':''}`:'required'}>
            {media.length===0 ? (
              <div
                style={{...S.drop, ...(drag==='img'?S.dropHot:{})}}
                onClick={()=>imgInput.current?.click()}
                onDragOver={e=>{e.preventDefault();setDrag('img');}}
                onDragLeave={()=>setDrag(null)}
                onDrop={e=>{e.preventDefault();setDrag(null);addFiles(e.dataTransfer.files,'image');}}>
                <div style={S.dropIcon}><I.image s={26}/></div>
                <div style={{fontWeight:600,fontSize:15}}>Drop an image or video</div>
                <div style={{fontSize:12.5,color:C.dim,marginTop:4}}>or click to browse · JPG PNG WebP MP4 MOV</div>
                <div style={{display:'flex',gap:8,marginTop:16}}>
                  {SAMPLES.map((g,i)=>(
                    <button key={i} title="Use sample image" onClick={e=>{e.stopPropagation();addSample(g);}}
                      style={{...S.sampleSwatch, background:g}}/>
                  ))}
                  <span style={{fontSize:11,color:C.dim,alignSelf:'center',marginLeft:2}}>try a sample →</span>
                </div>
              </div>
            ) : (
              <div>
                <div style={S.thumbRow}>
                  {media.map((m,i)=>(
                    <div key={m.id} style={S.thumb}>
                      <div style={{...S.thumbImg, background:m.grad|| (m.src?`#000 center/cover`:C.high), backgroundImage:m.src?`url(${m.src})`:m.grad}}>
                        {m.type==='video' && <span style={S.vidTag}><I.video s={11}/></span>}
                      </div>
                      <button style={S.thumbX} onClick={()=>removeMedia(m.id)}><I.x/></button>
                      {media.length>1 && <span style={S.thumbN}>{i+1}</span>}
                    </div>
                  ))}
                  {!isVideo && (
                    <button style={S.thumbAdd} onClick={()=>imgInput.current?.click()}><I.plus s={18}/></button>
                  )}
                </div>
                {media.length>1 && (
                  <div style={S.slideTiming}>
                    <span style={{fontSize:12.5,color:C.dim}}>Seconds per slide</span>
                    <div style={{display:'flex',gap:6}}>
                      {[2,3,4,5].map(v=>(
                        <button key={v} onClick={()=>setSlideSec(v)}
                          style={{...S.miniPill, ...(slideSec===v?S.miniPillOn:{})}}>{v}s</button>
                      ))}
                    </div>
                    <span style={{fontSize:11.5,color:C.violetB,marginLeft:'auto'}}>fade transitions ✓</span>
                  </div>
                )}
              </div>
            )}
          </Section>

          {/* STEP 2 — format */}
          <Section n="2" title="Output format" hint={F.id==='original'?'Original':`${F.w}×${F.h}`}>
            <div style={S.fmtGrid}>
              {FORMATS.map(f=>(
                <button key={f.id} onClick={()=>setFormat(f.id)}
                  style={{...S.fmtCard, ...(format===f.id?S.fmtCardOn:{})}}>
                  <div style={{...S.fmtShape, aspectRatio: f.id==='original'?'4/3': `${f.w||1}/${f.h||1}`,
                    ...(format===f.id?{borderColor:C.violetB,background:'rgba(124,58,237,.18)'}:{})}}/>
                  <div style={{textAlign:'left'}}>
                    <div style={{fontSize:12.5,fontWeight:600,lineHeight:1.2}}>{f.kind}</div>
                    <div style={{fontSize:10.5,color:C.dim,marginTop:2,fontFamily:'Geist Mono,monospace'}}>{f.ratio}</div>
                  </div>
                  {format===f.id && <span style={S.fmtCheck}><I.check s={11}/></span>}
                </button>
              ))}
            </div>
            <div style={{fontSize:11.5,color:C.dim,marginTop:9}}>{F.name}</div>
          </Section>

          {/* STEP 3 — framing + duration */}
          <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:14}}>
            <Section n="3" title="Framing">
              <div style={S.toggle}>
                {['fit','fill'].map(v=>(
                  <button key={v} onClick={()=>setFraming(v)}
                    style={{...S.toggleBtn, ...(framing===v?S.toggleOn:{})}}>
                    {v==='fit'?'Fit':'Fill'}
                  </button>
                ))}
              </div>
              <div style={{fontSize:11.5,color:C.dim,marginTop:8,lineHeight:1.45}}>
                {framing==='fit'?'Keep the whole image — letterboxed.':'Crop edges to cover the frame.'}
              </div>
            </Section>

            <Section n="4" title="Duration">
              <div style={S.toggle}>
                {[['10','10s'],['30','30s'],['audio','Audio']].map(([v,l])=>(
                  <button key={v} onClick={()=>v==='audio'?(audio&&setDurMode(v)):setDurMode(v)}
                    disabled={v==='audio'&&!audio}
                    style={{...S.toggleBtn, ...(durMode===v?S.toggleOn:{}), ...(v==='audio'&&!audio?{opacity:.4,cursor:'not-allowed'}:{})}}>
                    {l}
                  </button>
                ))}
              </div>
              <div style={{fontSize:11.5,color:C.dim,marginTop:8}}>Up to 5 min · matches {durMode==='audio'?'your track':'preset'}.</div>
            </Section>
          </div>

          {/* STEP 5 — audio */}
          <Section n="5" title="Soundtrack" hint="optional">
            {!audio ? (
              <button style={{...S.drop, padding:'16px 18px', flexDirection:'row', gap:12, justifyContent:'flex-start'}}
                onClick={()=>audInput.current?.click()}>
                <div style={{...S.dropIcon, width:38,height:38}}><I.audio s={17}/></div>
                <div style={{textAlign:'left'}}>
                  <div style={{fontWeight:600,fontSize:13.5}}>Add a soundtrack</div>
                  <div style={{fontSize:11.5,color:C.dim,marginTop:2}}>MP3 · WAV · M4A · AAC · OGG</div>
                </div>
                <span style={{marginLeft:'auto',color:C.violetB}}><I.plus/></span>
              </button>
            ) : (
              <div style={S.audioRow}>
                <span style={{color:C.gold}}><I.audio s={16}/></span>
                <div style={{flex:1,overflow:'hidden'}}>
                  <div style={{fontSize:13,fontWeight:600,whiteSpace:'nowrap',overflow:'hidden',textOverflow:'ellipsis'}}>{audio.name}</div>
                  <div style={S.wave}>{Array.from({length:42}).map((_,i)=>(
                    <span key={i} style={{height:`${20+Math.abs(Math.sin(i*1.7))*70}%`}}/>
                  ))}</div>
                </div>
                <button style={S.thumbX} onClick={()=>setAudio(null)}><I.x/></button>
              </div>
            )}
          </Section>

          <input ref={imgInput} type="file" accept="image/*,video/*" multiple hidden
            onChange={e=>{ const f=e.target.files; const v=[...f].some(x=>x.type.startsWith('video'));
              addFiles(f, v?'video':'image'); e.target.value=''; }}/>
          <input ref={audInput} type="file" accept="audio/*" hidden
            onChange={e=>{ addFiles(e.target.files,'audio'); e.target.value=''; }}/>
        </div>

        {/* ============== RIGHT : preview ============== */}
        <div style={S.right}>
          <div style={S.previewWrap}>
            <div style={S.previewMeta}>
              <span style={S.fmtBadge}>{F.kind} · {F.ratio}</span>
              <span style={{fontFamily:'Geist Mono,monospace',fontSize:11.5,color:C.dim}}>
                {F.id==='original'?'original size':`${F.w} × ${F.h}`}
              </span>
            </div>

            {/* the video frame */}
            <div style={{display:'flex',justifyContent:'center',alignItems:'center',flex:1}}>
              <div style={{...S.frame, width:pw, height:ph}}>
                {media.length===0 ? (
                  <div style={S.frameEmpty}>
                    <div className="stripes" style={S.stripes}/>
                    <span style={{fontFamily:'Geist Mono,monospace',fontSize:11,color:C.dim,position:'relative'}}>your image renders here</span>
                  </div>
                ) : (
                  media.map((m,i)=>(
                    <div key={m.id} style={{
                      ...S.frameImg,
                      backgroundImage: m.src?`url(${m.src})`: m.grad,
                      backgroundColor:'#000',
                      backgroundSize: framing==='fill'?'cover':'contain',
                      backgroundRepeat:'no-repeat', backgroundPosition:'center',
                      opacity: i===slideIdx?1:0,
                    }}/>
                  ))
                )}

                {/* play overlay */}
                {media.length>0 && (
                  <button style={S.bigPlay} onClick={()=>setPlaying(p=>!p)}>
                    <span style={S.bigPlayInner}>{playing? <I.pause s={20}/> : <I.play s={20}/>}</span>
                  </button>
                )}

                {/* bottom scrubber */}
                {media.length>0 && (
                  <div style={S.scrub}>
                    <span style={S.scrubTime}>{fmt(t*duration)}</span>
                    <div style={S.track} onClick={e=>{
                      const r=e.currentTarget.getBoundingClientRect();
                      setT(Math.max(0,Math.min(1,(e.clientX-r.left)/r.width)));
                    }}>
                      <div style={{...S.trackFill, width:`${t*100}%`}}/>
                      <div style={{...S.trackKnob, left:`${t*100}%`}}/>
                    </div>
                    <span style={S.scrubTime}>{fmt(duration)}</span>
                  </div>
                )}
              </div>
            </div>

            <div style={S.fileLine}>
              <span style={{fontFamily:'Geist Mono,monospace',fontSize:12,color:C.on}}>final.mp4</span>
              <span style={{fontFamily:'Geist Mono,monospace',fontSize:11.5,color:C.dim}}>1080p · H.264 · ~{Math.max(2,Math.round(duration*0.8))} MB</span>
            </div>
          </div>

          {/* export dock */}
          <div style={S.dock}>
            {!exporting && !done && (
              <button style={{...S.cta, ...(media.length?{}:S.ctaIdle)}} onClick={runExport}>
                <I.spark s={16}/> {media.length? 'Export MP4' : 'Add media to export'}
              </button>
            )}
            {exporting && (
              <div style={{width:'100%'}}>
                <div style={S.expRow}>
                  <span style={{display:'flex',alignItems:'center',gap:8,fontSize:13.5,fontWeight:600}}>
                    <span className="spin" style={S.spin}/> Rendering on server…
                  </span>
                  <span style={{fontFamily:'Geist Mono,monospace',fontSize:13,color: progress>=100?C.gold:C.violetB}}>{Math.floor(progress)}%</span>
                </div>
                <div style={S.progTrack}>
                  <div style={{...S.progFill, width:`${progress}%`, background: progress>=100?C.gold:C.violet,
                    boxShadow: progress>=100?'0 0 16px rgba(250,204,21,.5)':'0 0 12px rgba(124,58,237,.6)'}}/>
                </div>
              </div>
            )}
            {done && (
              <div style={S.doneRow}>
                <span style={S.doneBadge}><I.check s={15}/></span>
                <div style={{flex:1}}>
                  <div style={{fontSize:13.5,fontWeight:700}}>Render complete</div>
                  <div style={{fontSize:11.5,color:C.dim}}>final.mp4 · {F.ratio} · ready to post</div>
                </div>
                <button style={S.dlBtn}><I.down s={15}/> Download</button>
                <button style={S.againBtn} onClick={()=>{setDone(false);}}>New</button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---- section wrapper ---- */
function Section({n,title,hint,children}){
  return (
    <div style={S.section}>
      <div style={S.secHead}>
        <span style={S.secNum}>{n}</span>
        <span style={S.secTitle}>{title}</span>
        {hint && <span style={S.secHint}>{hint}</span>}
      </div>
      {children}
    </div>
  );
}

/* ============================================================ styles */
const S = {
  shell:{minHeight:'100vh',background:C.onyx,color:C.on,display:'flex',flexDirection:'column',
    fontFamily:'Geist,system-ui,sans-serif'},
  topbar:{height:60,flexShrink:0,display:'flex',alignItems:'center',justifyContent:'space-between',
    padding:'0 24px',borderBottom:`1px solid ${C.stroke}`,background:'rgba(11,19,38,.6)',backdropFilter:'blur(12px)',
    position:'sticky',top:0,zIndex:10},
  word:{fontSize:19,fontWeight:700,letterSpacing:'-.04em'},
  byline:{fontSize:12,color:C.dim,fontFamily:'Geist Mono,monospace',marginLeft:2},
  draftPill:{display:'flex',alignItems:'center',gap:7,fontSize:11.5,color:C.dim,
    border:`1px solid ${C.stroke}`,borderRadius:99,padding:'6px 12px'},
  ghostBtn:{background:'transparent',color:C.on,border:`1px solid ${C.stroke}`,borderRadius:8,
    padding:'7px 14px',fontSize:13,fontWeight:500,cursor:'pointer',fontFamily:'inherit'},

  body:{flex:1,display:'grid',gridTemplateColumns:'minmax(0,1fr) minmax(420px,540px)',gap:0,alignItems:'stretch'},

  left:{padding:'34px 40px 60px',maxWidth:680,width:'100%',justifySelf:'end',overflow:'auto'},
  kicker:{display:'inline-flex',alignItems:'center',gap:7,color:C.violetB,fontSize:12,fontWeight:600,
    fontFamily:'Geist Mono,monospace',textTransform:'uppercase',letterSpacing:'.12em',marginBottom:14},
  h1:{fontSize:34,fontWeight:700,letterSpacing:'-.035em',lineHeight:1.05},
  sub:{marginTop:10,color:C.dim,fontSize:14.5,lineHeight:1.55,maxWidth:520},

  section:{marginTop:26,background:C.surface,border:`1px solid ${C.stroke}`,borderRadius:14,padding:'18px 20px'},
  secHead:{display:'flex',alignItems:'center',gap:10,marginBottom:14},
  secNum:{width:22,height:22,borderRadius:7,background:C.indigo,color:C.violetB,fontSize:12,fontWeight:700,
    display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0},
  secTitle:{fontSize:15,fontWeight:600,letterSpacing:'-.01em'},
  secHint:{marginLeft:'auto',fontSize:11,color:C.dim,fontFamily:'Geist Mono,monospace',
    border:`1px solid ${C.stroke}`,borderRadius:6,padding:'3px 8px'},

  drop:{display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',
    border:`1.5px dashed ${C.strokeB}`,borderRadius:12,padding:'30px 20px',cursor:'pointer',
    background:C.low,transition:'all .15s',textAlign:'center',width:'100%',fontFamily:'inherit',color:C.on},
  dropHot:{borderColor:C.violetB,background:'rgba(124,58,237,.10)'},
  dropIcon:{width:48,height:48,borderRadius:12,background:C.high,color:C.violetB,
    display:'flex',alignItems:'center',justifyContent:'center',marginBottom:12},
  sampleSwatch:{width:30,height:30,borderRadius:7,border:`1px solid ${C.strokeB}`,cursor:'pointer',padding:0},

  thumbRow:{display:'flex',gap:10,flexWrap:'wrap'},
  thumb:{position:'relative',width:64,height:64},
  thumbImg:{width:'100%',height:'100%',borderRadius:10,backgroundSize:'cover',backgroundPosition:'center',
    border:`1px solid ${C.strokeB}`},
  thumbX:{position:'absolute',top:-6,right:-6,width:18,height:18,borderRadius:9,background:C.higher,
    color:C.on,border:`1px solid ${C.strokeB}`,display:'flex',alignItems:'center',justifyContent:'center',
    cursor:'pointer',padding:0},
  thumbN:{position:'absolute',bottom:4,left:4,fontSize:10,fontWeight:700,background:'rgba(2,6,23,.7)',
    borderRadius:5,padding:'1px 5px',fontFamily:'Geist Mono,monospace'},
  vidTag:{position:'absolute',top:5,right:5,color:'#fff',background:'rgba(2,6,23,.55)',borderRadius:5,
    padding:'2px 4px',display:'flex'},
  thumbAdd:{width:64,height:64,borderRadius:10,border:`1.5px dashed ${C.strokeB}`,background:C.low,
    color:C.violetB,cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'center'},
  slideTiming:{display:'flex',alignItems:'center',gap:12,marginTop:14,paddingTop:14,borderTop:`1px solid ${C.stroke}`},
  miniPill:{background:C.low,color:C.on,border:`1px solid ${C.stroke}`,borderRadius:7,padding:'5px 10px',
    fontSize:12,fontWeight:600,cursor:'pointer',fontFamily:'inherit'},
  miniPillOn:{background:C.violet,borderColor:C.violet,color:'#fff'},

  fmtGrid:{display:'grid',gridTemplateColumns:'1fr 1fr',gap:9},
  fmtCard:{position:'relative',display:'flex',alignItems:'center',gap:11,padding:'11px 13px',borderRadius:10,
    background:C.low,border:`1px solid ${C.stroke}`,cursor:'pointer',fontFamily:'inherit',color:C.on,textAlign:'left'},
  fmtCardOn:{borderColor:C.violet,background:'rgba(124,58,237,.10)',boxShadow:'inset 0 0 0 1px rgba(124,58,237,.4)'},
  fmtShape:{width:26,flexShrink:0,maxHeight:34,borderRadius:4,border:`1.5px solid ${C.strokeB}`,background:C.high},
  fmtCheck:{position:'absolute',top:9,right:9,width:16,height:16,borderRadius:8,background:C.violet,color:'#fff',
    display:'flex',alignItems:'center',justifyContent:'center'},

  toggle:{display:'flex',background:C.low,borderRadius:9,padding:3,gap:3,border:`1px solid ${C.stroke}`},
  toggleBtn:{flex:1,padding:'8px 0',borderRadius:6,background:'transparent',color:C.dim,border:'none',
    fontSize:13,fontWeight:600,cursor:'pointer',fontFamily:'inherit'},
  toggleOn:{background:C.violet,color:'#fff',boxShadow:'0 1px 8px rgba(124,58,237,.4)'},

  audioRow:{display:'flex',alignItems:'center',gap:12,background:C.low,border:`1px solid ${C.stroke}`,
    borderRadius:11,padding:'12px 14px'},
  wave:{display:'flex',alignItems:'center',gap:2,height:22,marginTop:6},

  /* RIGHT */
  right:{borderLeft:`1px solid ${C.stroke}`,background:'linear-gradient(180deg,#0a1124,#070d1d)',
    display:'flex',flexDirection:'column',position:'sticky',top:60,height:'calc(100vh - 60px)'},
  previewWrap:{flex:1,display:'flex',flexDirection:'column',padding:'26px 30px 18px',minHeight:0},
  previewMeta:{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:18},
  fmtBadge:{fontSize:11.5,fontWeight:600,color:C.violetB,background:'rgba(124,58,237,.16)',
    border:`1px solid rgba(124,58,237,.4)`,borderRadius:99,padding:'5px 12px'},

  frame:{position:'relative',borderRadius:18,overflow:'hidden',background:'#05080f',
    border:`1px solid ${C.strokeB}`,boxShadow:'0 30px 80px -30px rgba(0,0,0,.8)',
    transition:'width .35s cubic-bezier(.4,0,.2,1), height .35s cubic-bezier(.4,0,.2,1)'},
  frameImg:{position:'absolute',inset:0,transition:'opacity .5s'},
  frameEmpty:{position:'absolute',inset:0,display:'flex',alignItems:'center',justifyContent:'center',background:C.low},
  stripes:{position:'absolute',inset:0,backgroundImage:`repeating-linear-gradient(45deg,${C.high} 0 10px,transparent 10px 20px)`,opacity:.4},

  bigPlay:{position:'absolute',inset:0,margin:'auto',width:60,height:60,borderRadius:99,border:'none',
    background:'transparent',cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'center'},
  bigPlayInner:{width:54,height:54,borderRadius:99,background:'rgba(124,58,237,.85)',backdropFilter:'blur(6px)',
    color:'#fff',display:'flex',alignItems:'center',justifyContent:'center',paddingLeft:2,
    boxShadow:'0 6px 24px rgba(124,58,237,.55), inset 0 0 0 1px rgba(255,255,255,.25)'},

  scrub:{position:'absolute',left:0,right:0,bottom:0,display:'flex',alignItems:'center',gap:9,padding:'12px 14px',
    background:'linear-gradient(0deg,rgba(2,6,23,.85),transparent)'},
  scrubTime:{fontFamily:'Geist Mono,monospace',fontSize:10.5,color:'#fff',minWidth:26},
  track:{flex:1,height:5,borderRadius:9,background:'rgba(255,255,255,.18)',position:'relative',cursor:'pointer'},
  trackFill:{position:'absolute',left:0,top:0,bottom:0,borderRadius:9,background:C.violetB},
  trackKnob:{position:'absolute',top:'50%',width:12,height:12,borderRadius:9,background:'#fff',
    transform:'translate(-50%,-50%)',boxShadow:'0 1px 4px rgba(0,0,0,.5)'},

  fileLine:{display:'flex',alignItems:'center',justifyContent:'space-between',marginTop:16,
    padding:'10px 14px',background:'rgba(11,19,38,.6)',border:`1px solid ${C.stroke}`,borderRadius:10},

  dock:{flexShrink:0,borderTop:`1px solid ${C.stroke}`,padding:'16px 30px 20px',background:'rgba(7,13,29,.7)',
    minHeight:74,display:'flex',alignItems:'center'},
  cta:{width:'100%',height:48,borderRadius:11,border:'none',background:C.violet,color:'#fff',fontSize:15,
    fontWeight:600,cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'center',gap:9,
    fontFamily:'inherit',boxShadow:'0 6px 24px -6px rgba(124,58,237,.7), inset 0 0 0 1px rgba(255,255,255,.12)'},
  ctaIdle:{background:C.high,color:C.dim,boxShadow:'none',cursor:'pointer'},
  expRow:{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:9},
  spin:{width:15,height:15,borderRadius:99,border:`2px solid rgba(210,187,255,.3)`,borderTopColor:C.violetB,display:'inline-block'},
  progTrack:{height:8,borderRadius:9,background:C.low,overflow:'hidden'},
  progFill:{height:'100%',borderRadius:9,transition:'width .13s linear'},
  doneRow:{display:'flex',alignItems:'center',gap:13,width:'100%'},
  doneBadge:{width:34,height:34,borderRadius:9,background:'rgba(250,204,21,.16)',border:`1px solid rgba(250,204,21,.5)`,
    color:C.gold,display:'flex',alignItems:'center',justifyContent:'center',flexShrink:0},
  dlBtn:{height:40,borderRadius:9,border:'none',background:C.gold,color:'#3c2f00',fontSize:13.5,fontWeight:700,
    cursor:'pointer',display:'flex',alignItems:'center',gap:7,padding:'0 16px',fontFamily:'inherit'},
  againBtn:{height:40,borderRadius:9,border:`1px solid ${C.stroke}`,background:'transparent',color:C.on,
    fontSize:13.5,fontWeight:600,cursor:'pointer',padding:'0 14px',fontFamily:'inherit'},
};

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
