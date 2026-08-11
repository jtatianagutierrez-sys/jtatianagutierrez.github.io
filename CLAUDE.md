# Pages repo rules

This repo is **public** and GitHub Pages serves it **from the root of `main`**.
Anything committed here is live on the internet and indexable by Google.

Live base URL:
`https://jtatianagutierrez-sys.github.io/`

(The repo is named `jtatianagutierrez-sys.github.io`, matching the account name,
which makes it a **user page** served straight off the domain root. It was
renamed from `jtatianagutierrez.github.io` on 11 Aug 2026; the old project-page
URLs that repeated the name in the path now 404. Nothing depended on them:
Meta had already copied every ad image to its own CDN.)

## Where files go

| Put it here | What happens |
|---|---|
| `public-encrypted/<path>.html` | Encrypted on commit, published locked at `/<path>.html`. **Gitignored** - the source never leaves this machine. |
| repo root, e.g. `prisma-ads/` | Published in the clear, readable by anyone. |

Anything with numbers a competitor or the public shouldn't see goes in
`public-encrypted/`. That means performance reports, revenue, spend, ROAS,
client deliverables, audits, strategy, pricing.

Ad creatives and other assets meant to be seen publicly go at the root.

## Encryption

- Master secret lives in `.env` (gitignored, chmod 600). Never print it, never commit it.
- Each page's password is derived from the master secret + the file's path, so
  the same file always has the same password, and one page's password does not
  unlock another.
- `./scripts/encrypt.sh` encrypts everything in `public-encrypted/`.
- `./scripts/passwords.sh` prints each page's live URL and password.
- The pre-commit hook runs the encryption automatically and refuses any commit
  that has a secret file staged.
- After a fresh clone, reinstall the hook:
  `cp scripts/pre-commit .git/hooks/ && chmod +x .git/hooks/pre-commit`

Send the URL and the password in **separate messages** (URL by email, password
by Teams or similar).

## Images: always JPG, never PNG

Git history keeps every version of every file forever, even after deletion.
A phone-sized PNG is ~10 MB; the same image as JPG is ~200 KB.

Convert before committing:

```bash
sips -s format jpeg -s formatOptions 85 input.png --out prisma-ads/output.jpg
```

Never commit a PNG over ~2 MB. This repo's history is already 133 MB, about
90 MB of which is deleted Point Hacks PNGs that were committed without
conversion.

## Commits

Action prefix, then why not what: `Add:`, `Fix:`, `Update:`, `Remove:`, `Security:`.

## Before deleting anything published

Check whether a client or colleague still has the link. Deleting a file makes
its URL 404.
