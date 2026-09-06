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
