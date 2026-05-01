# ox-migration-tools

Shell script to export calendar, contacts and tasks from Open-Xchange AppSuite via HTTP API. Supports app passwords.

## Usage

```sh
./ox_http_api_dataextract.sh -t {tasks|calendar|contacts|all} [serverurl] [user] [password]
```

Credentials can be set directly in the script or passed as positional arguments. App passwords work if the account has export permissions.

## Requirements

- `curl`
- `jq`
