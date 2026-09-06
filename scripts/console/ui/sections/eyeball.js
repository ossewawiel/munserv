import { apiGet, apiPost, timeAgo } from '../api.js';
import { requiredServices, buildChecklistViewModel, stageLabel, stageChipClass } from './eyeball.model.mjs';

let root, ctx;
let candidates = [];
let selectedId = null;
let resultsData = null;
let fastState = null;
let accounts = {};
let candidatesFetchedAt = 0;
let candidatesTimer = null;
let logService = null;
let logFilter = '';
let autoScroll = true;
let logTimer = null;
let sequence = { running: false, step: null, error: null };
let pendingParam = null;

function selected() {
  return candidates.find((c) => c.id === selectedId) || null;
}

async function loadCandidates(force) {
  try {
    const data = await apiGet('/api/eyeball/candidates' + (force ? '?refresh=1' : ''));
    candidates = data.candidates;
    accounts = data.accounts || {};
    candidatesFetchedAt = Date.now();
    if (pendingParam && candidates.some((c) => c.id === pendingParam)) {
      selectCandidate(pendingParam, { silent: true });
      pendingParam = null;
    } else if (selectedId) {
      const found = candidates.find((c) => c.id === selectedId);
      resultsData = found ? found.results : resultsData;
    }
    renderAll();
  } catch (e) {
    ctx.toast('Could not load candidates: ' + e.message, 'error');
  }
}

function selectCandidate(id, opts) {
  selectedId = id;
  const c = selected();
  resultsData = c ? c.results : null;
  if (!(opts && opts.silent)) {
    history.replaceState(null, '', '#/eyeball/' + id);
  }
  renderAll();
}

async function saveResults() {
  if (!selectedId || !resultsData) return;
  try {
    await apiPost('/api/eyeball/save', { candidate: selectedId, data: resultsData });
  } catch (e) {
    ctx.toast('Could not save: ' + e.message, 'error');
  }
}

function ensureResultsData() {
  if (!resultsData) resultsData = { candidate: selectedId, checks: {}, observations: [] };
  return resultsData;
}

function setCheckResult(checkId, result) {
  const data = ensureResultsData();
  data.checks[checkId] = data.checks[checkId] || { result: null, note: '', issue_url: null };
  data.checks[checkId].result = data.checks[checkId].result === result ? null : result;
  saveResults();
  renderAll();
}

function setCheckNote(checkId, note) {
  const data = ensureResultsData();
  data.checks[checkId] = data.checks[checkId] || { result: null, note: '', issue_url: null };
  data.checks[checkId].note = note;
  saveResults();
}

function addObservation() {
  const data = ensureResultsData();
  data.observations.push({ kind: 'bug', text: '', issue_url: null });
  saveResults();
  renderAll();
}

// --- stepper sequence ------------------------------------------------------

function stepState(candidate) {
  const checkedOut = candidate.kind === 'smoke' || (fastState && fastState.checkout.branch === candidate.branch);
  const needed = requiredServices(candidate);
  const rows = fastState ? fastState.services.filter((s) => needed.includes(s.name)) : [];
  const needsPrepare = rows.some((r) => r.needs_prepare);
  const allUp = rows.length > 0 && rows.every((r) => r.up || r.manual);
  const vm = buildChecklistViewModel(candidate, resultsData);
  const tested = vm.total > 0 && vm.done === vm.total;
  return { checkedOut, prepared: !needsPrepare, needsPrepare, allUp, tested, submitted: vm.submitted, needed, rows, done: vm.done, total: vm.total };
}

async function refreshFastState() {
  fastState = await apiGet('/api/state');
  return fastState;
}

async function waitForJob(jobId) {
  for (;;) {
    const state = await refreshFastState();
    renderAll();
    const job = state.jobs.find((j) => j.id === jobId);
    if (!job || job.status !== 'running') return job;
    await new Promise((resolve) => setTimeout(resolve, 1500));
  }
}

async function runStepperSequence(candidate) {
  if (sequence.running) return;
  sequence = { running: true, step: 'checkout', error: null };
  renderAll();
  try {
    if (candidate.kind === 'pr') {
      const s0 = stepState(candidate);
      if (!s0.checkedOut) {
        await apiPost('/api/checkout', { branch: candidate.branch });
      }
    }
    sequence.step = 'prepare';
    renderAll();
    // Re-fetch state after checkout: needs_prepare depends on files inside the checkout, which
    // may not have existed (or may have been a different branch) before the checkout above ran.
    const afterCheckout = await refreshFastState();
    const needed = requiredServices(candidate);
    for (const name of needed) {
      const svc = (afterCheckout.services || []).find((s) => s.name === name);
      if (svc && svc.needs_prepare) {
        const { job } = await apiPost('/api/prepare', { name });
        const finished = await waitForJob(job.id);
        if (finished && finished.status === 'failed') {
          throw new Error(name + ' prepare failed: ' + finished.message);
        }
      }
    }
    sequence.step = 'start';
    renderAll();
    await apiPost('/api/service/start-required', { names: needed });
    await refreshFastState();
    sequence = { running: false, step: null, error: null };
    renderAll();
    ctx.toast('Started. Watch the services panel for green.', 'success');
    return;
  } catch (e) {
    sequence = { running: false, step: sequence.step, error: e.message };
    ctx.toast('Could not run the sequence: ' + e.message, 'error');
  } finally {
    renderAll();
  }
}

const STEP_DEFS = [
  { key: 'checkout', num: 1, title: 'Check out' },
  { key: 'prepare', num: 2, title: 'Prepare' },
  { key: 'start', num: 3, title: 'Start' },
  { key: 'test', num: 4, title: 'Test' },
  { key: 'submit', num: 5, title: 'Submit' },
];

function stepStatusText(key, s) {
  if (sequence.running && sequence.step === key) return 'running...';
  if (sequence.error && sequence.step === key) return 'failed: ' + sequence.error;
  if (key === 'checkout') return s.checkedOut ? (fastState.checkout.branch || 'checked out') : 'not checked out';
  if (key === 'prepare') return s.needsPrepare ? 'needed' : 'ready';
  if (key === 'start') return s.needed.length ? s.rows.filter((r) => r.up || r.manual).length + '/' + s.needed.length + ' up' : 'no services';
  if (key === 'test') return s.total ? s.done + '/' + s.total + ' ticked' : 'no checks';
  if (key === 'submit') return s.submitted ? 'submitted' : 'not yet';
  return '';
}

function stepDone(key, s) {
  if (key === 'checkout') return s.checkedOut;
  if (key === 'prepare') return s.prepared;
  if (key === 'start') return s.allUp;
  if (key === 'test') return s.tested;
  if (key === 'submit') return s.submitted;
  return false;
}

function stepperRow(candidate) {
  const { el } = ctx;
  const s = stepState(candidate);
  const items = STEP_DEFS.map((def) => {
    const done = stepDone(def.key, s);
    const failed = sequence.error && sequence.step === def.key;
    return el('div', { class: 'step-h-item' + (done ? ' done' : '') + (failed ? ' failed' : '') },
      el('div', { class: 'step-h-icon' }, done ? '✓' : String(def.num)),
      el('div', {},
        el('div', { class: 'step-h-title' }, def.title),
        el('div', { class: 'step-h-status' }, stepStatusText(def.key, s))));
  });
  return el('div', { class: 'stepper-h' },
    el('button', { class: 'primary', disabled: sequence.running, onclick: () => runStepperSequence(candidate) },
      sequence.running ? 'Running...' : 'Start testing'),
    ...items);
}

// --- right column: services + log panel -------------------------------

function serviceRow(row) {
  const { el } = ctx;
  const dotClass = row.manual ? 'manual' : row.up ? 'up' : 'down';
  const isLogTarget = logService === row.name;
  return el('div', { class: 'service-row' + (isLogTarget ? ' selected' : ''), onclick: () => { logService = row.name; renderAll(); startLogPolling(); } },
    el('span', { class: 'dot ' + dotClass }),
    el('span', { class: 'name' }, row.name),
    row.exit_code != null && !row.up
      ? el('span', { class: 'remedy' }, 'exited ' + row.exit_code + (row.last_log_line ? ' · ' + row.last_log_line : '') + ' · ' + row.remedy)
      : null,
    el('div', { style: 'display:flex;gap:4px', onclick: (e) => e.stopPropagation() },
      row.needs_prepare ? el('button', { onclick: () => apiPost('/api/prepare', { name: row.name }).catch((e) => ctx.toast(e.message, 'error')) }, 'Prepare') : null,
      !row.manual ? el('button', { onclick: () => apiPost('/api/service/start', { name: row.name }).catch((e) => ctx.toast(e.message, 'error')) }, 'Start') : null,
      !row.manual ? el('button', { onclick: () => apiPost('/api/service/stop', { name: row.name }).catch((e) => ctx.toast(e.message, 'error')) }, 'Stop') : null));
}

async function pollLog() {
  if (!logService) return;
  try {
    const data = await apiGet('/api/log?name=' + encodeURIComponent(logService) + '&kind=start');
    const pre = document.getElementById('log-pre');
    if (!pre) return;
    const lines = data.log.split('\n');
    const filtered = logFilter ? lines.filter((l) => l.toLowerCase().includes(logFilter.toLowerCase())) : lines;
    pre.textContent = filtered.join('\n');
    if (autoScroll) pre.scrollTop = pre.scrollHeight;
  } catch (e) { /* transient */ }
}

function startLogPolling() {
  clearInterval(logTimer);
  if (logService) {
    pollLog();
    logTimer = setInterval(pollLog, 2000);
  }
}

function logPanel() {
  const { el, emptyState } = ctx;
  if (!logService) return emptyState('No service selected', 'Click a service on the left to tail its log.');
  return el('div', {},
    el('div', { style: 'display:flex;gap:6px;margin-bottom:6px' },
      el('input', { placeholder: 'Filter...', value: logFilter, oninput: (e) => { logFilter = e.target.value; pollLog(); } }),
      el('label', { style: 'font-size:12px;display:flex;align-items:center;gap:4px;white-space:nowrap' },
        el('input', { type: 'checkbox', checked: autoScroll, onchange: (e) => { autoScroll = e.target.checked; } }),
        'Auto-scroll')),
    el('div', { class: 'log-drawer' }, el('pre', { id: 'log-pre' }, '')));
}

function rightColumn() {
  const { el, emptyState } = ctx;
  if (!fastState) return el('div', { class: 'card' }, emptyState('Loading services...'));
  return el('div', { class: 'eyeball-right' },
    el('div', { class: 'card' },
      el('h3', {}, 'Services'),
      fastState.services.length ? fastState.services.map(serviceRow) : emptyState('No services configured'),
      el('div', { style: 'margin-top:10px;font-size:12px;color:var(--muted)' }, 'Checkout: ',
        el('code', {}, (fastState.checkout.branch || 'none') + (fastState.checkout.sha ? ' @ ' + fastState.checkout.sha : ''))),
      el('div', { style: 'margin-top:6px' }, 'Latest OTP: ', el('code', {}, fastState.otp || '-'))),
    el('div', { class: 'card' }, el('h3', {}, 'Log' + (logService ? ': ' + logService : '')), logPanel()));
}

// --- checklist -----------------------------------------------------------

function checkCard(check) {
  const { el } = ctx;
  const account = check.as ? accounts[check.as] : null;
  return el('div', { class: 'card' },
    el('div', { style: 'display:flex;justify-content:space-between' }, el('h3', {}, check.title), el('span', {}, check.id)),
    account ? el('div', { style: 'font-size:12px;color:var(--muted);display:flex;gap:6px;align-items:center' },
      'Account: ', el('code', {}, account.email || account.phone || check.as),
      account.password ? ' / ' + account.password : (account.pin ? ' / PIN ' + account.pin : ''),
      el('button', {
        onclick: () => { navigator.clipboard?.writeText(account.email || account.phone || ''); ctx.toast('Copied', 'success'); },
      }, 'Copy')) : null,
    check.url ? el('div', {}, el('a', { href: check.url, target: '_blank', rel: 'noopener' }, el('button', {}, 'Open URL'))) : null,
    el('ol', { class: 'steps' }, check.steps.map((s) => el('li', {}, s))),
    el('div', {}, el('strong', {}, 'Expected: '), check.expect),
    el('div', { class: 'toggle-group', style: 'margin:8px 0' },
      el('button', { class: 'pass' + (check.result === 'pass' ? ' active' : ''), onclick: () => setCheckResult(check.id, 'pass') }, 'Pass'),
      el('button', { class: 'fail' + (check.result === 'fail' ? ' active' : ''), onclick: () => setCheckResult(check.id, 'fail') }, 'Fail')),
    el('textarea', { class: 'note', placeholder: 'Note (optional)', value: check.note || '', oninput: (e) => setCheckNote(check.id, e.target.value) }),
    check.issue_url ? el('div', {}, el('a', { href: check.issue_url, target: '_blank', rel: 'noopener' }, 'Filed issue')) : null);
}

function observationsCard() {
  const { el } = ctx;
  const data = ensureResultsData();
  return el('div', { class: 'card' },
    el('h3', {}, 'Observations'),
    data.observations.map((obs) => el('div', { style: 'display:flex;gap:8px;margin-bottom:8px' },
      el('select', { onchange: (e) => { obs.kind = e.target.value; saveResults(); } },
        el('option', { value: 'bug', selected: obs.kind === 'bug' }, 'Bug'),
        el('option', { value: 'improvement', selected: obs.kind === 'improvement' }, 'Improvement')),
      el('textarea', { style: 'flex:1', value: obs.text, placeholder: 'What did you notice?',
        oninput: (e) => { obs.text = e.target.value; saveResults(); } }),
      obs.issue_url ? el('a', { href: obs.issue_url, target: '_blank', rel: 'noopener' }, 'issue') : null)),
    el('button', { onclick: addObservation }, 'Add observation'));
}

async function submit() {
  if (!selectedId) return;
  try {
    const data = await apiPost('/api/eyeball/submit', { candidate: selectedId });
    resultsData = data.data;
    ctx.toast('Submitted', 'success');
    renderAll();
  } catch (e) {
    ctx.toast('Submit failed: ' + e.message, 'error');
  }
}

function checklistSection(candidate) {
  const { el, emptyState } = ctx;
  const vm = buildChecklistViewModel(candidate, resultsData);
  const s = stepState(candidate);
  const gated = !(s.checkedOut && s.allUp);
  return el('div', {},
    gated ? el('div', { class: 'empty-state', style: 'margin-bottom:12px' },
      'Check out and start services first (see the stepper above) - the checklist below still works, it just is not backed by a running environment yet.') : null,
    vm.checks.length
      ? vm.checks.map(checkCard)
      : emptyState('No checks in this candidate', candidate.parse_error || 'Its handoff has no Eyeball block.'),
    observationsCard(),
    el('button', { class: 'primary', onclick: submit }, vm.submitted ? 'Re-submit' : 'Submit'));
}

// --- candidate list (left column) ------------------------------------------

function candidateRow(c) {
  const { el } = ctx;
  const vm = buildChecklistViewModel(c, c.results);
  const stage = c.stage;
  return el('div', {
    class: 'candidate-row' + (c.id === selectedId ? ' selected' : ''),
    onclick: () => selectCandidate(c.id),
  },
    el('div', { class: 'cr-top' },
      c.number ? el('span', { class: 'cr-number' }, '#' + c.number) : null,
      el('span', { class: 'chip' }, c.story),
      stage ? el('span', { class: 'chip ' + stageChipClass(stage) }, stageLabel(stage)) : null),
    el('div', { class: 'cr-title' }, c.title),
    el('div', { class: 'cr-progress' },
      el('div', { class: 'progress' }, el('div', { style: 'width:' + (vm.total ? Math.round(100 * vm.done / vm.total) : 0) + '%' })),
      el('span', {}, vm.done + ' of ' + vm.total)));
}

// --- top-level render -------------------------------------------------

function renderAll() {
  const { el } = ctx;
  try {
    root.innerHTML = '';
    root.append(el('div', { class: 'section-title' }, el('h2', {}, 'Eyeball'),
      el('span', { class: 'stale' }, 'candidates ' + timeAgo(candidatesFetchedAt / 1000)),
      el('button', { onclick: () => loadCandidates(true) }, 'Refresh')));

    const left = el('div', { class: 'eyeball-left' }, candidates.map(candidateRow));
    const center = el('div', { class: 'eyeball-center' });
    const current = selected();
    if (current) {
      center.append(stepperRow(current));
      center.append(el('h3', {}, 'Checklist'));
      center.append(checklistSection(current));
    } else {
      center.append(ctx.emptyState('Select a candidate', 'Pick a PR (or the smoke checklist) on the left.'));
    }

    root.append(el('div', { class: 'eyeball-layout' }, left, center, rightColumn()));
  } catch (e) {
    // A rendering bug must be visible and diagnosable, never a silently missing section.
    // eslint-disable-next-line no-console
    console.error('eyeball render failed', e);
    root.append(ctx.emptyState('Something went wrong rendering this section', String(e && e.message || e)));
  }
}

export const eyeballSection = {
  async mount(rootEl, context) {
    root = rootEl; ctx = context;
    pendingParam = context.param || null;
    root.append(ctx.el('div', {}, 'Loading...'));
    try {
      fastState = await apiGet('/api/state');
    } catch (e) { /* covered by global banner */ }
    await loadCandidates(false);
    candidatesTimer = setInterval(() => loadCandidates(false), 60000);
  },
  unmount() {
    clearInterval(candidatesTimer);
    clearInterval(logTimer);
  },
  onFastState(data) {
    fastState = data;
    if (root) renderAll();
  },
};
