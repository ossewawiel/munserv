import test from 'node:test';
import assert from 'node:assert/strict';
import { requiredServices, buildChecklistViewModel, stageLabel, stageChipClass } from './eyeball.model.mjs';

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
