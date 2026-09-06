import test from 'node:test';
import assert from 'node:assert/strict';
import {
  requiredServices, buildChecklistViewModel, stageLabel, stageChipClass,
  checkoutMismatch, checkoutButtonLabel, stepButtonGate, isCheckedOut,
} from './eyeball.model.mjs';

const FIXTURE_CANDIDATE = {
  id: 'pr-100', kind: 'pr', story: 'B10',
  checks: [
    { id: 'E1', title: 'New administrator gets a welcome message', as: 'pod_chief',
      services: ['db', 'backend', 'web'], url: 'http://localhost:3000/pod-administrators',
      steps: ['Click "Add administrator".', 'Log in as the new administrator.'],
      expect: 'One unread welcome message.' },
    { id: 'E2', title: 'Failed creation sends nothing', as: 'pod_chief',
      services: ['db', 'backend', 'web'], url: 'http://localhost:3000/pod-administrators',
      steps: ['Submit a duplicate email.'], expect: 'No new message appears.' },
    { id: 'E3', title: 'Mobile still renders every message type', as: 'member',
      services: ['db', 'backend', 'mobile'], url: 'Messages screen',
      steps: ['Open Messages.'], expect: 'The list loads without error.' },
  ],
};

test('requiredServices unions services across every check', () => {
  assert.deepEqual(requiredServices(FIXTURE_CANDIDATE), ['db', 'backend', 'web', 'mobile']);
});

test('requiredServices returns empty for a candidate with no checks', () => {
  assert.deepEqual(requiredServices({ checks: [] }), []);
});

test('buildChecklistViewModel renders every check even with no results yet', () => {
  const vm = buildChecklistViewModel(FIXTURE_CANDIDATE, { candidate: 'pr-100', checks: {}, observations: [] });
  assert.equal(vm.checks.length, 3);
  assert.equal(vm.total, 3);
  assert.equal(vm.done, 0);
  assert.equal(vm.checks[0].id, 'E1');
  assert.equal(vm.checks[0].result, null);
  assert.equal(vm.submitted, false);
});

test('buildChecklistViewModel never drops checks when resultsData is null', () => {
  // This is the exact shape that made the checklist vanish entirely: a candidate is selected
  // (so its checks are known) but resultsData has not arrived/synced yet.
  const vm = buildChecklistViewModel(FIXTURE_CANDIDATE, null);
  assert.equal(vm.checks.length, 3);
  assert.equal(vm.total, 3);
});

test('buildChecklistViewModel never drops checks when resultsData is undefined', () => {
  const vm = buildChecklistViewModel(FIXTURE_CANDIDATE, undefined);
  assert.equal(vm.checks.length, 3);
});

test('buildChecklistViewModel reflects a ticked result and a note', () => {
  const results = { candidate: 'pr-100', checks: { E1: { result: 'pass', note: 'worked', issue_url: null } }, observations: [] };
  const vm = buildChecklistViewModel(FIXTURE_CANDIDATE, results);
  assert.equal(vm.checks[0].result, 'pass');
  assert.equal(vm.checks[0].note, 'worked');
  assert.equal(vm.done, 1);
});

test('buildChecklistViewModel carries observations through', () => {
  const results = { candidate: 'pr-100', checks: {}, observations: [{ kind: 'bug', text: 'x', issue_url: null }] };
  const vm = buildChecklistViewModel(FIXTURE_CANDIDATE, results);
  assert.equal(vm.observations.length, 1);
  assert.equal(vm.observations[0].kind, 'bug');
});

test('buildChecklistViewModel reports submitted from submitted_at', () => {
  const results = { candidate: 'pr-100', checks: {}, observations: [], submitted_at: '2026-01-01T00:00:00Z' };
  const vm = buildChecklistViewModel(FIXTURE_CANDIDATE, results);
  assert.equal(vm.submitted, true);
});

test('stageLabel and stageChipClass cover every known stage', () => {
  assert.equal(stageLabel('ready_to_merge'), 'Ready to merge');
  assert.equal(stageChipClass('ready_to_merge'), 'good');
  assert.equal(stageLabel('awaiting_eyeball'), 'Awaiting eyeball');
  assert.equal(stageLabel(null), null);
});

// --- per-step stepper buttons ------------------------------------------

const PR_CANDIDATE = { id: 'pr-100', kind: 'pr', branch: 'feat/console-testing' };
const SMOKE_CANDIDATE = { id: 'smoke', kind: 'smoke', branch: 'master' };

test('isCheckedOut is false when the checkout folder is not a worktree, even with an empty branch', () => {
  // The exact shape reported by a fresh /api/state before anything has ever been checked out:
  // the folder does not exist yet, so is_worktree is false and branch is ''. This must never
  // read as "checked out" for the smoke candidate just because its branch defaults to master.
  assert.equal(isCheckedOut(SMOKE_CANDIDATE, { branch: '', is_worktree: false }), false);
  assert.equal(isCheckedOut(PR_CANDIDATE, { branch: '', is_worktree: false }), false);
});

test('isCheckedOut is false when the checkout is a worktree but on a different branch', () => {
  assert.equal(isCheckedOut(PR_CANDIDATE, { branch: 'master', is_worktree: true }), false);
  assert.equal(isCheckedOut(SMOKE_CANDIDATE, { branch: 'feat/console-testing', is_worktree: true }), false);
});

test('isCheckedOut is true only when the checkout is a worktree on the candidate\'s own branch', () => {
  assert.equal(isCheckedOut(PR_CANDIDATE, { branch: 'feat/console-testing', is_worktree: true }), true);
  assert.equal(isCheckedOut(SMOKE_CANDIDATE, { branch: 'master', is_worktree: true }), true);
});

test('isCheckedOut never treats a kind of "smoke" as a free pass', () => {
  // Regression for the bug where the stepper showed "Check out - done" for the smoke candidate
  // purely because of candidate.kind, regardless of what was actually on disk.
  assert.equal(isCheckedOut(SMOKE_CANDIDATE, null), false);
  assert.equal(isCheckedOut(SMOKE_CANDIDATE, undefined), false);
});

test('checkoutMismatch reports the actual branch when it differs from the candidate\'s', () => {
  assert.equal(checkoutMismatch(PR_CANDIDATE, { branch: 'feat/other-thing' }), 'feat/other-thing');
});

test('checkoutMismatch is null when branches match or nothing is checked out yet', () => {
  assert.equal(checkoutMismatch(PR_CANDIDATE, { branch: 'feat/console-testing' }), null);
  assert.equal(checkoutMismatch(PR_CANDIDATE, { branch: '' }), null);
  assert.equal(checkoutMismatch(PR_CANDIDATE, null), null);
});

test('checkoutButtonLabel switches wording when the checkout is on another branch', () => {
  assert.equal(checkoutButtonLabel(null), 'Check out');
  assert.equal(checkoutButtonLabel('feat/other-thing'), 'Switch to this branch');
});

test('stepButtonGate disables Prepare and Start until checked out, with an explanatory reason', () => {
  const notCheckedOut = stepButtonGate('prepare', { checkedOut: false });
  assert.equal(notCheckedOut.disabled, true);
  assert.match(notCheckedOut.reason, /check out/i);

  const checkedOut = stepButtonGate('start', { checkedOut: true });
  assert.equal(checkedOut.disabled, false);
  assert.equal(checkedOut.reason, null);
});

test('stepButtonGate never gates the Check out step itself', () => {
  const gate = stepButtonGate('checkout', { checkedOut: false });
  assert.equal(gate.disabled, false);
  assert.equal(gate.reason, null);
});
