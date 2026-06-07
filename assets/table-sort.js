(function () {
  const collator = new Intl.Collator(undefined, { numeric: true, sensitivity: "base" });

  function normalize(text) {
    return String(text || "").replace(/\s+/g, " ").trim();
  }

  function parseNumber(text) {
    const cleaned = normalize(text).replace(/[,%$]/g, "").replace(/[()]/g, "").trim();
    if (!cleaned || !/^-?\d+(?:\.\d+)?$/.test(cleaned)) return null;
    const value = Number(cleaned);
    return Number.isFinite(value) ? value : null;
  }

  function parseDate(text) {
    const value = normalize(text);
    if (!/^\d{4}-\d{2}-\d{2}$|^\d{1,2}\/\d{1,2}\/\d{4}/.test(value)) return null;
    const timestamp = Date.parse(value);
    return Number.isNaN(timestamp) ? null : timestamp;
  }

  function comparable(text) {
    const value = normalize(text);
    if (!value) return { type: "empty", value: "" };

    const number = parseNumber(value);
    if (number !== null) return { type: "number", value: number };

    const date = parseDate(value);
    if (date !== null) return { type: "date", value: date };

    return { type: "text", value };
  }

  function compareCells(a, b, direction) {
    if (a.type === "empty" && b.type !== "empty") return 1;
    if (b.type === "empty" && a.type !== "empty") return -1;

    let result = 0;
    if ((a.type === "number" && b.type === "number") || (a.type === "date" && b.type === "date")) {
      result = a.value - b.value;
    } else {
      result = collator.compare(String(a.value), String(b.value));
    }

    return result * direction;
  }

  function updateHeaders(table, activeIndex, direction) {
    Array.from(table.tHead.rows[0].cells).forEach((th, index) => {
      const indicator = th.querySelector(".sort-indicator");
      const isActive = index === activeIndex;
      th.setAttribute("aria-sort", isActive ? (direction === 1 ? "ascending" : "descending") : "none");
      if (indicator) indicator.textContent = isActive ? (direction === 1 ? "asc" : "desc") : "sort";
    });
  }

  function sortTable(table, columnIndex) {
    const tbody = table.tBodies[0];
    if (!tbody) return;

    const previousIndex = Number(table.dataset.sortIndex || -1);
    const previousDirection = Number(table.dataset.sortDirection || 1);
    const direction = previousIndex === columnIndex ? previousDirection * -1 : 1;

    const rows = Array.from(tbody.rows).map((row, originalIndex) => ({
      row,
      originalIndex,
      value: comparable(row.cells[columnIndex] ? row.cells[columnIndex].textContent : "")
    }));

    rows.sort((a, b) => {
      const result = compareCells(a.value, b.value, direction);
      return result || a.originalIndex - b.originalIndex;
    });

    rows.forEach((item) => tbody.appendChild(item.row));
    table.dataset.sortIndex = String(columnIndex);
    table.dataset.sortDirection = String(direction);
    updateHeaders(table, columnIndex, direction);
  }

  function enhanceTable(table) {
    if (table.dataset.sortReady === "true" || !table.tHead || !table.tBodies.length) return;
    const headerRow = table.tHead.rows[0];
    if (!headerRow) return;

    Array.from(headerRow.cells).forEach((th, columnIndex) => {
      if (th.colSpan > 1) return;
      const label = normalize(th.textContent);
      if (!label) return;

      const button = document.createElement("button");
      button.type = "button";
      button.className = "sort-button";
      button.setAttribute("aria-label", "Sort by " + label);

      const labelSpan = document.createElement("span");
      labelSpan.className = "sort-label";
      labelSpan.textContent = label;

      const indicator = document.createElement("span");
      indicator.className = "sort-indicator";
      indicator.setAttribute("aria-hidden", "true");
      indicator.textContent = "sort";

      button.append(labelSpan, indicator);
      button.addEventListener("click", () => sortTable(table, columnIndex));

      th.textContent = "";
      th.dataset.sortable = "true";
      th.setAttribute("aria-sort", "none");
      th.appendChild(button);
    });

    table.dataset.sortReady = "true";
  }

  function init() {
    document.querySelectorAll("table").forEach(enhanceTable);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, { once: true });
  } else {
    init();
  }
})();
