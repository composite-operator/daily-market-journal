(function () {
  "use strict";

  var storageKey = "co-market-desk-theme";
  var root = document.documentElement;
  var systemTheme = window.matchMedia("(prefers-color-scheme: dark)");

  function storedTheme() {
    try {
      var value = window.localStorage.getItem(storageKey);
      return value === "light" || value === "dark" ? value : null;
    } catch (error) {
      return null;
    }
  }

  function applyTheme(theme) {
    root.dataset.theme = theme;
    root.style.colorScheme = theme;

    var button = document.querySelector(".theme-toggle");
    if (!button) return;

    var dark = theme === "dark";
    var label = dark ? "Use light mode" : "Use dark mode";
    button.innerHTML = dark ? "&#9788;" : "&#9790;";
    button.setAttribute("aria-label", label);
    button.setAttribute("aria-pressed", String(dark));
    button.title = label;
  }

  function saveTheme(theme) {
    try {
      window.localStorage.setItem(storageKey, theme);
    } catch (error) {
      // The selected theme still applies for this page when storage is blocked.
    }
  }

  applyTheme(storedTheme() || (systemTheme.matches ? "dark" : "light"));

  function installToggle() {
    if (document.querySelector(".theme-toggle")) return;

    var nav = document.querySelector(".top-nav, .site-nav");
    if (!nav) return;

    var button = document.createElement("button");
    button.type = "button";
    button.className = "theme-toggle";
    button.addEventListener("click", function () {
      var nextTheme = root.dataset.theme === "dark" ? "light" : "dark";
      saveTheme(nextTheme);
      applyTheme(nextTheme);
    });
    nav.appendChild(button);
    applyTheme(root.dataset.theme || "light");
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", installToggle, { once: true });
  } else {
    installToggle();
  }

  systemTheme.addEventListener("change", function (event) {
    if (!storedTheme()) applyTheme(event.matches ? "dark" : "light");
  });
})();
