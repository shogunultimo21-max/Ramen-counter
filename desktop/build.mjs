// 웹 게임(../index.html)을 PC 프로그램용으로 복사하는 스크립트
// - 3D 엔진(three.js)과 글꼴을 인터넷 대신 게임 안의 파일로 바꿔서 오프라인에서도 돌아가게 함
// - 결과물은 desktop/app/ 에 생김 (git에는 안 올라감)
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const out = path.resolve(import.meta.dirname, 'app');
fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(out, { recursive: true });

// 1) index.html: 인터넷 주소 → 게임 안 파일
let html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const swap = (from, to) => {
  if (!html.includes(from)) throw new Error(`index.html에서 못 찾음: ${from}`);
  html = html.replaceAll(from, to);
};
swap('https://unpkg.com/three@0.160.0/build/three.module.js', './vendor/three/three.module.js');
swap('https://unpkg.com/three@0.160.0/examples/jsm/', './vendor/three/jsm/');
html = html.replace(/<link rel="preconnect"[^>]*>/g, '');
swap('https://fonts.googleapis.com/css2?family=Jua&family=Song+Myung&family=Yuji+Syuku&display=swap', './vendor/fonts/fonts.css');
html = html.replace('<head>', '<head>\n<script>window.IS_DESKTOP = true;</script>');
fs.writeFileSync(path.join(out, 'index.html'), html);

// 2) three.js 엔진 + 쓰는 부가 기능(addons)만
const three = path.resolve(import.meta.dirname, 'node_modules/three');
const copy = (src, dst) => { fs.mkdirSync(path.dirname(dst), { recursive: true }); fs.copyFileSync(src, dst); };
copy(path.join(three, 'build/three.module.js'), path.join(out, 'vendor/three/three.module.js'));
for (const f of ['environments/RoomEnvironment.js']) copy(path.join(three, 'examples/jsm', f), path.join(out, 'vendor/three/jsm', f));
// 고화질용: 화면 효과(빛 번짐)와 HDR 조명 불러오기 — 서로 불러 쓰는 파일이 많아 폴더째
for (const d of ['postprocessing', 'shaders']) fs.cpSync(path.join(three, 'examples/jsm', d), path.join(out, 'vendor/three/jsm', d), { recursive: true });
copy(path.join(three, 'examples/jsm/loaders/RGBELoader.js'), path.join(out, 'vendor/three/jsm/loaders/RGBELoader.js'));
// 3D 손님: 모델 불러오기 + 같은 모델을 여러 명으로 복제
for (const f of ['loaders/GLTFLoader.js', 'utils/BufferGeometryUtils.js', 'utils/SkeletonUtils.js']) copy(path.join(three, 'examples/jsm', f), path.join(out, 'vendor/three/jsm', f));

// 3) 글꼴 (desktop/fonts — 미리 받아 둔 송명체·유지슈쿠)
fs.cpSync(path.resolve(import.meta.dirname, 'fonts'), path.join(out, 'vendor/fonts'), { recursive: true });

// 4) 음성 파일
fs.cpSync(path.join(root, 'voices'), path.join(out, 'voices'), { recursive: true });
// 5) 그림 (등장인물 얼굴 등 — 게임용 축소본)
fs.cpSync(path.join(root, 'img'), path.join(out, 'img'), { recursive: true });
for (const f of ['manifest.json', 'icon.png', 'icon-192.png', 'icon-512.png', 'apple-touch-icon.png']) {
  if (fs.existsSync(path.join(root, f))) copy(path.join(root, f), path.join(out, f));
}
console.log('PC용 게임 파일 준비 완료 →', out);
