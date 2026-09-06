import { apiGet, apiPost, timeAgo } from '../api.js';

let root, ctx, timer, lastFetch = 0, links = {};

async function load() {
  let data;
  try {
    data = await apiGet('/api/github');
  } catch (e) {
    ctx.toast('Could not load GitHub data: ' + e.message, 'error');
    return;
  }
  lastFetch = Date.now();
  render(data);
}

function milestoneCard(m) {
  const { el } = ctx;
  return el('div', { class: 'card' },
    el('div', { style: 'display:flex;justify-content:space-between;align-items:baseline' },
      el('a', { href: m.url, target: '_blank', rel: 'noopener' }, m.title),
      el('span', { class: 'chip' }, m.closed + '/' + m.total)),
    el('div', { class: 'progress' }, el('div', { style: 'width:' + m.percent + '%' })));
}

function pipelineColumn(title, items) {
  const { el } = ctx;
  return el('div', { class: 'pipeline-col' },
    el('h4', {}, title + ' (' + items.length + ')'),
    items.length
      ? items.map((pr) => el('div', { class: 'pipeline-item' },
          el('a', { href: pr.url, target: '_blank', rel: 'noopener' }, '#' + pr.number), ' ' + pr.title))
      : el('div', { class: 'hint', style: 'color:var(--muted);font-size:12px' }, 'none'));
}

function render(data) {
  const { el, emptyState } = ctx;
  root.innerHTML = '';
  root.append(el('div', { class: 'section-title' }, el('h2', {}, 'Overview'),
    el('span', { class: 'stale' }, 'GitHub data ' + timeAgo(lastFetch / 1000)),
    el('button', { onclick: () => apiPost('/api/refresh', {}).then(load) }, 'Refresh')));

  root.append(el('h3', {}, 'Milestones'));
  root.append(data.milestones.length
    ? el('div', { class: 'grid cols-3' }, data.milestones.map(milestoneCard))
    : emptyState('No milestones yet', 'Milestones appear here once the feature-planner creates one.'));

  root.append(el('h3', {}, 'PR pipeline'));
  root.append(el('div', { class: 'card' }, el('div', { class: 'pipeline' },
    pipelineColumn('In progress', data.pipeline.in_progress),
    pipelineColumn('In review', data.pipeline.in_review),
    pipelineColumn('Awaiting eyeball', data.pipeline.awaiting_eyeball),
    pipelineColumn('Ready to merge', data.pipeline.ready_to_merge))));

  root.append(el('h3', {}, 'From eyeball'));
  root.append(data.eyeball_issues.length
    ? el('div', { class: 'card table-scroll' }, el('table', {},
        el('thead', {}, el('tr', {}, el('th', {}, 'Issue'), el('th', {}, 'Title'), el('th', {}, 'Milestone'))),
        el('tbody', {}, data.eyeball_issues.map((i) => el('tr', {},
          el('td', {}, el('a', { href: i.url, target: '_blank', rel: 'noopener' }, '#' + i.number)),
          el('td', {}, i.title),
          el('td', {}, i.milestone || '-'))))))
    : emptyState('No open eyeball-filed issues', 'Bugs and improvements filed from a failed check show up here.'));

  root.append(el('h3', {}, 'Quick links'));
  const entries = Object.entries(links);
  root.append(entries.length
    ? el('div', { class: 'card' }, entries.map(([name, url]) =>
        el('div', {}, el('a', { href: url, target: '_blank', rel: 'noopener' }, name))))
    : emptyState('No links configured', 'Add them under links: in project.yaml.'));
}

export const overviewSection = {
  async mount(rootEl, context) {
    root = rootEl; ctx = context;
    root.append(ctx.el('div', {}, 'Loading...'));
    try {
      const state = await apiGet('/api/state');
      links = state.project.links || {};
    } catch (e) { /* fast-state banner already covers this */ }
    await load();
    timer = setInterval(load, 60000);
  },
  unmount() { clearInterval(timer); },
  onFastState(data) { links = data.project.links || links; },
};
