// tg.js - Telegram helper (runs on Node inside DSH: TLS works, SChannel not needed)
// usage:
//   node tg.js updates            -> print chat ids / last messages
//   node tg.js send "text"        -> send message to configured chat
//   node tg.js setchat <chat_id>  -> remember chat id
var https = require('https');
var fs = require('fs');
var path = require('path');

var CFG = path.join(__dirname, 'tg.json');
var cfg = { token: '', chat_id: '' };
try { cfg = JSON.parse(fs.readFileSync(CFG, 'utf8')); } catch (e) {}

function api(method, payload, cb) {
  var body = payload ? JSON.stringify(payload) : null;
  var opts = {
    method: body ? 'POST' : 'GET',
    host: 'api.telegram.org',
    path: '/bot' + cfg.token + '/' + method,
    headers: { 'Content-Type': 'application/json' },
    rejectUnauthorized: false
  };
  if (body) { opts.headers['Content-Length'] = Buffer.byteLength(body); }
  var req = https.request(opts, function (res) {
    var chunks = [];
    res.on('data', function (c) { chunks.push(c); });
    res.on('end', function () {
      var text = Buffer.concat(chunks).toString('utf8');
      var json = null;
      try { json = JSON.parse(text); } catch (e) {}
      cb(json, text, res.statusCode);
    });
  });
  req.on('error', function (e) { cb(null, 'NETERR ' + e.message, 0); });
  req.setTimeout(20000, function () { req.abort(); cb(null, 'TIMEOUT', 0); });
  if (body) { req.write(body); }
  req.end();
}

var cmd = process.argv[2] || '';

if (cmd === 'updates') {
  api('getUpdates', null, function (json, text) {
    if (!json || !json.ok) { console.log('ERR ' + text.substring(0, 300)); return; }
    var n = (json.result || []).length;
    console.log('updates=' + n);
    var seen = {};
    for (var i = 0; i < json.result.length; i++) {
      var u = json.result[i];
      var m = u.message || u.edited_message || u.channel_post;
      if (!m) { continue; }
      var cid = m.chat && m.chat.id;
      var who = (m.from && (m.from.username || m.from.first_name)) || '?';
      if (!seen[cid]) { seen[cid] = 1; console.log('chat_id=' + cid + ' from=' + who + ' text=' + (m.text || '').substring(0, 40)); }
    }
  });
} else if (cmd === 'setchat') {
  cfg.chat_id = String(process.argv[3] || '');
  fs.writeFileSync(CFG, JSON.stringify(cfg, null, 2), 'utf8');
  console.log('chat_id=' + cfg.chat_id);
} else if (cmd === 'send') {
  var text = process.argv.slice(3).join(' ');
  if (!cfg.chat_id) { console.log('ERR no chat_id'); return; }
  api('sendMessage', { chat_id: cfg.chat_id, text: text, disable_web_page_preview: true }, function (json, raw) {
    if (json && json.ok) { console.log('SENT ok message_id=' + json.result.message_id); }
    else { console.log('ERR ' + raw.substring(0, 400)); }
  });
} else {
  console.log('usage: node tg.js updates|send|setchat');
}
