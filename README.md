# hamberger-dl

Download invoices from the Hamberger customer portal from the command line, no app needed.

- Lists your invoices as plain text
- Downloads PDFs, one by one or as a single ZIP
- Filters by date range and invoice type
- Re-runs are safe: already-downloaded PDFs are skipped

## Requirements

- macOS or Linux with `curl`, `python3`, and `openssl`
- A Hamberger customer account. You log in with the same username and password you use on the customer portal (this is what the `login` step is for).

## Install

One line:

```sh
curl -fsSL https://raw.githubusercontent.com/faramirezs/hamberger-dl/main/install.sh | bash
```

This installs `hamberger-dl` into `~/bin` (override with `HAMBERGER_INSTALL_DIR`, e.g. `~/.local/bin`). If `~/bin` is not on your PATH, the installer prints the line to add it.

Manual install: copy the script anywhere on your PATH and make it executable:

```sh
mkdir -p ~/bin
curl -fsSL https://raw.githubusercontent.com/faramirezs/hamberger-dl/main/hamberger-dl -o ~/bin/hamberger-dl
chmod +x ~/bin/hamberger-dl
```

## Quick start

> You'll need a Hamberger customer account. The `login` step asks for the username and password you use on the portal; they are never stored.

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

## Request flow and security

The CLI is a single Bash script. It uses `curl` for HTTP and `python3` for JSON.

### Request flow

1. `hamberger-dl <command>` parses the command and the filters (`--after`, `--before`, `--type`, `--out`, `--overwrite`).
2. `ensure_token` loads the token cache. If the cached access token has not expired yet, the run continues without any auth request.
3. If the cached access token has expired, the script tries the `refresh_token` grant against the portal's OpenID Connect (Keycloak) token endpoint. The refresh token is minted at login through the `offline_access` scope, so it works without the browser.
4. If Keycloak rejects the refresh grant, the script starts an interactive login: an authorization request with PKCE (`S256`), `state` and `nonce`, then a POST of the login form to Keycloak, then an exchange of the authorization code for tokens. This is the only step that asks for the username and password.
5. `list`, `download` and `zip` request the invoice list with `GET /invoice/api/document` plus the header `Authorization: Bearer <access token>` and `Accept: application/json`. The JSON response is converted to `date <TAB> type <TAB> gross <TAB> id` rows, then filtered and sorted by date.
6. `download` fetches each invoice with `GET /invoice/api/document/<id>` and `Accept: application/pdf`, and writes the response body to `<out dir>/<id>.pdf`.
7. `zip` sends `POST /invoice/api/document/package` with a JSON body that holds the selected invoice IDs, and writes the response to a single ZIP file.

Every request goes to the portal's own login and API hosts. The script sends data to no other server.

### Credentials and token storage

- The username and password are read from the terminal at the login prompt (the password without echo). They are used in that one login request only. There is no password file, no password option and no password environment variable, and the password is never written to disk.
- The token cache lives in `~/.config/hamberger/tokens.json`. Set `HAMBERGER_CFG_DIR` to move it. The file holds `access_token`, `refresh_token`, `access_expires_at` and `saved_at`. It is written with mode `600`, and the config directory with mode `700`.
- Downloaded invoices go to `~/Downloads/Hamberger` by default. Change it with `--out DIR` or `HAMBERGER_OUT_DIR`.
- At install time the installer only downloads the script from this repository, copies it into the install directory (default `~/bin`) and prints a PATH hint and a next-step note. It sends no credentials and contacts no other host.
- The token is checked once per command, at the start. A run that outlives the remaining token lifetime can fail single requests, and those are reported per invoice as `FAIL <id>`.

### Re-runs are safe

`download` skips an invoice when `<out dir>/<id>.pdf` already exists, so an interrupted run continues where it stopped instead of fetching everything again. The check is per file. It tests that the file exists, not that it is complete, so use `--overwrite` after an interrupted download. `list` writes nothing.

`zip` is the exception to the rule: it always writes a new `invoices-<timestamp>.zip`, so repeated `zip` runs add files to the output directory.

## Uninstall

```sh
rm ~/bin/hamberger-dl
rm -rf ~/.config/hamberger
```

## License

MIT: see [LICENSE](LICENSE).

*Unofficial tool, not affiliated with Hamberger.*
