import { apiGet, ApiFailure, timeAgo } from './api.js';
import { overviewSection } from './sections/overview.js';
import { knowledgeSection } from './sections/knowledge.js';
import { designSection } from './sections/design.js';
import { eyeballSection } from './sections/eyeball.js';
import { releaseSection } from './sections/release.js';

export function el(tag, attrs, ...children) {
  const e = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (k === 'class') e.className = v;
    else if (k === 'html') e.innerHTML = v;
    else if (k === 'value') e.value = v;
    else if (k.startsWith('on')) e.addEventListener(k.slice(2), v);
    else if (v !== null && v !== undefined && v !== false) e.setAttribute(k, v === true ? '' : v);
  }
  for (const c of children.flat(Infinity)) {
    if (c === null || c === undefined || c === false) continue;
    e.append(c.nodeType ? c : document.createTextNode(String(c)));
  }
  return e;
}

export function toast(message, kind) {
  const stack = document.getElementById('toast-stack');
  const t = el('div', { class: 'toast' + (kind ? ' ' + kind : '') }, message);
  stack.append(t);
  setTimeout(() => t.remove(), 4000);
}

export function emptyState(title, hint) {
  return el('div', { class: 'empty-state' }, el('div', {}, title), hint ? el('div', { class: 'hint' }, hint) : null);
}

const SECTIONS = {
  overview: overviewSection,
  knowledge: knowledgeSection,
  design: designSection,
  eyeball: eyeballSection,
  release: releaseSection,
};

const main = document.getElementById('main');
const banner = document.getElementById('banner');
const navLinks = [...document.querySelectorAll('#nav a')];
const updatedEl = document.getElementById('updated');
const checkoutChip = document.getElementById('checkout-chip');
const projectNameEl = document.getElementById('project-name');

let currentSection = null;
let currentController = null;
let lastFastFetch = 0;
let bannerFailures = 0;

function setBanner(message) {
  if (message) {
    banner.textContent = message;
    banner.hidden = false;
  } else {
    banner.hidden = true;
  }
}

function applySectionVisibility(sectionsEnabled) {
  for (const link of navLinks) {
    const id = link.dataset.section;
    link.hidden = sectionsEnabled && sectionsEnabled[id] === false;
  }
}

async function pollFastState() {
  try {
    const data = await apiGet('/api/state');
    lastFastFetch = Date.now();
    bannerFailures = 0;
    setBanner(null);
    projectNameEl.textContent = data.project.name;
    // The project's brand colour marks the project name only: overriding --accent itself would
    // replace the theme's contrast-checked interactive colour (links, primary buttons) with an
    // arbitrary brand colour that may not read well against a dark background.
    projectNameEl.style.borderLeft = '4px solid ' + data.project.accent;
    projectNameEl.style.paddingLeft = '8px';
    const branch = data.checkout.branch || 'master';
    const sha = data.checkout.sha ? ' @ ' + data.checkout.sha : '';
    checkoutChip.textContent = branch + sha;
    applySectionVisibility(data.project.sections);
    if (currentController && currentController.onFastState) currentController.onFastState(data);
    updatedEl.textContent = 'updated just now';
  } catch (e) {
    bannerFailures += 1;
    if (bannerFailures >= 2) {
      setBanner('Lost contact with the console server: ' + (e instanceof ApiFailure ? e.message : e));
    }
  }
}

setInterval(() => {
  if (lastFastFetch) updatedEl.textContent = 'updated ' + timeAgo(lastFastFetch / 1000);
}, 1000);

function initTheme() {
  const stored = localStorage.getItem('console-theme');
  if (stored) document.documentElement.setAttribute('data-theme', stored);
  document.getElementById('theme-toggle').addEventListener('click', () => {
    const current = document.documentElement.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : current === 'light' ? null : 'dark';
    if (next) {
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('console-theme', next);
    } else {
      document.documentElement.removeAttribute('data-theme');
      localStorage.removeItem('console-theme');
    }
  });
}

async function route() {
  const hash = location.hash.replace(/^#\//, '') || 'overview';
  const sectionId = SECTIONS[hash] ? hash : 'overview';
  for (const link of navLinks) link.classList.toggle('active', link.dataset.section === sectionId);
  if (currentController && currentController.unmount) currentController.unmount();
  currentSection = sectionId;
  main.innerHTML = '';
  const controller = SECTIONS[sectionId];
  currentController = controller;
  await controller.mount(main, { toast, el, emptyState });
}

window.addEventListener('hashchange', route);

initTheme();
route();
pollFastState();
setInterval(pollFastState, 3000);
