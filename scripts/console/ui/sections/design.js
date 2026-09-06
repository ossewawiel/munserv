import { apiGet, apiPost } from '../api.js';

let root, ctx, cache = null;

function flattenTokens(node, path = []) {
  const out = [];
  if (node && typeof node === 'object') {
    if (node.$value && typeof node.$value === 'string') {
      out.push({ path: path.join('.'), value: node.$value, description: node.$description || '' });
      return out;
    }
    for (const [k, v] of Object.entries(node)) {
      if (k.startsWith('$')) continue;
      out.push(...flattenTokens(v, [...path, k]));
    }
  }
  return out;
}

function renderMarkdownTable(el, markdown) {
  const lines = markdown.split('\n');
  const blocks = [];
  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (line.startsWith('#')) {
      blocks.push(el(line.startsWith('##') ? 'h4' : 'h3', {}, line.replace(/^#+\s*/, '')));
      i += 1;
    } else if (line.trim().startsWith('|') && lines[i + 1] && /^\|?[\s:-]+\|/.test(lines[i + 1])) {
      const header = line.split('|').map((c) => c.trim()).filter(Boolean);
      const rows = [];
      let j = i + 2;
      while (j < lines.length && lines[j].trim().startsWith('|')) {
        rows.push(lines[j].split('|').map((c) => c.trim()).filter((c, idx, arr) => !(idx === 0 && c === '') && !(idx === arr.length - 1 && c === '')));
        j += 1;
      }
      blocks.push(el('div', { class: 'table-scroll' }, el('table', {},
        el('thead', {}, el('tr', {}, header.map((h) => el('th', {}, h)))),
        el('tbody', {}, rows.map((r) => el('tr', {}, r.map((c) => el('td', { html: c }))))))));
      i = j;
    } else if (line.trim()) {
      blocks.push(el('p', {}, line));
      i += 1;
    } else {
      i += 1;
    }
  }
  return blocks;
}

function canvasCard(c) {
  const { el } = ctx;
  return el('div', { class: 'card' },
    el('div', { style: 'display:flex;justify-content:space-between;align-items:center' },
      el('h3', {}, c.feature),
      el('span', { class: 'chip ' + (c.approved ? 'good' : 'warn') }, c.approved ? 'Approved' : 'Pending approval')),
    c.canvas_url ? el('div', {}, el('a', { href: c.canvas_url, target: '_blank', rel: 'noopener' }, 'Open canvas')) : null,
    el('div', { style: 'margin-top:8px;font-size:12px;color:var(--muted)' },
      c.artboards.length ? c.artboards.map((a) => a.title || a.file).join(', ') : 'no artboards listed'));
}

async function startTool(name) {
  try {
    await apiPost('/api/service/start', { name });
    ctx.toast(name + ' starting - check the Eyeball section for its log', 'success');
  } catch (e) {
    ctx.toast('Could not start ' + name + ': ' + e.message, 'error');
  }
}

function render(links) {
  const { el, emptyState } = ctx;
  root.innerHTML = '';
  root.append(el('div', { class: 'section-title' }, el('h2', {}, 'Design')));

  root.append(el('h3', {}, 'Canvases'));
  root.append(cache.canvases.length
    ? el('div', { class: 'grid cols-2' }, cache.canvases.map(canvasCard))
    : emptyState('No canvases yet', 'The designer agent publishes one per feature under design/canvases/.'));

  root.append(el('h3', {}, 'Component registry'));
  root.append(cache.registry.length
    ? el('div', {}, cache.registry.map((r) => el('div', { class: 'card' }, renderMarkdownTable(el, r.markdown))))
    : emptyState('No registry files found', 'Add one under design/registry/.'));

  root.append(el('h3', {}, 'Colour tokens'));
  const swatches = flattenTokens(cache.tokens);
  root.append(swatches.length
    ? el('div', { class: 'card' }, swatches.map((t) => el('div', { class: 'token-row' },
        el('span', { class: 'swatch', style: 'background:' + t.value }), el('code', {}, t.path), ' ', t.value)))
    : emptyState('No tokens found', 'Add design/tokens/color.tokens.json.'));

  root.append(el('h3', {}, 'Tools'));
  root.append(el('div', { class: 'card', style: 'display:flex;gap:12px;flex-wrap:wrap' },
    el('button', { onclick: () => startTool('storybook') }, 'Start Storybook'),
    links.Storybook ? el('a', { href: links.Storybook, target: '_blank', rel: 'noopener' },
      el('button', {}, 'Open Storybook')) : null,
    links.Widgetbook ? el('a', { href: links.Widgetbook, target: '_blank', rel: 'noopener' },
      el('button', {}, 'Open Widgetbook')) : null));
}

export const designSection = {
  async mount(rootEl, context) {
    root = rootEl; ctx = context;
    root.append(ctx.el('div', {}, 'Loading...'));
    let links = {};
    try {
      const state = await apiGet('/api/state');
      links = state.project.links || {};
    } catch (e) { /* ignore */ }
    try {
      cache = await apiGet('/api/knowledge');
      render(links);
    } catch (e) {
      root.innerHTML = '';
      root.append(ctx.emptyState('Could not load design data', e.message));
    }
  },
  unmount() {},
};
