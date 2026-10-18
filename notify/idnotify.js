// idnotify.js - send the RustDesk ID plus IPs to Telegram on every start.
// needs: node.exe (portable is fine) and tg.json in the repo root with {"token": "...", "chat_id": "..."}
var https = require('https');
var fs = require('fs');
var os = require('os');
var path = require('path');
var cp = require('child_process');

var DIR = path.resolve(__dirname, '..');
var CFG = path.join(DIR, 'tg.json');
var LOG = path.join(DIR, 'last.log');
var LOCALAPPDATA = process.env.LOCALAPPDATA || path.join(os.homedir(), 'AppData', 'Local');

function log(m) {
  try { fs.appendFileSync(LOG, (new Date()).toISOString() + ' ' + m + '\r\n', 'utf8'); } catch (e) {}
}

// any rustdesk-*-x86_64.exe in the repo root, else the unpacked payload
function findRustDesk() {
  var candidates = [];
  try {
    var list = fs.readdirSync(DIR);
    for (var i = 0; i < list.length; i++) {
      if (/^rustdesk.*-x86.*\.exe$/i.test(list[i])) { candidates.push(path.join(DIR, list[i])); }
    }
  } catch (e) {}
  candidates.push(path.join(LOCALAPPDATA, 'rustdesk', 'rustdesk.exe'));
  for (var j = 0; j < candidates.length; j++) {
    if (fs.existsSync(candidates[j])) { return { exe: candidates[j], dir: path.dirname(candidates[j]) }; }
  }
  return null;
}

function getRustDeskId(cb) {
  var rd = findRustDesk();
  if (!rd) { log('ERR rustdesk.exe not found'); cb(''); return; }
  try {
    var r = cp.spawnSync(rd.exe, ['--get-id'], { timeout: 25000, windowsHide: true, cwd: rd.dir });
    var out = (r.stdout ? r.stdout.toString('utf8') : '').trim();
    var m = out.match(/\d{6,15}/);
    cb(m ? m[0] : '');
  } catch (e) { log('ERR get-id ' + e.message); cb(''); }
}

function localIps() {
  var out = [], ifs = os.networkInterfaces();
  for (var k in ifs) {
    var arr = ifs[k] || [];
    for (var i = 0; i < arr.length; i++) {
      var a = arr[i];
      if ((a.family === 'IPv4' || a.family === 4) && !a.internal) { out.push(a.address); }
    }
  }
  return out.join(', ');
}

function externalIp(cb) {
  var req = https.get('https://api.ipify.org', { rejectUnauthorized: false }, function (res) {
    var c = [];
    res.on('data', function (d) { c.push(d); });
    res.on('end', function () { cb(Buffer.concat(c).toString('utf8').trim()); });
  });
  req.on('error', function () { cb('?'); });
  req.setTimeout(10000, function () { req.abort(); cb('?'); });
}

function send(token, chatId, text, cb) {
  var body = JSON.stringify({ chat_id: chatId, text: text, disable_web_page_preview: true });
  var opts = {
    method: 'POST', host: 'api.telegram.org', path: '/bot' + token + '/sendMessage',
    headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    rejectUnauthorized: false
  };
  var req = https.request(opts, function (res) {
    var c = [];
    res.on('data', function (d) { c.push(d); });
    res.on('end', function () { cb(Buffer.concat(c).toString('utf8')); });
  });
  req.on('error', function (e) { cb('NETERR ' + e.message); });
  req.setTimeout(20000, function () { req.abort(); cb('TIMEOUT'); });
  req.write(body);
  req.end();
}

var cfg = {};
try { cfg = JSON.parse(fs.readFileSync(CFG, 'utf8')); } catch (e) { log('ERR config ' + e.message); process.exit(1); }
if (!cfg.token || !cfg.chat_id) { log('ERR token/chat_id missing in tg.json'); process.exit(1); }

getRustDeskId(function (id) {
  externalIp(function (ext) {
    var now = new Date();
    var pad = function (n) { return (n < 10 ? '0' : '') + n; };
    var stamp = pad(now.getDate()) + '.' + pad(now.getMonth() + 1) + '.' + now.getFullYear() + ' ' +
      pad(now.getHours()) + ':' + pad(now.getMinutes());
    var hostName = process.env.COMPUTERNAME || process.env.HOSTNAME || 'PC';
    var text = 'PC is up: ' + hostName + '\n' +
      'RustDesk ID: ' + (id || '?') + '\n' +
      'LAN IP: ' + (localIps() || '?') + '\n' +
      'External IP: ' + ext + '\n' +
      'Time: ' + stamp;
    log('notify id=' + id + ' ext=' + ext);
    send(cfg.token, cfg.chat_id, text, function (res) {
      log('tg answer: ' + res.substring(0, 200));
      process.exit(0);
    });
  });
});
