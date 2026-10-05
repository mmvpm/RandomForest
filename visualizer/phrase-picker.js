"use strict";

// Renders phrase suggestions in the page instead of a misplaced native popup.
function createPhrasePicker({ input, list, getValue, onSelect, onInvalid }) {
  let phrases = [], options = [], buttons = [], active = -1;

  // Closes suggestions without changing the saved phrase selection.
  function close() {
    list.hidden = true;
    input.setAttribute("aria-expanded", "false");
    input.removeAttribute("aria-activedescendant");
    active = -1;
  }

  // Commits a library phrase or the automatic pool option.
  function choose(id) {
    input.value = id; close(); onSelect();
  }

  // Highlights one keyboard option while keeping focus in the input.
  function highlight(index) {
    active = Math.max(0, Math.min(buttons.length - 1, index));
    buttons.forEach((button, i) => button.setAttribute("aria-selected", String(i === active)));
    input.setAttribute("aria-activedescendant", buttons[active].id);
    buttons[active].scrollIntoView?.({ block: "nearest" });
  }

  // Filters by readable phrase text or its stable configuration ID.
  function show() {
    if (input.disabled) return;
    const query = input.value.trim().toLocaleLowerCase();
    options = [{ id: "", text: "Автоматически из пула" }, ...phrases.filter(phrase =>
      phrase.id.toLocaleLowerCase().includes(query) || phrase.text.toLocaleLowerCase().includes(query))];
    list.replaceChildren(); active = -1;
    buttons = options.map((phrase, index) => {
      const button = document.createElement("button");
      button.type = "button"; button.className = "memory-phrase-option";
      button.tabIndex = -1;
      button.id = `${list.id}-option-${index}`;
      button.textContent = phrase.id ? `${phrase.text} · ${phrase.id}` : phrase.text;
      button.setAttribute("role", "option"); button.setAttribute("aria-selected", "false");
      button.addEventListener("pointerdown", event => event.preventDefault());
      button.addEventListener("click", () => choose(phrase.id));
      list.appendChild(button); return button;
    });
    list.hidden = false;
    input.setAttribute("aria-expanded", "true");
  }

  // Accepts exact IDs; free search text must never turn into an invalid game ID.
  function commitTyped() {
    const id = input.value.trim();
    if (!id || id === getValue() || phrases.some(phrase => phrase.id === id)) {
      choose(id);
    } else {
      input.value = getValue(); close(); onInvalid();
    }
  }

  // Supports the usual combobox keys without triggering map shortcuts.
  function keyboard(event) {
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      if (list.hidden) show();
      const down = event.key === "ArrowDown";
      highlight(active < 0 ? (down ? 0 : buttons.length - 1) : active + (down ? 1 : -1));
      event.preventDefault();
    } else if (event.key === "Enter") {
      if (!list.hidden && active >= 0) choose(options[active].id);
      else commitTyped();
      event.preventDefault();
    } else if (event.key === "Escape") {
      input.value = getValue(); close(); event.preventDefault();
    }
  }

  // Refreshes suggestions after the authored phrase library finishes loading.
  function setOptions(values) {
    phrases = values;
    if (!list.hidden) show();
  }

  input.addEventListener("focus", show);
  input.addEventListener("input", show);
  input.addEventListener("keydown", keyboard);
  input.addEventListener("change", commitTyped);
  input.addEventListener("blur", close);
  close();
  return { setOptions, close };
}

if (typeof module !== "undefined") module.exports = { createPhrasePicker };
