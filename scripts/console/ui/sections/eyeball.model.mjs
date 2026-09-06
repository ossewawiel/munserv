// Pure, DOM-independent view-model builders for the Eyeball section. Kept separate from
// eyeball.js so the checklist-rendering logic can be unit tested (scripts/test-console.py shells
// out to `node --test` on eyeball.model.test.mjs) without a browser or a DOM shim, and so the
// rendering code itself always has a safe, fully-shaped object to draw from -- a missing or
// null `resultsData` (the bug that made the checklist vanish entirely) can no longer skip
// rendering, only render checks with no answers ticked yet.

export function requiredServices(candidate) {
  const set = new Set();
  for (const c of candidate.checks || []) {
    for (const s of c.services || []) set.add(s);
  }
  return [...set];
}

export function buildChecklistViewModel(candidate, resultsData) {
  const safe = resultsData && typeof resultsData === 'object'
    ? { checks: resultsData.checks || {}, observations: resultsData.observations || [] }
    : { checks: {}, observations: [] };

  const checks = (candidate.checks || []).map((c) => {
    const r = safe.checks[c.id] || {};
    return {
      id: c.id,
      title: c.title,
      as: c.as || null,
      url: c.url || '',
      services: c.services || [],
      steps: c.steps || [],
      expect: c.expect || '',
      result: r.result || null,
      note: r.note || '',
      issue_url: r.issue_url || null,
    };
  });

  const observations = safe.observations.map((o) => ({
    kind: o.kind || 'bug',
    text: o.text || '',
    issue_url: o.issue_url || null,
  }));

  const done = checks.filter((c) => c.result === 'pass' || c.result === 'fail').length;
  return { checks, observations, done, total: checks.length, submitted: !!(resultsData && resultsData.submitted_at) };
}

const STAGE_LABELS = {
  in_progress: 'In progress',
  in_review: 'In review',
  awaiting_eyeball: 'Awaiting eyeball',
  ready_to_merge: 'Ready to merge',
};

const STAGE_CLASSES = {
  in_progress: '',
  in_review: 'warn',
  awaiting_eyeball: 'accent',
  ready_to_merge: 'good',
};

export function stageLabel(stage) {
  return STAGE_LABELS[stage] || null;
}

export function stageChipClass(stage) {
  return STAGE_CLASSES[stage] || '';
}

// --- per-step stepper buttons ----------------------------------------------
//
// Pulled out of eyeball.js so the gating and labelling rules (what disables a step button, what
// its title/tooltip says, what the "Check out" step is called when the checkout is already on a
// different branch) are unit-testable without a DOM.

// The branch the checkout is actually on, if it differs from the selected candidate's branch --
// null when they match or either is unknown. Used both for the "checkout is on <branch>" warning
// chip and to relabel the Check out button as a switch.
export function checkoutMismatch(candidate, checkout) {
  const checkoutBranch = checkout && checkout.branch;
  if (!checkoutBranch || !candidate || !candidate.branch) return null;
  if (checkoutBranch === candidate.branch) return null;
  return checkoutBranch;
}

export function checkoutButtonLabel(mismatchBranch) {
  return mismatchBranch ? 'Switch to this branch' : 'Check out';
}

// Whether the candidate's branch is actually checked out right now. Never inferred from the
// candidate's kind (a "smoke" candidate does not get a free pass just because it does not need a
// feature branch) or from an empty/default branch name -- the checkout directory must actually be
// a worktree, and its recorded branch must actually match. A missing checkout directory reports
// `is_worktree: false` and `branch: ''`, which must read as "not checked out", not as "checked out
// with no branch" or "checked out because this is the smoke candidate".
export function isCheckedOut(candidate, checkout) {
  return !!(candidate && checkout && checkout.is_worktree && checkout.branch === candidate.branch);
}

// Whether a step's own action button should be disabled right now, and why -- independent of
// "a run is already in progress", which the caller layers on top. Only Prepare and Start are
// gated on a prior step; Check out is always available.
export function stepButtonGate(key, stepState) {
  if (key === 'prepare' || key === 'start') {
    return stepState.checkedOut
      ? { disabled: false, reason: null }
      : { disabled: true, reason: 'Check out the candidate\'s branch first.' };
  }
  return { disabled: false, reason: null };
}
