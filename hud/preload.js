const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('metaghostBridge', {
  request: (baseUrl, apiPath, opts) =>
    ipcRenderer.invoke('api-request', { baseUrl, apiPath, ...opts }),
  pickFile: (title, filters) =>
    ipcRenderer.invoke('pick-file', { title, filters }),
  pickDirectory: (title) =>
    ipcRenderer.invoke('pick-directory', { title }),
  revealInFolder: (targetPath) =>
    ipcRenderer.invoke('reveal-in-folder', { targetPath }),
  openExternal: (url) =>
    ipcRenderer.invoke('open-external', { url }),
});
