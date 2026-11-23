// 인생라멘 PC판 (Electron) — 게임 창을 띄우는 프로그램
// 게임 파일은 app:// 주소로 열어서 웹에서와 똑같이 모듈·음성 파일·저장(localStorage)이 동작하게 함
const { app, BrowserWindow, protocol, net, Menu, shell } = require('electron');
const path = require('node:path');
const fs = require('node:fs');
const { pathToFileURL } = require('node:url');

const GAME_DIR = path.join(__dirname, 'app');
// 개발 확인용 실행(RAMEN_DEBUG)은 저장 기록을 따로 써서, 실제로 플레이하는 기록을 건드리지 않게
if (process.env.RAMEN_DEBUG) app.setPath('userData', path.join(app.getPath('temp'), 'insaeng-ramen-debug'));

// app:// 를 일반 웹 주소처럼 다루게 등록 (모듈 import · fetch · 저장소 허용)
protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { standard: true, secure: true, supportFetchAPI: true, corsEnabled: true, stream: true } },
]);

function createWindow() {
  const win = new BrowserWindow({
    width: 1280, height: 720, minWidth: 960, minHeight: 540,
    backgroundColor: '#120d0a',
    title: '인생라멘',
    autoHideMenuBar: true,
    webPreferences: { contextIsolation: true, sandbox: true },
  });
  win.loadURL('app://game/index.html');
  // 개발 확인용: RAMEN_DEBUG=캡처파일경로 로 켜면 콘솔 오류를 출력하고 7초 뒤 화면을 저장
  if (process.env.RAMEN_DEBUG) {
    win.webContents.on('console-message', (e, level, message) => { if (level >= 2) console.log('[game]', message); });
    win.webContents.on('did-finish-load', () => setTimeout(async () => {
      if (process.env.RAMEN_DEBUG_JS) { try { console.log('[debug js]', await win.webContents.executeJavaScript(process.env.RAMEN_DEBUG_JS)); } catch (err) { console.log('[debug js error]', err.message); } }
      const img = await win.webContents.capturePage();
      require('node:fs').writeFileSync(process.env.RAMEN_DEBUG, img.toPNG());
      console.log('[debug] saved', process.env.RAMEN_DEBUG);
    }, 7000));
  }
  // 게임 안의 바깥 링크(웹사이트)는 기본 브라우저로 열기
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:/.test(url)) shell.openExternal(url);
    return { action: 'deny' };
  });
  // F11 · ⌃⌘F 로 전체 화면 전환
  win.webContents.on('before-input-event', (e, input) => {
    if (input.type === 'keyDown' && (input.key === 'F11' || (input.key === 'f' && input.control && input.meta))) {
      win.setFullScreen(!win.isFullScreen()); e.preventDefault();
    }
  });
}

app.whenReady().then(() => {
  protocol.handle('app', req => {
    const { pathname } = new URL(req.url);
    const file = path.normalize(path.join(GAME_DIR, decodeURIComponent(pathname)));
    if (!file.startsWith(GAME_DIR) || !fs.existsSync(file)) return new Response('Not found', { status: 404 }); // 게임 폴더 밖·없는 파일

    return net.fetch(pathToFileURL(file).toString());
  });
  if (process.platform === 'darwin') Menu.setApplicationMenu(Menu.buildFromTemplate([{ role: 'appMenu' }, { role: 'editMenu' }, { role: 'viewMenu' }, { role: 'windowMenu' }]));
  else Menu.setApplicationMenu(null);
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on('window-all-closed', () => app.quit());
