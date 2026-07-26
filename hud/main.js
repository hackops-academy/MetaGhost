const { app, BrowserWindow, ipcMain, dialog, shell } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 920,
    minWidth: 1024,
    minHeight: 680,
    backgroundColor: '#080a14',
    title: 'MetaGhost // Forensics Console',
    icon: path.join(__dirname, 'logo.svg'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });
  win.loadFile('index.html');
}

// Runs in Node (main process), not the renderer's browser context, so
// there's no CORS restriction regardless of method/body used.
ipcMain.handle('api-request', async (event, { baseUrl, apiPath, method, params, body }) => {
  let url = baseUrl.replace(/\/$/, '') + apiPath;
  const opts = { method: method || 'GET', headers: {} };

  if (params && Object.keys(params).length) {
    const qs = new URLSearchParams(params).toString();
    url += (url.includes('?') ? '&' : '?') + qs;
  }
  if (body !== undefined) {
    opts.headers['Content-Type'] = 'application/json';
    opts.body = JSON.stringify(body);
  }

  try {
    const res = await fetch(url, opts);
    let data;
    try {
      data = await res.json();
    } catch {
      data = null;
    }
    if (!res.ok) {
      return { ok: false, status: res.status, error: (data && data.error) || 'HTTP ' + res.status };
    }
    return { ok: true, data: (data && data.data !== undefined) ? data.data : data };
  } catch (err) {
    return { ok: false, error: err.message };
  }
});

// Native "pick a file" dialog - returns an absolute path exiftool can
// read directly, no upload step needed.
ipcMain.handle('pick-file', async (event, { title, filters }) => {
  const win = BrowserWindow.getFocusedWindow();
  const result = await dialog.showOpenDialog(win, {
    title: title || 'Select a file',
    properties: ['openFile'],
    filters: filters || [
      { name: 'Media & Documents', extensions: ['jpg', 'jpeg', 'png', 'gif', 'tiff', 'heic', 'mp4', 'mov', 'pdf', 'docx'] },
      { name: 'All Files', extensions: ['*'] },
    ],
  });
  if (result.canceled || !result.filePaths.length) return { ok: false, canceled: true };
  return { ok: true, path: result.filePaths[0] };
});

// Native "pick a folder" dialog for bulk operations.
ipcMain.handle('pick-directory', async (event, { title }) => {
  const win = BrowserWindow.getFocusedWindow();
  const result = await dialog.showOpenDialog(win, {
    title: title || 'Select a directory',
    properties: ['openDirectory'],
  });
  if (result.canceled || !result.filePaths.length) return { ok: false, canceled: true };
  return { ok: true, path: result.filePaths[0] };
});

// Reveal a cleaned/backup/report file in the OS file manager.
ipcMain.handle('reveal-in-folder', async (event, { targetPath }) => {
  try {
    shell.showItemInFolder(targetPath);
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err.message };
  }
});

// Open a generated HTML report in the system's default browser.
ipcMain.handle('open-external', async (event, { url }) => {
  try {
    await shell.openExternal(url);
    return { ok: true };
  } catch (err) {
    return { ok: false, error: err.message };
  }
});

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
