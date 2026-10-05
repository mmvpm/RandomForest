"use strict";

// Keeps unsaved level drafts separate from the last successfully written JSON.
function createLevelPersistence({ state, getPath, getSaveUrl, statusUrl, setStatus, onChange,
  request = (...args) => fetch(...args) }) {
  const drafts = new Map();
  let queue = Promise.resolve();
  let available = null;
  const serverHint = "Сервер сохранения недоступен. Запустите python3 visualizer/server.py";

  // Bounds network waits so a stalled server cannot keep the save queue locked.
  async function fetchWithTimeout(url, options) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3000);
    try {
      return await request(url, { ...options, signal: controller.signal });
    } finally {
      clearTimeout(timeout);
    }
  }

  // Reports the current draft without replacing it with an older disk version.
  function reportStatus() {
    const draft = drafts.get(state.levelNumber);
    if (draft?.pending) {
      setStatus("Сохранение изменений…", getPath(state.levelNumber));
    } else if (available === false) {
      setStatus(draft ? "Правки не сохранены" : "Сохранение недоступно", serverHint, true);
    } else if (draft) {
      setStatus("Правки не сохранены", draft.error || "Изменения остаются в памяти страницы", true);
    } else {
      return false;
    }
    return true;
  }

  // Checks that the loopback server supports saving, with a bounded wait.
  async function checkConnection() {
    try {
      const response = await fetchWithTimeout(statusUrl, { cache: "no-store" });
      if (!response.ok || (await response.json()).can_save !== true) throw new Error("Нет сервера сохранения");
      available = true;
    } catch {
      available = false;
    }
    reportStatus(); onChange();
    return available;
  }

  // Writes one immutable snapshot; only the latest revision can clear its draft.
  async function write(draft, text, revision) {
    try {
      const response = await fetchWithTimeout(getSaveUrl(draft.number), {
        method: "PUT", headers: { "Content-Type": "application/json; charset=utf-8" }, body: text
      });
      available = true;
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      draft.savedText = text;
      if (state.levelNumber === draft.number) {
        state.loadedPath = getPath(draft.number);
        state.loadedText = text;
      }
      if (draft.revision === revision) {
        drafts.delete(draft.number);
        if (state.levelNumber === draft.number) {
          setStatus(`Уровень ${String(draft.number).padStart(2, "0")} · изменения сохранены`,
            `${getPath(draft.number)} · ${new Date().toLocaleTimeString("ru-RU")}`);
        }
      }
    } catch (error) {
      if (error instanceof TypeError || error.name === "AbortError") available = false;
      draft.error = `${getPath(draft.number)} · ${error.message}`;
    } finally {
      draft.pending -= 1;
      reportStatus(); onChange();
    }
  }

  // Serializes each committed gesture and keeps all writes in their original order.
  function save() {
    if (!state.level || !state.loadedPath) return queue;
    let draft = drafts.get(state.levelNumber);
    if (!draft) {
      draft = { number: state.levelNumber, savedText: state.loadedText, pending: 0 };
      drafts.set(state.levelNumber, draft);
    }
    draft.level = state.level;
    draft.undoStack = state.undoStack;
    draft.revision = state.editRevision;
    draft.error = "";
    const text = `${JSON.stringify(state.level, null, 2)}\n`;
    const revision = draft.revision;
    draft.pending += 1;
    reportStatus(); onChange();
    queue = queue.then(() => write(draft, text, revision));
    return queue;
  }

  // Rechecks the connection before retrying the current, not the failed, snapshot.
  async function retry() {
    if (isSaving() || !drafts.has(state.levelNumber)) return;
    const number = state.levelNumber;
    if (await checkConnection() && number === state.levelNumber) return save();
  }

  // Returns whether the selected level has queued writes.
  function isSaving() { return Boolean(drafts.get(state.levelNumber)?.pending); }

  return { save, retry, checkConnection, reportStatus, isSaving,
    hasUnsaved: (number = state.levelNumber) => drafts.has(number),
    getDraft: number => drafts.get(number) };
}

if (typeof module !== "undefined") module.exports = { createLevelPersistence };
