#!/usr/bin/env node
// Drives headless Chromium against a booted app to capture the UI-capture
// target list as still PNGs, at two viewports.
//
// Usage:
//   node capture.mjs --targets <path> --out <dir> --base-url <url>
//
// The targets file is the merged JSON described in
// .claude/skills/ticket-pipeline/references/developer.md (D2): a `ticket`
// id and a `targets` array. Each target carries `name`, `kind` ("still"),
// `path`, and optionally `signed_out: true`. A target may also carry
// `source: "core"` (set by run.sh when it merges in UiCapture::CoreTargets'
// output); anything else is treated as ticket-sourced.
//
// Writes `<out>/manifest.json` after every entry, so a budget timeout or a
// crash mid-run still leaves everything captured so far on disk: an array
// of { name, kind, viewport, source, file, bytes, status, attach } records
// (plus `error` on a tooling failure), including a synthetic
// "contact-sheet" record per viewport when one was built. `attach` says
// whether the Gatekeeper should send this file on its own: false for a
// core still folded into its viewport's contact sheet, true for the sheet
// itself, a ticket target, a core page that did not answer 200, or any
// entry that failed outright (as long as it produced a file at all).
//
// `status` is either the real numeric HTTP status or null; null (paired
// with a non-empty `error`) always means a tooling failure, never a page
// fault -- a page that failed to load a different way, or answered but
// bounced to the sign-in page unexpectedly, both come back this way rather
// than as a misleadingly clean 200.
//
// Exits 0 once every target has been attempted, even when individual pages
// answer with a non-200 status -- that is data for the manifest, not a
// script failure. Exits 1 only on an error that stopped the run itself
// (the browser would not launch, credentials could not be read).
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const REPO_ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const CHROMIUM_PATH = '/opt/pw-browsers/chromium';
const SIGN_IN_PATH = '/users/sign_in';

const VIEWPORTS = [
  { name: 'desktop', viewport: { width: 1440, height: 900 } },
  {
    name: 'mobile',
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 3,
    isMobile: true,
    hasTouch: true,
  },
];

const LOOPBACK_HOSTNAMES = new Set(['127.0.0.1', 'localhost', '::1']);

// --base-url always comes from boot.sh's own local, throwaway boot in the
// pipeline -- nothing enforces that for a direct invocation. This capture
// signs in with seeded demo credentials and delivers its output onward, so
// it must never be pointed at anything but a local test boot.
function assertLoopbackBaseUrl(baseUrl) {
  let hostname;
  try {
    hostname = new URL(baseUrl).hostname.replace(/^\[|\]$/g, '');
  } catch {
    throw new Error(`--base-url is not a valid URL: ${baseUrl}`);
  }
  if (!LOOPBACK_HOSTNAMES.has(hostname)) {
    throw new Error(
      `--base-url must be loopback (127.0.0.1, localhost, or ::1), got host '${hostname}' from '${baseUrl}'. ` +
      'This capture signs in with seeded demo credentials and its output is delivered onward, so it only ever runs against a local test boot.',
    );
  }
}

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i].startsWith('--')) {
      args[argv[i].slice(2)] = argv[i + 1];
      i += 1;
    }
  }
  for (const key of ['targets', 'out', 'base-url']) {
    if (!args[key]) throw new Error(`missing required --${key}`);
  }
  assertLoopbackBaseUrl(args['base-url']);
  return args;
}

function readTargets(targetsPath) {
  const raw = JSON.parse(fs.readFileSync(targetsPath, 'utf8'));
  return raw.targets || [];
}

function targetSource(target) {
  return target.source === 'core' ? 'core' : 'ticket';
}

// false for a core still that belongs in its viewport's contact sheet;
// true for anything worth its own upload (see the file header).
function computeAttach(entry) {
  if (!entry.file) return false;
  if (entry.error) return true;
  if (entry.kind === 'contact-sheet') return true;
  if (entry.source === 'ticket') return true;
  return entry.status !== 200;
}

function finalizeEntry(entry) {
  return { ...entry, attach: computeAttach(entry) };
}

function adminCredentials() {
  const script = 'puts [Demo::DraftSeeder::ADMIN_EMAIL, Demo::DraftSeeder::ADMIN_PASSWORD].join("|")';
  const output = execFileSync('bundle', ['exec', 'rails', 'runner', script], {
    cwd: REPO_ROOT,
    env: { ...process.env, RAILS_ENV: 'test' },
    encoding: 'utf8',
  });
  const line = output.trim().split('\n').pop();
  const [email, password] = line.split('|');
  return { email, password };
}

async function signIn(page, baseUrl, credentials) {
  await page.goto(new URL(SIGN_IN_PATH, baseUrl).toString());
  await page.fill('#user_email', credentials.email);
  await page.fill('#user_password', credentials.password);
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle' }),
    page.click('input[type="submit"]'),
  ]);
}

// A response can be a plain 200 because the browser was quietly bounced to
// the sign-in page instead of the page actually requested -- e.g. a
// sign-in that silently failed to establish a session. Catching this here
// keeps that failure out of the block-worthy "real 200" bucket.
function redirectedToSignIn(page, target) {
  if (target.path === SIGN_IN_PATH) return false;
  try {
    return new URL(page.url()).pathname === SIGN_IN_PATH;
  } catch {
    return false;
  }
}

async function captureStill(page, target, baseUrl, outDir, viewportName) {
  const filePath = path.join(outDir, viewportName, `${target.name}.png`);
  const base = { name: target.name, kind: 'still', viewport: viewportName, source: targetSource(target) };
  try {
    const response = await page.goto(new URL(target.path, baseUrl).toString(), { waitUntil: 'networkidle' });
    await page.screenshot({ path: filePath });
    const bytes = fs.statSync(filePath).size;
    if (redirectedToSignIn(page, target)) {
      return finalizeEntry({
        ...base, file: filePath, bytes, status: null,
        error: 'redirected to sign-in unexpectedly (session likely not established)',
      });
    }
    return finalizeEntry({ ...base, file: filePath, bytes, status: response ? response.status() : null });
  } catch (error) {
    return finalizeEntry({ ...base, file: null, bytes: 0, status: null, error: error.message });
  }
}

function skippedEntry(target, viewportName, reason) {
  return finalizeEntry({
    name: target.name, kind: 'still', viewport: viewportName, source: targetSource(target),
    file: null, bytes: 0, status: null, error: reason,
  });
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

async function buildContactSheet(browser, entries, outDir, viewportName) {
  const sheetEntries = entries.filter((e) => e.kind === 'still' && e.source === 'core' && e.status === 200);
  if (sheetEntries.length === 0) return null;

  // A core target's name comes from a Rails route name and is safe, but a
  // ticket target's name comes from the Capture plan -- agent-authored
  // text that reaches this file unvalidated -- so escape every value
  // regardless of its source, not just the ones known to need it today.
  const cells = sheetEntries
    .map((e) => `<figure><img src="file://${escapeHtml(e.file)}"><figcaption>${escapeHtml(e.name)} (${escapeHtml(e.status)})</figcaption></figure>`)
    .join('\n');
  const html = `<!doctype html><html><head><style>
    body { margin: 0; background: #fff; font: 12px sans-serif; }
    .grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; padding: 8px; }
    figure { margin: 0; border: 1px solid #ccc; }
    figure img { width: 100%; display: block; }
    figcaption { padding: 4px; word-break: break-all; }
  </style></head><body><div class="grid">${cells}</div></body></html>`;

  const htmlPath = path.join(outDir, viewportName, 'contact-sheet.html');
  fs.writeFileSync(htmlPath, html);

  // A plain desktop-sized viewport regardless of which viewport this sheet
  // is FOR -- inheriting the mobile viewport's deviceScaleFactor/isMobile
  // here would render a 4800x3600+ full-page image, the file most likely
  // to hit an upload size limit.
  const context = await browser.newContext({ viewport: { width: 1600, height: 1200 } });
  const page = await context.newPage();
  await page.goto(`file://${htmlPath}`);
  const filePath = path.join(outDir, viewportName, 'contact-sheet.png');
  await page.screenshot({ path: filePath, fullPage: true });
  await context.close();

  return finalizeEntry({
    name: `contact-sheet-${viewportName}`,
    kind: 'contact-sheet',
    viewport: viewportName,
    source: 'core',
    file: filePath,
    bytes: fs.statSync(filePath).size,
    status: 200,
  });
}

function writeManifest(outDir, manifest) {
  fs.writeFileSync(path.join(outDir, 'manifest.json'), JSON.stringify(manifest, null, 2));
}

async function captureViewport(browser, targets, baseUrl, credentials, outDir, viewportDef, manifest) {
  const { name: viewportName, ...viewportConfig } = viewportDef;
  fs.mkdirSync(path.join(outDir, viewportName), { recursive: true });

  const push = (entry) => {
    manifest.push(entry);
    writeManifest(outDir, manifest);
  };

  const signedOutTargets = targets.filter((t) => t.signed_out);
  const restTargets = targets.filter((t) => !t.signed_out);

  const context = await browser.newContext({ ...viewportConfig, baseURL: baseUrl });
  const page = await context.newPage();

  for (const target of signedOutTargets) push(await captureStill(page, target, baseUrl, outDir, viewportName));

  let signInError = null;
  if (restTargets.length > 0) {
    try {
      await signIn(page, baseUrl, credentials);
    } catch (error) {
      signInError = error;
    }
  }

  for (const target of restTargets) {
    if (signInError) {
      push(skippedEntry(target, viewportName, `sign-in failed: ${signInError.message}`));
    } else {
      push(await captureStill(page, target, baseUrl, outDir, viewportName));
    }
  }

  await context.close();

  const sheet = await buildContactSheet(browser, manifest.filter((e) => e.viewport === viewportName), outDir, viewportName);
  if (sheet) push(sheet);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const outDir = path.resolve(args.out);
  fs.mkdirSync(outDir, { recursive: true });

  const targets = readTargets(args.targets);
  const credentials = adminCredentials();

  const browser = await chromium.launch({ executablePath: CHROMIUM_PATH, args: ['--no-sandbox'] });
  const closeOnSignal = async () => {
    try { await browser.close(); } catch { /* already gone */ }
    process.exit(143);
  };
  process.on('SIGTERM', closeOnSignal);
  process.on('SIGINT', closeOnSignal);

  const manifest = [];
  try {
    for (const viewportDef of VIEWPORTS) {
      await captureViewport(browser, targets, args['base-url'], credentials, outDir, viewportDef, manifest);
    }
  } finally {
    await browser.close();
  }

  writeManifest(outDir, manifest);
  console.log(`captured ${manifest.length} entries -> ${path.join(outDir, 'manifest.json')}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
