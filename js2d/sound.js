// 인생라멘 2D — 소리(브라우저 합성)·음성 파일·일본어 음성 (index.html의 사운드 부분을 그대로 옮김)
// 쓰기 전에 HAKATA · YOKO · SAPPO 를 정의해야 함
// ================= 사운드 (브라우저에서 직접 합성) =================
// 전체 소리 크기 (설정 화면, 0~1) — 지역과 상관없이 하나
const volumeNow = () => { try { const v = parseFloat(localStorage.getItem('ramen-volume')); return isNaN(v) ? 1 : v; } catch (e) { return 1; } };
const Sound = (() => {
  let ctx, master, noiseBuf, boilGain, sizzleGain;
  let boilTarget = 0, sizzleOn = false;
  function loopNoise(type, freq, q) {
    const src = ctx.createBufferSource(); src.buffer = noiseBuf; src.loop = true;
    const f = ctx.createBiquadFilter(); f.type = type; f.frequency.value = freq; f.Q.value = q;
    const g = ctx.createGain(); g.gain.value = 0;
    src.connect(f).connect(g).connect(master); src.start();
    return g;
  }
  // ---- 배경 음악 (music()에서 켜고 끔) ----
  let musicGain = null, musicTimer = null, nextBeat = 0, beat = 0, rainGain = null, melo = 3;
  const N = m => 440 * Math.pow(2, (m - 69) / 12);                 // MIDI 번호 → 주파수
  const YO = [62, 64, 67, 69, 71, 74, 76, 79, 81];                  // D E G A B (요나누키 음계)
  const BARS = [[50, 57, 62, 66], [47, 54, 62, 66], [43, 50, 59, 62], [45, 52, 57, 64]]; // D · Bm · G · A
  const EIGHTH = 60 / 80 / 2;                                       // 80 BPM 8분음표
  function voice(freq, t, dur, vol, type = 'triangle', cutoff = 2400) {
    const o = ctx.createOscillator(); o.type = type; o.frequency.value = freq;
    const f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = cutoff;
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol, t + 0.012); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(f).connect(g).connect(musicGain); o.start(t); o.stop(t + dur + 0.05);
  }
  function pluck(m, t, vol = 0.07) { voice(N(m), t, 1.4, vol); voice(N(m) * 2.01, t, 0.5, vol * 0.25, 'sine'); }
  function scheduleMusic() {
    while (nextBeat < ctx.currentTime + 0.35) {
      const t = nextBeat, i = beat % 16, bar = BARS[Math.floor(beat / 16) % 4];
      if (i === 0) { // 마디 첫 박: 화음 + 베이스
        for (const m of bar.slice(1)) { const o = ctx.createOscillator(), g = ctx.createGain(); o.type = 'sine'; o.frequency.value = N(m);
          g.gain.setValueAtTime(0.0001, t); g.gain.linearRampToValueAtTime(0.025, t + 0.6); g.gain.linearRampToValueAtTime(0.0001, t + EIGHTH * 16);
          o.connect(g).connect(musicGain); o.start(t); o.stop(t + EIGHTH * 16 + 0.1); }
        voice(N(bar[0] - 12), t, 1.6, 0.12, 'sine', 600);
      }
      if (i === 8) voice(N(bar[0] - 5), t, 1.2, 0.08, 'sine', 600);
      if (i === 4 || i === 12) { const o = ctx.createOscillator(), g = ctx.createGain(); o.frequency.value = 1800; o.type = 'square'; // 나무 딱
        g.gain.setValueAtTime(0.012, t); g.gain.exponentialRampToValueAtTime(0.0001, t + 0.04); o.connect(g).connect(musicGain); o.start(t); o.stop(t + 0.05); }
      if (i % 2 === 0 && Math.random() < 0.6) { // 멜로디: 음계 위를 천천히 오르내림
        melo = Math.max(0, Math.min(YO.length - 1, melo + [-2, -1, -1, 0, 1, 1, 2][Math.floor(Math.random() * 7)]));
        pluck(YO[melo], t);
        if (Math.random() < 0.15) pluck(YO[Math.max(0, melo - 2)], t + EIGHTH);
      }
      nextBeat += EIGHTH; beat++;
    }
  }
  // 아이폰은 무음 스위치가 켜져 있으면 웹 오디오를 꺼 버림 →
  // 소리 없는 오디오를 계속 틀어 '미디어 재생'으로 바꿔서 무음 스위치와 상관없이 들리게 (iOS 17+는 audioSession도)
  let mobileUnlocked = false;
  function silentWavUrl() {
    const n = 800, buf = new ArrayBuffer(44 + n * 2), v = new DataView(buf);
    const str = (o, s) => { for (let i = 0; i < s.length; i++) v.setUint8(o + i, s.charCodeAt(i)); };
    str(0, 'RIFF'); v.setUint32(4, 36 + n * 2, true); str(8, 'WAVE'); str(12, 'fmt ');
    v.setUint32(16, 16, true); v.setUint16(20, 1, true); v.setUint16(22, 1, true); v.setUint32(24, 8000, true);
    v.setUint32(28, 16000, true); v.setUint16(32, 2, true); v.setUint16(34, 16, true); str(36, 'data'); v.setUint32(40, n * 2, true);
    return URL.createObjectURL(new Blob([buf], { type: 'audio/wav' }));
  }
  function unlockMobileAudio() {
    if (mobileUnlocked) return;
    mobileUnlocked = true;
    try { if (navigator.audioSession) navigator.audioSession.type = 'playback'; } catch (e) { /* 미지원 */ }
    try {
      const a = new Audio(silentWavUrl()); a.loop = true; a.setAttribute('playsinline', '');
      a.play().catch(() => { mobileUnlocked = false; }); // 막히면 다음 탭에서 다시 시도
    } catch (e) { mobileUnlocked = false; }
  }
  function tone(freq, dur, { type = 'sine', vol = 0.15, slide = 0, delay = 0 } = {}) {
    if (!ctx) return;
    const t = ctx.currentTime + delay;
    const o = ctx.createOscillator(); o.type = type; o.frequency.setValueAtTime(freq, t);
    if (slide) o.frequency.exponentialRampToValueAtTime(freq * slide, t + dur);
    const g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(vol, t + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g).connect(master); o.start(t); o.stop(t + dur + 0.05);
  }
  function burst(dur, type, freq, vol, delay = 0) {
    if (!ctx) return;
    const t = ctx.currentTime + delay;
    const src = ctx.createBufferSource(); src.buffer = noiseBuf;
    const f = ctx.createBiquadFilter(); f.type = type; f.frequency.value = freq;
    const g = ctx.createGain();
    g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f).connect(g).connect(master);
    src.start(t, Math.random()); src.stop(t + dur + 0.05);
  }
  return {
    init() {
      unlockMobileAudio();
      if (ctx) { if (ctx.state !== 'running') ctx.resume(); return; }
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain(); master.gain.value = 0.7 * volumeNow(); master.connect(ctx.destination);
      noiseBuf = ctx.createBuffer(1, ctx.sampleRate * 2, ctx.sampleRate);
      const d = noiseBuf.getChannelData(0);
      for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
      boilGain = loopNoise('bandpass', 380, 0.8);
      sizzleGain = loopNoise('highpass', 2600, 0.5);
      loopNoise('lowpass', 240, 0.7).gain.value = 0.025; // 가게 웅성거림
    },
    suspend() { ctx?.suspend(); },
    // 휴대폰이 소리를 멈춰 뒀으면 다시 켬 (화면 탭 · 앱으로 돌아올 때)
    wake() { if (ctx && ctx.state !== 'running' && !(G?.paused)) ctx.resume(); },
    // 비 오는 날 빗소리
    // 빗소리: 낮고 부드럽게 (치익 하는 챠슈 굽는 소리와 헷갈리지 않게)
    setRain(on) { if (!ctx) return; rainGain ??= loopNoise('lowpass', 1100, 0.3); rainGain.gain.setTargetAtTime(on ? 0.03 : 0, ctx.currentTime, 0.5); },
    // 배경 음악: 일본 음계(요나누키)로 코토처럼 뜯는 멜로디 + 부드러운 화음 + 베이스를 그 자리에서 만들어 연주
    music(on) {
      if (!ctx) return;
      if (!musicGain) { musicGain = ctx.createGain(); musicGain.gain.value = 0; musicGain.connect(master); }
      musicGain.gain.setTargetAtTime(on ? 0.5 : 0, ctx.currentTime, 0.4);
      if (on && !musicTimer) { nextBeat = ctx.currentTime + 0.1; musicTimer = setInterval(scheduleMusic, 100); }
      if (!on && musicTimer) { clearInterval(musicTimer); musicTimer = null; }
    },
    update(dt) {
      if (!ctx) return;
      const now = ctx.currentTime;
      boilGain.gain.setTargetAtTime(boilTarget * 0.06, now, 0.3);
      sizzleGain.gain.setTargetAtTime(sizzleOn ? 0.1 * (0.6 + Math.random() * 0.8) : 0, now, 0.03);
      if (boilTarget > 0 && Math.random() < dt * boilTarget * 8) tone(250 + Math.random() * 450, 0.07, { vol: 0.035, slide: 1.8 });
      if (sizzleOn && Math.random() < dt * 25) burst(0.02, 'highpass', 4000, 0.09);
    },
    setBoil(v) { boilTarget = v; },
    setSizzle(on) { sizzleOn = on; },
    pick() { tone(900, 0.06, { type: 'triangle', vol: 0.08 }); },
    place() { tone(240, 0.12, { vol: 0.14, slide: 0.7 }); burst(0.05, 'lowpass', 1400, 0.08); },
    pour() { burst(0.45, 'bandpass', 900, 0.14); burst(0.3, 'bandpass', 600, 0.08, 0.1); },
    ding() { tone(1568, 1.2, { vol: 0.12 }); tone(2093, 1.0, { vol: 0.05, delay: 0.02 }); },
    happy() { [523, 659, 784, 1047].forEach((f, i) => tone(f, 0.25, { type: 'triangle', vol: 0.09, delay: i * 0.08 })); },
    normal() { tone(523, 0.2, { type: 'triangle', vol: 0.08 }); tone(587, 0.25, { type: 'triangle', vol: 0.08, delay: 0.1 }); },
    angry() { tone(180, 0.4, { type: 'sawtooth', vol: 0.05, slide: 0.6 }); tone(140, 0.5, { type: 'sawtooth', vol: 0.045, delay: 0.15, slide: 0.6 }); },
    kaedama() { tone(880, 0.15, { type: 'square', vol: 0.05 }); tone(1175, 0.25, { type: 'square', vol: 0.05, delay: 0.15 }); },
    trash() { burst(0.2, 'lowpass', 600, 0.16); },
    knob() { tone(1400, 0.03, { type: 'square', vol: 0.05 }); tone(1000, 0.03, { type: 'square', vol: 0.04, delay: 0.04 }); },
    fire() { burst(0.4, 'bandpass', 300, 0.16); },
    splash() { burst(0.25, 'bandpass', 1500, 0.12); },
    door() { burst(0.35, 'bandpass', 650, 0.07); tone(140, 0.08, { vol: 0.05, delay: 0.3 }); },
    // who: { voice, pitch, rate } — 손님마다 목소리를 다르게
    say(text, who = {}) {
      try {
        const v = who.voice ?? Voices.best();
        if (!v) return; // 음성 목록이 아직 없으면 기본(다른 성별) 목소리가 섞이지 않게 건너뜀
        const u = new SpeechSynthesisUtterance(text);
        u.lang = 'ja-JP'; u.voice = v;
        u.pitch = who.pitch ?? 1; u.rate = who.rate ?? 1.05; u.volume = 0.9;
        speechSynthesis.speak(u);
      } catch (e) { /* 음성 미지원 브라우저 */ }
    },
    // 대사 재생: 음성 파일(VoiceFiles)이 있으면 그걸, 없으면 읽어 주기 음성
    line(key, text, who = {}) {
      const buf = ctx && VoiceFiles.get(key, who.vv);
      if (!buf) return this.say(text, who);
      const src = ctx.createBufferSource(); src.buffer = buf;
      src.playbackRate.value = who.fileRate ?? 1; // 같은 목소리라도 사람마다 높낮이가 아주 살짝 다르게
      const g = ctx.createGain(); g.gain.value = 1.3;
      src.connect(g).connect(master); src.start();
    },
    decode: ab => ctx.decodeAudioData(ab),
    get ready() { return !!ctx; },
    setVolume(v) { if (master) master.gain.value = 0.7 * v; },
  };
})();

// 음성 파일 미리 불러오기. 우선순위: 직접 녹음한 voices/<key>.mp3 (README.txt 참고)
// → VOICEVOX로 만든 음성 voices/vv/<key>_<목소리>.mp4 (tools/make_voices.py). 없으면 브라우저 읽어 주기
// <audio> 여러 개를 한꺼번에 불러오면 브라우저가 일부를 끝까지 안 불러올 수 있어서, 파일을 내려받아 메모리에 풀어 둔다
const HK_VOICE = new Set(['umai', 'gochisousama', 'kaedama_katame', 'kaedama_futsu', 'kaedama_yawa']); // 하카타 사투리 음성이 따로 있는 대사 (<key>_hk)
const YK_VOICE = new Set(['umai', 'gochisousama']); // 요코하마 하마 말투 음성 (<key>_yk) · 삿포로 홋카이도 말투 음성 (<key>_sp)
const VOICE_KEYS = ['irasshaimase', 'arigatou', 'itadakimasu', 'umai', 'gochisousama', 'kaedama_katame', 'kaedama_futsu', 'kaedama_yawa',
  ...(HAKATA ? [...HK_VOICE].map(k => k + '_hk') : []), ...(YOKO ? [...[...YK_VOICE].map(k => k + '_yk'), 'kko'] : []), ...(SAPPO ? [...[...YK_VOICE].map(k => k + '_sp'), 'misobutter'] : [])];
const SHOP_KEYS = ['irasshaimase', 'arigatou'];
// VOICEVOX 목소리 그룹별 인원 (tools/make_voices.py의 CAST와 같게): 셰프 · 남자 · 학생 · 여자 · 할아버지 · 할머니
const VV_CAST = { chef: 1, m: 4, st: 1, f: 6, om: 2, of: 2 };
const VoiceFiles = (() => {
  const raw = {}, ok = {};
  const load = (id, src) => fetch(src).then(r => (r.ok ? r.arrayBuffer() : null)).then(ab => { if (ab) { raw[id] = ab; decode(); } }).catch(() => {});
  // 소리 장치는 첫 클릭 뒤에야 생기므로, 그 뒤에 한 번씩 풀어 둔다
  function decode() {
    if (!Sound.ready) return;
    for (const id of Object.keys(raw)) {
      const ab = raw[id]; delete raw[id];
      Sound.decode(ab).then(b => { ok[id] = b; }).catch(() => {});
    }
  }
  for (const key of VOICE_KEYS) {
    load(key, `voices/${key}.mp3`);
    for (const [g, n] of Object.entries(VV_CAST)) {
      if ((g === 'chef') !== SHOP_KEYS.includes(key)) continue; // 인사는 셰프만, 손님 대사는 손님만
      for (let i = 0; i < n; i++) load(`vv/${key}_${g}${i}`, `voices/vv/${key}_${g}${i}.mp4`);
    }
  }
  return {
    decode,
    get: (key, vv) => ok[key] || (vv && ok[`vv/${key}_${vv}`]) || null,
    loaded: () => Object.keys(ok),
  };
})();

// 일본어 음성 고르기: 고품질(Premium·Enhanced·Natural) 음성을 우선 사용
const Voices = (() => {
  let list = [];
  const score = v => (/premium|enhanced|natural|neural|siri|프리미엄|고품질/i.test(v.name) ? 10 : 0) + (/online|google/i.test(v.name) ? 5 : 0)
    + (/^(Kyoko|O-ren|Otoya|Hattori)/i.test(v.name) ? 3 : 0) - (/^(Eddy|Flo|Grandma|Grandpa|Reed|Rocko|Sandy|Shelley|Bad|Bubbles|Boing|Jester|Organ|Trinoids|Whisper|Zarvox)/i.test(v.name) ? 10 : 0); // 장난감 같은 음성은 제외
  function load() {
    try {
      list = speechSynthesis.getVoices().filter(v => /^ja/i.test(v.lang)).sort((a, b) => score(b) - score(a));
    } catch (e) { list = []; }
  }
  load();
  try { speechSynthesis.addEventListener('voiceschanged', load); } catch (e) { /* 미지원 */ }
  return {
    best: () => list[0] || null,
    // 품질이 비슷한 상위 음성들 중에서 무작위로 (없으면 가장 좋은 음성)
    random() {
      if (!list.length) return null;
      const top = list.filter(v => score(v) >= score(list[0]) - 1);
      return top[Math.floor(Math.random() * top.length)];
    },
    // 성별에 맞는 음성 (macOS 일본어: Kyoko·O-ren 여성, Otoya·Hattori 남성). 없으면 null
    byGender(female) {
      const re = female ? /kyoko|o-ren|female|女/i : /otoya|hattori|male|男/i;
      const m = list.filter(v => re.test(v.name) && !(female ? /otoya|hattori/i : /kyoko|o-ren|female/i).test(v.name));
      return m.length ? m[Math.floor(Math.random() * m.length)] : null;
    },
    names: () => list.map(v => v.name),
  };
})();
// 가게(셰프) 인사는 항상 같은 목소리 (가장 좋은 음성을 한 번 정하면 계속 사용)
let shopVoice = null;
const SHOP_VOICE = {
  pitch: 1, rate: 1.08, fileRate: 1, vv: 'chef0',
  get voice() { return shopVoice ??= Voices.best(); },
};
