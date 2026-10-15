(() => {
  const stage = document.getElementById('stage');
  if (!stage || typeof ResizeObserver === 'undefined') return;

  const resizeObserver = new ResizeObserver(() => {
    window.dispatchEvent(new Event('resize'));
  });
  resizeObserver.observe(stage);
})();
