#!/usr/bin/env bash
# ox_http_api_dataextract v0.2 — export calendar/contacts/tasks from OX AppSuite via HTTP API
# https://github.com/0kaba0hub/ox-migration-tools

OX_SERVER="https://example.ox.io"
OX_USER="user@domain.com"
OX_PASSWORD="CHANGE_ME"
OX_CLIENT="my-export-client"

CURL=(curl -b cookies -c cookies -H "Expect:" -s -L --location-trusted -k)
VALID_TYPES=("tasks" "calendar" "contacts" "all")

usage() {
    cat <<EOF
Usage: $0 -t {tasks|calendar|contacts|all} [serverurl] [user] [password]
EOF
    exit 1
}

login() {
    local session
    session=$("${CURL[@]}" --data "name=$OX_USER&password=$OX_PASSWORD&client=$OX_CLIENT" \
        "$OX_SERVER/ajax/login?action=login")
    if echo "$session" | grep -q "error"; then
        echo "login failed" >&2
        exit 1
    fi
    echo "$session"
}

get_folders() {
    local session=$1
    "${CURL[@]}" -X GET \
        "$OX_SERVER/ajax/folders?action=list&columns=1%2C301%2C300%2C307%2C304%2C306%2C302%2C305%2C308%2C311%2C2%2C314%2C313%2C315&session=$session&parent=1"
}

export_tasks() {
    local session=$1 folder=$2
    "${CURL[@]}" -X GET "$OX_SERVER/ajax/export?action=ICAL&session=$session&folder=$folder"
}

export_calendar() {
    local session=$1 folder=$2
    "${CURL[@]}" -X GET "$OX_SERVER/ajax/export?action=ICAL&session=$session&folder=cal://0/$folder"
}

export_contacts() {
    local session=$1 folder=$2
    "${CURL[@]}" -X GET "$OX_SERVER/ajax/export?action=VCARD&session=$session&folder=$folder"
}

# --- main ---

while getopts ":t:" opt; do
    case $opt in
        t)  TYPE="$OPTARG" ;;
        \?) echo "Error: Unknown option -$OPTARG" >&2;          usage ;;
        :)  echo "Error: Option -$OPTARG requires an argument" >&2; usage ;;
    esac
done
shift $((OPTIND - 1))

[[ -z "$TYPE" ]] && { echo "Error: -t option is required" >&2; usage; }

if [[ ! " ${VALID_TYPES[*]} " =~ " ${TYPE} " ]]; then
    echo "Error: Invalid value for -t: $TYPE" >&2
    usage
fi

[[ -n "$1" ]] && OX_SERVER="$1"
[[ -n "$2" ]] && OX_USER="$2"
[[ -n "$3" ]] && OX_PASSWORD="$3"

RESPONSE=$(login)
SESSION=$(echo "$RESPONSE" | jq -r '.session')

FOLDERS=$(get_folders "$SESSION")
CAL=$(echo "$FOLDERS"  | jq -r '.data[] | select(.[1] == "calendar") | .[0]' | grep '^[0-9]\+$')
TASK=$(echo "$FOLDERS" | jq -r '.data[] | select(.[1] == "tasks")    | .[0]')
CON=$(echo "$FOLDERS"  | jq -r '.data[] | select(.[1] == "contacts") | .[0]' | grep '^[0-9]\+$')

sep() { echo "------------------------------------------------------" >&2; }

case "$TYPE" in
    tasks)
        sep; echo "exporting private task folder $TASK:" >&2; sep
        export_tasks "$SESSION" "$TASK"
        ;;
    calendar)
        sep; echo "exporting private calendar folder $CAL:" >&2; sep
        export_calendar "$SESSION" "$CAL"
        ;;
    contacts)
        sep; echo "exporting private contacts folder $CON:" >&2; sep
        export_contacts "$SESSION" "$CON"
        ;;
    all)
        sep; echo "exporting private task folder $TASK:" >&2;     sep; export_tasks    "$SESSION" "$TASK"
        sep; echo "exporting private calendar folder $CAL:" >&2;  sep; export_calendar "$SESSION" "$CAL"
        sep; echo "exporting private contacts folder $CON:" >&2;  sep; export_contacts "$SESSION" "$CON"
        ;;
esac
