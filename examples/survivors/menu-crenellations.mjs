// Presentation only: N full square teeth, N-1 equally wide gaps, no end margin.
// W = (2N - 1)s. Keep s near 8 CSS px by adapting N to the available width.
export function crenellationGeometry(width, preferredSize = 8) {
  const teeth = Math.max(2, Math.round((width / preferredSize + 1) / 2));
  const cells = 2 * teeth - 1;
  return { teeth, size: width / cells, step: 100 / cells, period: 200 / cells };
}

if (typeof document !== 'undefined') {
  const observed = new Set();
  function fit(element) {
    const width = element.getBoundingClientRect().width;
    if (width <= 0) return; // ResizeObserver also handles hidden panels opening.
    const { size, step, period } = crenellationGeometry(width);
    element.style.setProperty('--cren-size', `${size}px`);
    element.style.setProperty('--cren-step', `${step}%`);
    element.style.setProperty('--cren-period', `${period}%`);
  }
  const resize = new ResizeObserver(entries => {
    for (const { target } of entries) fit(target);
  });
  function refresh() {
    for (const element of observed) {
      if (!element.isConnected) { resize.unobserve(element); observed.delete(element); }
    }
    for (const element of document.querySelectorAll('.banner-heading,.tab-surface')) {
      if (observed.has(element)) continue;
      observed.add(element); fit(element); resize.observe(element);
    }
  }
  refresh();
  // Watch only rebuilt menu fragments, never the canvas, HUD or network updates.
  const menus = new MutationObserver(refresh);
  for (const selector of ['#menuContent', '#dialog', '#coop-setup-preview', '#coop-offers']) {
    const root = document.querySelector(selector);
    if (root) menus.observe(root, { childList: true, subtree: true });
  }
}
