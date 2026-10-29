import { apiGet, timeAgo } from '../api.js';

let root, ctx, timer, lastFetch = 0;

const usd = (n) => '$' + n.toFixed(n >= 100 ? 0 : n >= 1 ? 2 : 4);
const count = (n) => n.toLocaleString('en-US');
const tokenTotal = (tokens) => Object.values(tokens).reduce((a, b) => a + b, 0);

function breakdown(title, rows, maxCost) {
  const { el, emptyState } = ctx;
  if (!rows.length) return el('div', { class: 'card' }, el('h3', {}, title), emptyState('No data'));
  return el('div', { class: 'card table-scroll' },
    el('h3', {}, title),
    el('table', {},
      el('thead', {}, el('tr', {}, ['', 'Cost', 'Input', 'Output', 'Cache read', 'Cache write'].map((h) => el('th', {}, h)))),
      el('tbody', {}, rows.map((r) => el('tr', {},
        el('td', {}, el('div', {}, r.key),
          el('div', { style: `height:4px;border-radius:2px;background:var(--accent);width:${maxCost ? Math.max(2, 100 * r.cost / maxCost) : 0}%` })),
        el('td', {}, usd(r.cost)),
        el('td', {}, count(r.tokens.input)),
        el('td', {}, count(r.tokens.output)),
        el('td', {}, count(r.tokens.cacheRead)),
        el('td', {}, count(r.tokens.cacheCreation)))))));
}

function render(data) {
  const { el, emptyState } = ctx;
  root.innerHTML = '';
  root.append(el('div', { class: 'section-title' }, el('h2', {}, 'Cost'),
    el('span', { class: 'stale' }, 'loaded ' + timeAgo(lastFetch / 1000)),
    el('button', { onclick: () => load() }, 'Refresh')));
  if (!data.available) {
    root.append(emptyState('No telemetry yet',
      'Start the collector (docker compose --profile telemetry up -d) and run Claude Code with telemetry on; see infrastructure/CLAUDE.md.'));
    return;
  }
  root.append(el('div', { class: 'grid cols-3' },
    el('div', { class: 'card' }, el('h3', {}, 'Total cost'), el('div', { style: 'font-size:28px;font-weight:700' }, usd(data.total.cost))),
    el('div', { class: 'card' }, el('h3', {}, 'Tokens'), el('div', { style: 'font-size:28px;font-weight:700' }, count(tokenTotal(data.total.tokens)))),
    el('div', { class: 'card' }, el('h3', {}, 'Days with data'), el('div', { style: 'font-size:28px;font-weight:700' }, data.day.length))));
  const max = (rows) => Math.max(0, ...rows.map((r) => r.cost));
  root.append(el('div', { class: 'grid cols-2', style: 'margin-top:16px' },
    breakdown('Per day', data.day, max(data.day)),
    breakdown('Per agent', data.agent, max(data.agent)),
    breakdown('Per model', data.model, max(data.model)),
    breakdown('Per story', data.story, max(data.story))));
}

async function load() {
  try {
    const data = await apiGet('/api/cost');
    lastFetch = Date.now();
    render(data);
  } catch (e) {
    ctx.toast('Could not load cost data: ' + e.message, 'error');
  }
}

export const costSection = {
  async mount(rootEl, context) {
    root = rootEl; ctx = context;
    root.append(ctx.el('div', {}, 'Loading...'));
    await load();
    timer = setInterval(load, 30000);
  },
  unmount() { clearInterval(timer); },
};
