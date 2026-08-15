# hamberger-dl

Download invoices from the Hamberger customer portal (mein.hamberger-cc.de) from the command line — no app needed.

- Lists your invoices as plain text
- Downloads PDFs, one by one or as a single ZIP
- Filters by date range and invoice type
- Re-runs are safe: already-downloaded PDFs are skipped

## Requirements

macOS with `curl`, `python3`, `openssl`, and `uuidgen` (all ship with macOS by default).

## Install

One line:

```sh
curl -fsSL https://raw.githubusercontent.com/faramirezs/hamberger-dl/main/install.sh | bash
```

This installs `hamberger-dl` into `~/bin` (override with `HAMBERGER_INSTALL_DIR`, e.g. `~/.local/bin`). If `~/bin` is not on your PATH, the installer prints the line to add it.

Manual install — copy the script anywhere on your PATH and make it executable:

```sh
mkdir -p ~/bin
curl -fsSL https://raw.githubusercontent.com/faramirezs/hamberger-dl/main/hamberger-dl -o ~/bin/hamberger-dl
chmod +x ~/bin/hamberger-dl
```

## Quick start

```sh
hamberger-dl login        # once: asks for your portal username and password
hamberger-dl list         # see your invoices
hamberger-dl download     # save all invoices as PDFs
```

PDFs land in `~/Downloads/Hamberger` by default (`--out DIR` to change).

## Usage

```
hamberger-dl help
hamberger-dl login
hamberger-dl list [filters]
hamberger-dl download [ID...] [filters] [--out DIR] [--overwrite]
hamberger-dl zip [ID...] [filters] [--out DIR]
```

### Filters

| Option | Meaning |
|---|---|
| `--after YYYY-MM-DD` | only invoices dated on/after this date |
| `--before YYYY-MM-DD` | only invoices dated on/before this date |
| `--type TYPE` | only `RECHNUNG` (invoice) or `GUTSCHRIFT` (credit note) |

### Examples

```sh
hamberger-dl download --after 2026-07-01          # invoices since July 2026
hamberger-dl download --after 2025-01-01 --before 2025-12-31   # all of 2025
hamberger-dl download --type GUTSCHRIFT           # credit notes only
hamberger-dl download 26-008-7823899 --out ~/Documents/invoices
hamberger-dl zip --after 2026-01-01               # one ZIP for the whole year
```

`download` and `zip` accept explicit invoice IDs (as shown by `list`) instead of filters.

## How it works

The tool talks to the customer portal's own web API: an OpenID Connect login (Keycloak) with token caching, then REST calls to list and download invoices. Tokens are stored in `~/.config/hamberger/tokens.json` (mode 600); your password is never saved. When the cached tokens expire, the next run asks you to log in again.

## Uninstall

```sh
rm ~/bin/hamberger-dl
rm -rf ~/.config/hamberger
```

## License

MIT — see [LICENSE](LICENSE).

*Unofficial tool, not affiliated with Hamberger.*
