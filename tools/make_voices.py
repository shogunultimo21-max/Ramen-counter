# VOICEVOX 엔진(127.0.0.1:50021)으로 게임 대사 음성을 만들어 voices/vv/ 에 저장
# 사용: ~/voicevox/engine/run 을 켠 뒤  python3 tools/make_voices.py
import json, os, subprocess, sys, tempfile, urllib.parse, urllib.request

ENGINE = 'http://127.0.0.1:50021'
OUT = os.path.join(os.path.dirname(__file__), '..', 'voices', 'vv')

# 목소리 그룹: (이름, 스타일 id, 말 빠르기, 음높이, 억양)
CAST = {
    'chef': [('青山龍星', 81, 1.05, 0.0, 1.2)],
    'm':    [('玄野武宏', 11, 1.05, 0.0, 1.1), ('剣崎雌雄', 21, 1.05, 0.0, 1.1), ('雀松朱司', 52, 1.0, 0.0, 1.1), ('麒ヶ島宗麟', 53, 1.0, 0.0, 1.0)],
    'st':   [('白上虎太郎', 12, 1.1, 0.0, 1.2)],
    'f':    [('四国めたん', 2, 1.05, 0.0, 1.1), ('九州そら', 16, 1.05, 0.0, 1.1), ('冥鳴ひまり', 14, 1.05, 0.0, 1.1),
             ('春日部つむぎ', 8, 1.05, 0.0, 1.1), ('波音リツ', 9, 1.05, 0.0, 1.1), ('No.7', 29, 1.05, 0.0, 1.0)],
    'om':   [('ちび式じい', 42, 0.9, 0.0, 1.0), ('麒ヶ島宗麟', 53, 0.85, -0.05, 0.9)],
    'of':   [('もち子さん', 80, 0.85, -0.03, 1.0), ('東北イタコ', 109, 0.85, -0.05, 0.9)],
}
# 대사: 기본 + 그룹별로 말투만 살짝 다르게
LINES = {
    'irasshaimase': {'chef': 'いらっしゃいませー！'},
    'arigatou': {'chef': 'ありがとうございましたー！'},
    'itadakimasu': {'_': 'いただきます！', 'om': 'いただきます。', 'of': 'いただきますね。'},
    'umai': {'m': 'うまい！', 'st': 'うめぇ！', 'f': 'おいしい！', 'om': 'うまいねぇ。', 'of': 'おいしいわぁ。'},
    'gochisousama': {'_': 'ごちそうさまでした！', 'om': 'ごちそうさん。', 'of': 'ごちそうさまでした。'},
    'kaedama_katame': {'_': 'すみません、替え玉カタメで！', 'om': '替え玉、かためで頼むよ。', 'of': '替え玉、かためでお願いね。'},
    'kaedama_futsu': {'_': 'すみません、替え玉お願いします！', 'om': '替え玉、ひとつ頼むよ。', 'of': '替え玉、お願いね。'},
    'kaedama_yawa': {'_': 'すみません、替え玉やわめで！', 'om': '替え玉、やわらかめで頼むよ。', 'of': '替え玉、やわらかめでお願いね。'},
    # 하카타 사투리 (하카타벤) — 후쿠오카 가게에서만 씀
    'umai_hk': {'m': 'うまか！', 'st': 'バリうまか！', 'f': 'バリおいしか〜！', 'om': 'うまかねぇ。', 'of': 'おいしかねぇ。'},
    'gochisousama_hk': {'_': 'ごちそうさん、うまかったばい！', 'f': 'ごちそうさま、バリおいしかった〜！', 'om': 'ごちそうさん。よか味やった。', 'of': 'ごちそうさま。おいしかったばい。'},
    'kaedama_katame_hk': {'_': 'すいません、替え玉ハリガネで！', 'om': '替え玉、ハリガネで頼むばい。', 'of': '替え玉、ハリガネでお願いね。'},
    'kaedama_futsu_hk': {'_': '替え玉、バリカタで頼むばい！', 'om': '替え玉、バリカタで頼むばい。', 'of': '替え玉、バリカタでお願いしようかね。'},
    'kaedama_yawa_hk': {'_': '替え玉、カタでよかよ！', 'om': '替え玉、カタでよか。', 'of': '替え玉、カタでよかよ。'},
}

def post(path, params, body=None):
    url = f'{ENGINE}{path}?{urllib.parse.urlencode(params)}'
    data = json.dumps(body).encode() if body is not None else b''
    req = urllib.request.Request(url, data=data, method='POST', headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as r:
        return r.read()

def synth(text, sid, speed, pitch, inton, dst):
    q = json.loads(post('/audio_query', {'text': text, 'speaker': sid}))
    q.update(speedScale=speed, pitchScale=pitch, intonationScale=inton, volumeScale=1.0, prePhonemeLength=0.05, postPhonemeLength=0.1)
    wav = post('/synthesis', {'speaker': sid}, q)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        f.write(wav)
    subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '64000', f.name, dst], check=True)  # 작게 AAC로
    os.unlink(f.name)

os.makedirs(OUT, exist_ok=True)
count = {}
only = sys.argv[1] if len(sys.argv) > 1 else ''  # 예: python3 tools/make_voices.py _hk  → 이름에 _hk 가 든 대사만 새로 만듦
for key, texts in LINES.items():
    if only and only not in key:
        continue
    for group, voices in CAST.items():
        text = texts.get(group) or (texts.get('_') if group != 'chef' else None)
        if not text:
            continue
        for i, (name, sid, speed, pitch, inton) in enumerate(voices):
            synth(text, sid, speed, pitch, inton, os.path.join(OUT, f'{key}_{group}{i}.mp4'))
        count[group] = len(voices)
json.dump({g: len(v) for g, v in CAST.items()}, open(os.path.join(OUT, 'cast.json'), 'w'))
print('done', sorted(os.listdir(OUT))[:5], len(os.listdir(OUT)), 'files')
print('credits:', ' / '.join(sorted({f'VOICEVOX:{n}' for v in CAST.values() for n, *_ in v})))
