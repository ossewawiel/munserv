import { apiGet, apiPost, timeAgo } from '../api.js';

let root, ctx;
let candidates = [];
let selectedId = null;
let resultsData = null;
let fastState = null;
let accounts = {};
let candidatesFetchedAt = 0;
let candidatesTimer = null;
let openLog = null; // {name, kind}
let logTimer = null;
let stepRunning = false;

function selected() {
  return candidates.find((c) => c.id === selectedId) || null;
}

function requiredServices(candidate) {
  const set = new Set();
  for (const c of candidate.checks || []) for (const s of c.services || []) set.add(s);
  return [...set];
}

async function loadCandidates(force) {
  try {
    const data = await apiGet('/api/eyeball/candidates' + (force ? '?refresh=1' : ''));
    candidates = data.candidates;
    accounts = data.accounts || {};
    candidatesFetchedAt = Date.now();
    if (selectedId) {
      const found = candidates.find((c) => c.id === selectedId);
      resultsData = found ? found.results : null;
    }
    renderAll();
  } catch (e) {
    ctx.toast('Could not load candidates: ' + e.message, 'error');
  }
}

function selectCandidate(id) {
  selectedId = id;
  const c = selected();
  resultsData = c ? c.results : null;
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

function setCheckResult(checkId, result) {
  resultsData.checks[checkId] = resultsData.checks[checkId] || { result: null, note: '', issue_url: null };
  resultsData.checks[checkId].result = resultsData.checks[checkId].result === result ? null : result;
  saveResults();
  renderAll();
}

function setCheckNote(checkId, note) {
  resultsData.checks[checkId] = resultsData.checks[checkId] || { result: null, note: '', issue_url: null };
  resultsData.checks[checkId].note = note;
  saveResults();
}

function addObservation() {
  resultsData.observations.push({ kind: 'bug', text: '', issue_url: null });
  saveResults();
  renderAll();
}

// --- stepper -----------------------------------------------------------

function stepState(candidate) {
  const checkedOut = candidate.kind === 'smoke' || (fastState && fastState.checkout.branch === candidate.branch);
  const needed = requiredServices(candidate);
  const rows = fastState ? fastState.services.filter((s) => needed.includes(s.name)) : [];
  const needsPrepare = rows.some((r) => r.needs_prepare);
  const prepared = !needsPrepare;
  const allUp = rows.length > 0 && rows.every((r) => r.up || r.manual);
  const total = candidate.checks.length;
  const done = candidate.checks.filter((c) => resultsData && resultsData.checks[c.id] && resultsData.checks[c.id].result).length;
  const tested = total > 0 && done === total;
  const submitted = !!(resultsData && resultsData.submitted_at);
  return { checkedOut, prepared, needsPrepare, allUp, tested, submitted, needed, rows, done, total };
}

async function runStepperSequence(candidate) {
  if (stepRunning) return;
  stepRunning = true;
  renderAll();
  try {
    if (candidate.kind === 'pr') {
      ctx.toast('Checking out ' + candidate.branch + '...');
      await apiPost('/api/checkout', { branch: candidate.branch });
    }
    const needed = requiredServices(candidate);
    for (const name of needed) {
      const svc = (fastState.services || []).find((s) => s.name === name);
      if (svc && svc.needs_prepare) {
        ctx.toast('Preparing ' + name + '...');
        await apiPost('/api/prepare', { name });
      }
    }
    ctx.toast('Starting services...');
    await apiPost('/api/service/start-required', { names: needed });
    ctx.toast('Started. Watch the services panel for green.', 'success');
  } catch (e) {
    ctx.toast('Could not run the sequence: ' + e.message, 'error');
  } finally {
    stepRunning = false;
    renderAll();
  }
}

function stepperCard(candidate) {
  const { el } = ctx;
  const s = stepState(candidate);
  const step = (n, title, done, body) => el('div', { class: 'step' + (done ? ' done' : '') },
    el('div', { class: 'step-head' },
      el('div', { class: 'step-num' }, done ? '✓' : n),
      el('div', { class: 'step-title' }, title),
      el('div', { class: 'step-state' }, done ? 'done' : '')),
    body ? el('div', { class: 'step-body' }, body) : null);
  return el('div', { class: 'stepper' },
    el('button', { class: 'primary', disabled: stepRunning, onclick: () => runStepperSequence(candidate) },
      stepRunning ? 'Running...' : 'Start testing this candidate'),
    step(1, 'Check out', s.checkedOut),
    step(2, 'Prepare', s.prepared, s.needsPrepare ? 'Some services need dependencies installed.' : null),
    step(3, 'Start services', s.allUp, s.needed.length
      ? s.rows.map((r) => el('span', { class: 'chip ' + (r.up || r.manual ? 'good' : 'bad') }, r.name))
      : 'This candidate lists no services.'),
    step(4, 'Test', s.tested, s.total ? (s.done + ' of ' + s.total + ' checks ticked') : 'No checks in this candidate.'),
    step(5, 'Submit', s.submitted));
}

// --- services panel ------------------------------------------------------

function serviceRow(row) {
  const { el } = ctx;
  const dotClass = row.manual ? 'manual' : row.up ? 'up' : 'down';
  const isOpen = openLog && openLog.name === row.name;
  return el('div', {},
    el('div', { class: 'service-row' },
      el('span', { class: 'dot ' + dotClass }),
      el('span', { class: 'name' }, row.name),
      row.exit_code != null && !row.up
        ? el('span', { class: 'remedy' }, 'exited ' + row.exit_code + (row.last_log_line ? ': ' + row.last_log_line : '') + ' - ' + row.remedy)
        : null,
      row.needs_prepare ? el('button', { onclick: () => apiPost('/api/prepare', { name: row.name }).catch((e) => ctx.toast(e.message, 'error')) }, 'Prepare') : null,
      !row.manual ? el('button', { onclick: () => apiPost('/api/service/start', { name: row.name }).catch((e) => ctx.toast(e.message, 'error')) }, 'Start') : null,
      !row.manual ? el('button', { onclick: () => apiPost('/api/service/stop', { name: row.name }).catch((e) => ctx.toast(e.message, 'error')) }, 'Stop') : null,
      el('button', { onclick: () => { openLog = isOpen ? null : { name: row.name, kind: 'start' }; renderAll(); startLogPolling(); } }, isOpen ? 'Hide log' : 'Log')),
    isOpen ? el('div', { class: 'log-drawer', id: 'log-drawer' }, el('pre', { id: 'log-pre' }, '')) : null);
}

async function pollLog() {
  if (!openLog) return;
  try {
    const data = await apiGet('/api/log?name=' + encodeURIComponent(openLog.name) + '&kind=' + openLog.kind);
    const pre = document.getElementById('log-pre');
    if (pre) { pre.textContent = data.log; pre.scrollTop = pre.scrollHeight; }
  } catch (e) { /* transient */ }
}

function startLogPolling() {
  clearInterval(logTimer);
  if (openLog) {
    pollLog();
    logTimer = setInterval(pollLog, 2000);
  }
}

function servicesPanel() {
  const { el, emptyState } = ctx;
  if (!fastState) return emptyState('Loading services...');
  return el('div', { class: 'card' },
    el('h3', {}, 'Services'),
    fastState.services.length ? fastState.services.map(serviceRow) : emptyState('No services configured'),
    el('div', { style: 'margin-top:10px;font-size:12px;color:var(--muted)' }, 'Checkout: ',
      el('code', {}, (fastState.checkout.branch || 'none') + (fastState.checkout.sha ? ' @ ' + fastState.checkout.sha : ''))),
    el('div', { style: 'margin-top:6px' }, 'Latest OTP: ', el('code', {}, fastState.otp || '-')));
}

// --- checklist -----------------------------------------------------------

function checkCard(candidate, check) {
  const { el } = ctx;
  const r = resultsData.checks[check.id] || { result: null, note: '' };
  const account = accounts[check.as];
  return el('div', { class: 'card' },
    el('div', { style: 'display:flex;justify-content:space-between' }, el('h3', {}, check.title), el('span', {}, check.id)),
    account ? el('div', { style: 'font-size:12px;color:var(--muted)' },
      'Account: ', el('code', {}, account.email || account.phone || check.as), account.password ? ' / ' + account.password : (account.pin ? ' / PIN ' + account.pin : '')) : null,
    check.url ? el('div', {}, el('a', { href: check.url, target: '_blank', rel: 'noopener' }, check.url)) : null,
    el('ol', { class: 'steps' }, (check.steps || []).map((s) => el('li', {}, s))),
    el('div', {}, el('strong', {}, 'Expected: '), check.expect),
    el('div', { class: 'toggle-group', style: 'margin:8px 0' },
      el('button', { class: 'pass' + (r.result === 'pass' ? ' active' : ''), onclick: () => setCheckResult(check.id, 'pass') }, 'Pass'),
      el('button', { class: 'fail' + (r.result === 'fail' ? ' active' : ''), onclick: () => setCheckResult(check.id, 'fail') }, 'Fail')),
    el('textarea', { class: 'note', placeholder: 'Note (optional)', value: r.note || '', oninput: (e) => setCheckNote(check.id, e.target.value) }),
    r.issue_url ? el('div', {}, el('a', { href: r.issue_url, target: '_blank', rel: 'noopener' }, 'Filed issue')) : null);
}

function observationsCard() {
  const { el } = ctx;
  return el('div', { class: 'card' },
    el('h3', {}, 'Observations'),
    resultsData.observations.map((obs, idx) => el('div', { class: 'obs-row', style: 'display:flex;gap:8px;margin-bottom:8px' },
      el('select', {
        onchange: (e) => { obs.kind = e.target.value; saveResults(); },
      },
        el('option', { value: 'bug', selected: obs.kind === 'bug' }, 'Bug'),
        el('option', { value: 'improvement', selected: obs.kind === 'improvement' }, 'Improvement')),
      el('textarea', {
        style: 'flex:1', value: obs.text, placeholder: 'What did you notice?',
        oninput: (e) => { obs.text = e.target.value; saveResults(); },
      }),
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
  const s = stepState(candidate);
  const gated = !(s.checkedOut && s.allUp);
  const body = el('div', { class: gated ? 'checklist-inner' : '' },
    candidate.checks.length
      ? candidate.checks.map((c) => checkCard(candidate, c))
      : emptyState('No checks in this candidate', candidate.parse_error || 'Its handoff has no Eyeball block.'),
    observationsCard(),
    el('button', { class: 'primary', onclick: submit }, 'Submit'));
  return el('div', {},
    gated ? el('div', { class: 'empty-state' }, 'Check out and start services first (see the stepper above).') : null,
    body);
}

// --- candidate list --------------------------------------------------------

function candidateRow(c) {
  const { el } = ctx;
  const badge = c.eyeball_label === 'eyeball:pass' ? el('span', { class: 'chip good' }, 'pass')
    : c.eyeball_label === 'eyeball:fail' ? el('span', { class: 'chip bad' }, 'fail') : null;
  const results = c.results || { checks: {} };
  const done = c.checks.filter((chk) => results.checks[chk.id] && results.checks[chk.id].result).length;
  return el('div', {
    class: 'card', style: 'cursor:pointer;border-color:' + (c.id === selectedId ? 'var(--accent)' : 'var(--border)'),
    onclick: () => selectCandidate(c.id),
  },
    el('div', { style: 'font-weight:600' }, c.title),
    el('div', { style: 'font-size:12px;color:var(--muted);display:flex;gap:6px;align-items:center' },
      c.story, badge, el('span', {}, done + ' of ' + c.checks.length)));
}

function renderAll() {
  const { el } = ctx;
  root.innerHTML = '';
  root.append(el('div', { class: 'section-title' }, el('h2', {}, 'Eyeball'),
    el('span', { class: 'stale' }, 'candidates ' + timeAgo(candidatesFetchedAt / 1000)),
    el('button', { onclick: () => loadCandidates(true) }, 'Refresh')));

  root.append(el('div', { class: 'grid cols-2' },
    el('div', {}, el('h3', {}, 'Candidates'), candidates.map(candidateRow)),
    el('div', {}, selected() ? [stepperCard(selected()), servicesPanel()] : servicesPanel())));

  if (selected() && resultsData) {
    root.append(el('h3', {}, 'Checklist'));
    root.append(checklistSection(selected()));
  }
}

export const eyeballSection = {
  async mount(rootEl, context) {
    root = rootEl; ctx = context;
    root.append(ctx.el('div', {}, 'Loading...'));
    try {
      const state = await apiGet('/api/state');
      fastState = state;
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
