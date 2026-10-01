const styles = `
  :root { color-scheme: light dark; --edge: #d8d2c8; --accent: #7a5c3e; --muted: #6b6560;
          --soft: rgba(122, 92, 62, 0.08); }
  * { box-sizing: border-box; }
  body { margin: 0; font: 16px/1.55 ui-sans-serif, system-ui, sans-serif; }
  header { border-bottom: 1px solid var(--edge); padding: 1rem 1.25rem; display: flex;
           flex-wrap: wrap; gap: 1rem; align-items: baseline; }
  header h1 { font-size: 1.1rem; margin: 0; letter-spacing: 0.01em; }
  nav { display: flex; gap: 1rem; flex-wrap: wrap; }
  nav a { color: inherit; text-decoration: none; border-bottom: 2px solid transparent; }
  nav a:hover, nav a[aria-current="page"] { border-bottom-color: var(--accent); }
  main { max-width: 56rem; margin: 0 auto; padding: 1.5rem 1.25rem 4rem; }
  h2 { font-size: 1.3rem; margin: 2rem 0 0.75rem; }
  h2:first-child { margin-top: 0; }
  h3 { font-size: 1rem; margin: 1.5rem 0 0.5rem; }
  a { color: var(--accent); }
  table { border-collapse: collapse; width: 100%; }
  th, td { text-align: left; padding: 0.5rem 0.75rem 0.5rem 0; border-bottom: 1px solid var(--edge);
           vertical-align: top; }
  th { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--muted); }
  td.amount { white-space: nowrap; }
  code { font-size: 0.9em; }
  .note { color: var(--muted); }
  .pill { display: inline-block; padding: 0.1rem 0.5rem; border: 1px solid var(--edge);
          border-radius: 999px; font-size: 0.8rem; margin-right: 0.3rem; }
  .pill.flag { border-color: #a23a2c; color: #a23a2c; }
  .ok { color: #2f6b36; } .bad { color: #a23a2c; }
  .steps { padding-left: 1.2rem; } .steps li { margin: 0.4rem 0; }
  .bar { display: flex; gap: 0.75rem; align-items: center; flex-wrap: wrap; margin-bottom: 1.5rem; }
  .bar form { margin: 0; }
  .banner { background: var(--soft); border-left: 3px solid var(--accent);
            padding: 0.7rem 0.9rem; margin-bottom: 1.5rem; }
  .banner.bad { border-left-color: #a23a2c; }
  label { display: block; font-size: 0.8rem; text-transform: uppercase;
          letter-spacing: 0.06em; color: var(--muted); margin-bottom: 0.25rem; }
  input, select, textarea, button { font: inherit; }
  input, select, textarea { width: 100%; padding: 0.45rem 0.55rem; border: 1px solid var(--edge);
                            border-radius: 4px; background: transparent; color: inherit; }
  textarea { resize: vertical; min-height: 7rem; font-family: ui-monospace, monospace; font-size: 0.9rem; }
  .field { margin-bottom: 1rem; }
  .row { display: grid; grid-template-columns: repeat(auto-fit, minmax(10rem, 1fr)); gap: 1rem; }
  button { padding: 0.45rem 1rem; border: 1px solid var(--accent); border-radius: 4px;
           background: var(--accent); color: #fff; cursor: pointer; }
  button.quiet { background: transparent; color: var(--accent); }
  .empty { border: 1px dashed var(--edge); padding: 1.5rem; text-align: center; }
  ol.recipe { padding-left: 1.3rem; } ol.recipe li { margin: 0.5rem 0; }
`;

const navigation = [
  { href: '/', label: 'Status' },
  { href: '/recipes', label: 'Recipes' },
];

export function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, (character) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[character]));
}

export function page({ title, body, current = '/' }) {
  const links = navigation
    .map(({ href, label }) => {
      const marker = href === current ? ' aria-current="page"' : '';

      return `<a href="${href}"${marker}>${escapeHtml(label)}</a>`;
    })
    .join('');

  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} &middot; Meal planner</title>
<style>${styles}</style>
</head>
<body>
<header><h1><a href="/" style="color:inherit;text-decoration:none">Meal planner</a></h1><nav>${links}</nav></header>
<main>${body}</main>
</body>
</html>
`;
}
