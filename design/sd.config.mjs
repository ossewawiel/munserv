// Style Dictionary build: design/tokens/*.tokens.json -> platform theme constants.
// Run from design/: `pnpm build`. CI runs `pnpm check` and fails on drift.
import StyleDictionary from 'style-dictionary';

const HEADER = 'GENERATED from design/tokens by design/sd.config.mjs. Do not edit; change the tokens and run `pnpm --dir design build`.';

const isColor = (t) => t.$type === 'color' || t.type === 'color';
const isDimension = (t) => t.$type === 'dimension' || t.type === 'dimension';
const value = (t) => (t.$value !== undefined ? t.$value : t.value);
const num = (t) => {
  const v = value(t);
  return typeof v === 'object' ? v.value : v;
};
const camel = (parts) => parts.map((p, i) => (i === 0 ? p : p[0].toUpperCase() + p.slice(1))).join('');
const pascal = (s) => s[0].toUpperCase() + s.slice(1);
// Dart identifiers cannot carry the wire value's underscore: in_progress -> inProgress.
const dartIdent = (n) => n.split('_').map((p, i) => (i === 0 ? p : pascal(p))).join('');

// Group tokens by their first path segment (and second for `scheme` / `semantic`).
function groups(tokens) {
  const out = new Map();
  for (const t of tokens) {
    const p = t.path;
    const key = p[0] === 'scheme' || p[0] === 'semantic' ? `${p[0]}.${p[1]}` : p[0];
    const rest = p[0] === 'scheme' || p[0] === 'semantic' ? p.slice(2) : p.slice(1);
    if (!out.has(key)) out.set(key, []);
    out.get(key).push({ name: camel(rest), token: t });
  }
  return out;
}

StyleDictionary.registerFormat({
  name: 'typescript/munserv',
  format: ({ dictionary }) => {
    let s = `// ${HEADER}\n\n`;
    for (const [key, items] of groups(dictionary.allTokens)) {
      const name = camel(key.split('.'));
      s += `export const ${name} = {\n`;
      for (const { name: n, token } of items) {
        const v = isColor(token) ? `'${value(token)}'` : num(token);
        const d = token.$description ? ` // ${token.$description}` : '';
        s += `  ${n}: ${v},${d}\n`;
      }
      s += `} as const;\n\n`;
    }
    return s;
  },
});

StyleDictionary.registerFormat({
  name: 'dart/munserv',
  format: ({ dictionary }) => {
    let s = `// ${HEADER}\n// ignore_for_file: constant_identifier_names\n\nimport 'package:flutter/material.dart';\n\n`;
    for (const [key, items] of groups(dictionary.allTokens)) {
      const cls = 'Tokens' + key.split('.').map(pascal).join('');
      s += `abstract class ${cls} {\n`;
      for (const { name: raw, token } of items) {
        const n = dartIdent(raw);
        if (isColor(token)) {
          s += `  static const Color ${n} = Color(0xFF${value(token).slice(1).toUpperCase()});\n`;
        } else if (isDimension(token)) {
          s += `  static const double ${n} = ${Number(num(token)).toFixed(1).replace(/\.0$/, '')};\n`;
        }
      }
      s += `}\n\n`;
    }
    return s.trimEnd() + '\n';
  },
});

const sd = new StyleDictionary({
  source: ['tokens/*.tokens.json'],
  platforms: {
    web: {
      buildPath: '../web/src/theme/generated/',
      files: [{ destination: 'tokens.ts', format: 'typescript/munserv' }],
    },
    mobile: {
      buildPath: '../mobile/lib/shared/theme/generated/',
      files: [{ destination: 'tokens.dart', format: 'dart/munserv' }],
    },
  },
});

await sd.buildAllPlatforms();
