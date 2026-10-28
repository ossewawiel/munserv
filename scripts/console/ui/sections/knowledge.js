import { apiGet, timeAgo } from '../api.js';

let root, ctx, lastFetch = 0, cache = null, search = '';

function conceptCard(c) {
  const { el } = ctx;
  const valueRows = Object.entries(c.values || {}).map(([k, v]) =>
    el('div', { style: 'font-size:12px;color:var(--muted)' }, k + ': ', el('code', {}, (v || []).join(', '))));
  const codeRows = Object.entries(c.code || {}).flatMap(([platform, names]) =>
    (names || []).length ? [el('div', { style: 'font-size:12px;color:var(--muted)' }, platform + ': ', el('code', {}, names.join(', ')))] : []);
  return el('div', { class: 'card' },
    el('h3', {}, c.name),
    el('div', {}, c.definition),
    valueRows, codeRows);
}

function statusCounts(counts) {
  const { el } = ctx;
  return el('div', { style: 'display:flex;gap:8px' },
    el('span', { class: 'chip good' }, counts.done + ' done'),
    el('span', { class: 'chip warn' }, counts.in_progress + ' in progress'),
    el('span', { class: 'chip bad' }, counts.pending + ' pending'));
}

function requirementsCard(req) {
  const { el } = ctx;
  const details = el('div', { hidden: true, class: 'table-scroll' });
  if (req.rows.length) {
    const headers = Object.keys(req.rows[0]);
    details.append(el('table', {},
      el('thead', {}, el('tr', {}, headers.map((h) => el('th', {}, h)))),
      el('tbody', {}, req.rows.map((r) => el('tr', {}, headers.map((h) => el('td', {}, r[h] || '')))))));
  }
  const toggle = el('button', {
    onclick: () => { details.hidden = !details.hidden; toggle.textContent = details.hidden ? 'Show rows' : 'Hide rows'; },
  }, 'Show rows');
  return el('div', { class: 'card' },
    el('div', { style: 'display:flex;justify-content:space-between;align-items:center' },
      el('h3', {}, req.title), statusCounts(req.counts)),
    toggle, details);
}

function adrList(adrs) {
  const { el, emptyState } = ctx;
  if (!adrs.length) return emptyState('No ADRs found', 'Add one under specs/architecture/decisions/.');
  return el('div', { class: 'card' }, adrs.map((a) => el('div', {}, a.file + ' - ' + a.title)));
}

function render() {
  const { el, emptyState } = ctx;
  root.innerHTML = '';
  root.append(el('div', { class: 'section-title' }, el('h2', {}, 'Knowledge'),
    el('span', { class: 'stale' }, 'loaded ' + timeAgo(lastFetch / 1000)),
    el('input', {
      placeholder: 'Search concepts...', value: search,
      oninput: (e) => { search = e.target.value; renderConcepts(); },
    })));

  root.append(el('h3', {}, 'Domain language'));
  root.append(el('div', { id: 'concepts-grid', class: 'grid cols-2' }));
  renderConcepts();

  root.append(el('h3', {}, 'Requirements'));
  root.append(cache.requirements.length
    ? el('div', {}, cache.requirements.map(requirementsCard))
    : emptyState('No requirements tables found', 'Add markdown tables under specs/requirements/.'));

  root.append(el('h3', {}, 'Architecture decisions'));
  root.append(adrList(cache.adrs));

  root.append(el('h3', {}, 'Platform cards'));
  root.append(el('div', { class: 'card' },
    ['backend/CLAUDE.md', 'web/CLAUDE.md', 'mobile/CLAUDE.md', 'database/CLAUDE.md', 'infrastructure/CLAUDE.md']
      .map((p) => el('div', {}, el('code', {}, p)))));
}

function renderConcepts() {
  const { el, emptyState } = ctx;
  const grid = document.getElementById('concepts-grid');
  if (!grid) return;
  grid.innerHTML = '';
  const filtered = cache.concepts.filter((c) =>
    !search || c.name.toLowerCase().includes(search.toLowerCase()) || c.definition.toLowerCase().includes(search.toLowerCase()));
  if (!filtered.length) {
    grid.append(emptyState('No matching concepts', 'domain/README.md defines the vocabulary; language.yaml mirrors it.'));
    return;
  }
  grid.append(...filtered.map(conceptCard));
}

export const knowledgeSection = {
  async mount(rootEl, context) {
    root = rootEl; ctx = context;
    root.append(ctx.el('div', {}, 'Loading...'));
    try {
      cache = await apiGet('/api/knowledge');
      lastFetch = Date.now();
      render();
    } catch (e) {
      root.innerHTML = '';
      root.append(ctx.emptyState('Could not load knowledge data', e.message));
    }
  },
  unmount() {},
};
