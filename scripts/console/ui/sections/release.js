import { apiGet, apiPost, timeAgo } from '../api.js';

let root, ctx, timer, lastFetch = 0;
const CHECKLIST_ITEMS = [
  'Smoke eyeball passed on master since the last tag',
  'CHANGELOG.md updated',
  'All milestone issues closed',
];

function checklistState() {
  try {
    return JSON.parse(localStorage.getItem('console-release-checklist') || '{}');
  } catch (e) { return {}; }
}

function setChecklistItem(idx, value) {
  const state = checklistState();
  state[idx] = value;
  localStorage.setItem('console-release-checklist', JSON.stringify(state));
}

function commitGroup(kind, subjects) {
  const { el } = ctx;
  return el('div', {}, el('div', { style: 'font-weight:600;margin-top:8px' }, kind + ' (' + subjects.length + ')'),
    el('ul', {}, subjects.map((s) => el('li', {}, s))));
}

function ciChip(ci) {
  const { el } = ctx;
  if (!ci) return el('span', { class: 'chip' }, 'unknown');
  const cls = ci.overall === 'success' ? 'good' : ci.overall === 'failure' ? 'bad' : 'warn';
  return el('span', { class: 'chip ' + cls }, ci.overall);
}

function copyableCommands(nextVersion) {
  const { el } = ctx;
  const commands = [
    `git tag -a ${nextVersion} -m "${nextVersion}"`,
    `git push origin ${nextVersion}`,
  ];
  return el('pre', { style: 'background:var(--code-bg);padding:8px;border-radius:8px' }, commands.join('\n'));
}

function render(data) {
  const { el, emptyState } = ctx;
  root.innerHTML = '';
  root.append(el('div', { class: 'section-title' }, el('h2', {}, 'Release'),
    el('span', { class: 'stale' }, 'loaded ' + timeAgo(lastFetch / 1000)),
    el('button', { onclick: () => apiPost('/api/refresh', {}).then(load) }, 'Refresh')));

  root.append(el('div', { class: 'grid cols-2' },
    el('div', { class: 'card' },
      el('h3', {}, 'Latest tag'),
      el('div', {}, data.latest_tag || 'no tags yet'),
      el('h3', {}, 'Master CI'),
      ciChip(data.ci)),
    el('div', { class: 'card' },
      el('h3', {}, 'Release checklist'),
      CHECKLIST_ITEMS.map((item, idx) => {
        const state = checklistState();
        const id = 'checklist-' + idx;
        return el('div', {}, el('label', {},
          el('input', { type: 'checkbox', checked: !!state[idx], onchange: (e) => setChecklistItem(idx, e.target.checked) }),
          ' ' + item));
      }))));

  root.append(el('h3', {}, 'Commits since the last tag'));
  const groups = Object.entries(data.commits || {});
  root.append(groups.length
    ? el('div', { class: 'card' }, groups.map(([kind, subjects]) => commitGroup(kind, subjects)))
    : emptyState('No commits since the last tag'));

  root.append(el('h3', {}, 'CHANGELOG.md (head)'));
  root.append(data.changelog_head
    ? el('div', { class: 'card' }, el('pre', { style: 'white-space:pre-wrap' }, data.changelog_head))
    : emptyState('No CHANGELOG.md found'));

  root.append(el('h3', {}, 'Tag and push'));
  root.append(el('div', { class: 'card' }, copyableCommands('vX.Y.Z')));
}

async function load() {
  try {
    const data = await apiGet('/api/release');
    lastFetch = Date.now();
    render(data);
  } catch (e) {
    ctx.toast('Could not load release data: ' + e.message, 'error');
  }
}

export const releaseSection = {
  async mount(rootEl, context) {
    root = rootEl; ctx = context;
    root.append(ctx.el('div', {}, 'Loading...'));
    await load();
    timer = setInterval(load, 60000);
  },
  unmount() { clearInterval(timer); },
};
