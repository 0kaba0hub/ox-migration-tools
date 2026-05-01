# ox-migration-tools

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](LICENSE)

Shell script that exports calendar, contacts and tasks from an **Open-Xchange AppSuite** instance via its HTTP API. Outputs standard iCalendar (`.ics`) and vCard (`.vcf`) files compatible with any CalDAV/CardDAV client, Google Workspace, Nextcloud, and similar platforms.

---

## Requirements

- `curl`
- `jq`

---

## Usage

```sh
./ox_http_api_dataextract.sh -t {tasks|calendar|contacts|all} [serverurl] [user] [password]
```

| Argument | Description |
|:---------|:------------|
| `-t TYPE` | Data type to export: `tasks`, `calendar`, `contacts`, or `all` |
| `serverurl` | OX AppSuite base URL, e.g. `https://ox.example.com` |
| `user` | Login username (usually email) |
| `password` | Account password or app password |

Positional arguments are optional — credentials can be set directly in the script (see [Configuration](#configuration)).

---

## Output formats

| Type | Format | Import target |
|:-----|:-------|:--------------|
| `calendar` | iCalendar (`.ics`) | Google Calendar, Nextcloud, Apple Calendar |
| `tasks` | iCalendar (`.ics`) | Nextcloud Tasks, Thunderbird |
| `contacts` | vCard (`.vcf`) | Google Contacts, Nextcloud, Apple Contacts |

---

## Examples

```bash
# Export all data using credentials from the script
./ox_http_api_dataextract.sh -t all

# Export only contacts, save to file
./ox_http_api_dataextract.sh -t contacts https://ox.example.com user@example.com mypassword > contacts.vcf

# Export calendar with app password
./ox_http_api_dataextract.sh -t calendar https://ox.example.com user@example.com app-password-here > calendar.ics

# Export everything, save each type separately
./ox_http_api_dataextract.sh -t tasks   https://ox.example.com user@example.com pass > tasks.ics
./ox_http_api_dataextract.sh -t calendar https://ox.example.com user@example.com pass > calendar.ics
./ox_http_api_dataextract.sh -t contacts https://ox.example.com user@example.com pass > contacts.vcf
```

---

## Configuration

Open `ox_http_api_dataextract.sh` and set the defaults at the top of the file:

```bash
SERVER=https://example.ox.io     # OX AppSuite base URL
USER="user@domain.com"           # Login username
PASSWORD="CHANGE_ME"             # Password or app password
```

These values are overridden if you pass positional arguments on the command line.

> **Note:** The script uses `-k` with curl, which disables SSL certificate verification. This is intentional for environments with self-signed certificates. Remove it if your server has a valid public certificate.

---

## App passwords

If the OX AppSuite account has two-factor authentication or external app access restrictions, generate an **app password** in the account security settings and use it in place of the main password. App passwords work as long as the account has export permissions enabled by the administrator.

---

## License

[GPL-3.0](LICENSE)
