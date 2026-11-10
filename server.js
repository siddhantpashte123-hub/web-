const express = require('express');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'pastes.json');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Make sure data folder + file exist (no database needed, file-based storage)
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}
if (!fs.existsSync(DATA_FILE)) {
  fs.writeFileSync(DATA_FILE, '{}');
}

let pastes = {};
try {
  pastes = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
} catch (e) {
  pastes = {};
  fs.writeFileSync(DATA_FILE, '{}');
}

function save() {
  fs.writeFileSync(DATA_FILE, JSON.stringify(pastes, null, 2));
}

function genId() {
  return crypto.randomBytes(4).toString('hex'); // 8 char unique id
}

// Home page - paste HTML here
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Create a paste from HTML -> returns a shareable URL
app.post('/api/paste', (req, res) => {
  const { html } = req.body;
  if (!html || html.trim() === '') {
    return res.status(400).json({ error: 'HTML chahiye (empty nahi)' });
  }

  const id = genId();
  pastes[id] = {
    html: html,
    createdAt: new Date().toISOString(),
  };
  save();

  const base = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
  res.json({ id, url: `${base}/view/${id}` });
});

// View the pasted HTML as a live page
app.get('/view/:id', (req, res) => {
  const p = pastes[req.params.id];
  if (!p) {
    return res.status(404).send('<h2 style="font-family:sans-serif;color:#c00;">Paste nahi mila (404)</h2>');
  }
  res.send(`<!DOCTYPE html>
<html lang="hi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Paste ${req.params.id}</title>
<style>
body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;padding:20px;line-height:1.6;background:#f5f5f5}
.frame{background:#fff;padding:24px;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,.1);max-width:900px;margin:0 auto}
.badge{display:inline-block;margin-bottom:12px;padding:4px 10px;border-radius:6px;background:#eef;font-size:.8rem;color:#333;border:1px solid #ddd}
</style>
</head>
<body>
<div class="frame">
  <div class="badge">Paste ID: ${req.params.id} &bull; HTML-only paste service</div>
  ${p.html}
</div>
</body>
</html>`);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`HTML Paste server running on port ${PORT}`);
});
