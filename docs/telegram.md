# Telegram notification

The notifier sends one message per boot: host name, RustDesk ID, LAN IP, external IP, time.
Needs a node runtime, because Windows 7 has no TLS 1.2 in SChannel and PowerShell 2.0 cannot
talk to `api.telegram.org`. A portable `node.exe` in the repo root is enough, no install.

## 1. Create a bot

1. In Telegram open `@BotFather`, send `/newbot`, pick a name and a username.
2. Copy the token it prints, it looks like `123456789:AA...`.

## 2. Get your chat_id

Put the token into `tg.json` first, then run from the repo root:

```
node.exe notify\tg.js updates
```

Write something to the bot from your own account, run the command again, it prints
`chat_id=...`. Save it:

```
node.exe notify\tg.js setchat <chat_id>
```

Or just copy `tg.json.example` to `tg.json` and fill both fields by hand.

## 3. Check

```
node.exe notify\idnotify.js
```

The message arrives, and `last.log` gets a line with the Telegram answer.

## Notes

- `tg.json` is in `.gitignore`, keep the token out of the repo.
- Without `tg.json` the whole notification step is skipped and RustDesk still starts hidden.
- `notify\tg.js send "text"` sends an arbitrary message, handy for testing.
