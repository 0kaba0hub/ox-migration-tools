#!/bin/bash

SERVER=https://example.ox.io
USER="user@domain.com"
PASSWORD="CHANGE_ME"
XCLIENT=pe-export-client

CURL='curl -b cookies -c cookies -H Expect: -s -L --location-trusted -k'
VALID_TYPES=("tasks" "calendar" "contacts" "all")

usage() {
    echo "Usage: $0 -t {tasks|calendar|contacts|all} [serverurl] [user] [password]"
    exit 1
}

login() {
    local session
    session=$($CURL --data "name=$USER&password=$PASSWORD&client=$XCLIENT" "$SERVER/ajax/login?action=login")
    if echo "$session" | grep -q "error"; then
        echo "got no session, login failed"
        exit 1
    fi
    echo "$session"
}

get_folders() {
    local session=$1
    local folders

    folders=$($CURL -X GET "$SERVER/ajax/folders?action=list&columns=1%2C301%2C300%2C307%2C304%2C306%2C302%2C305%2C308%2C311%2C2%2C314%2C313%2C315&session=$session&parent=1")
    echo "$folders"
}

export_tasks() {
    local session=$1
    local folder=$2
    local tasks

    tasks=$($CURL -X GET "$SERVER/ajax/export?action=ICAL&session=$session&folder=$folder")
    echo "$tasks"
}

export_calendar() {
    local session=$1
    local folder=$2
    local calendar

    calendar=$($CURL -X GET "$SERVER/ajax/export?action=ICAL&session=$session&folder=cal://0/$folder")
    echo "$calendar"
}

export_contacts() {
    local session=$1
    local folder=$2
    local contacts

    contacts=$($CURL -X GET "$SERVER/ajax/export?action=VCARD&session=$session&folder=$folder")
    echo "$contacts"
}

# --- main ---
# Parse -t option
while getopts ":t:" opt; do
    case $opt in
        t)
            TYPE="$OPTARG"
            ;;
        \?)
            echo "Error: Unknown option -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument" >&2
            usage
            ;;
    esac
done

# Shift parsed options; remaining args are positional
shift $((OPTIND - 1))

# Validate -t argument
if [[ -z "$TYPE" ]]; then
    echo "Error: -t option is required"
    usage
fi

if [[ ! " ${VALID_TYPES[@]} " =~ " ${TYPE} " ]]; then
    echo "Error: Invalid value for -t: $TYPE"
    usage
fi

# Override defaults with positional args if provided
[[ -n "$1" ]] && SERVER="$1"
[[ -n "$2" ]] && USER="$2"
[[ -n "$3" ]] && PASSWORD="$3"

RESPONSE=$(login)

#echo $RESPONSE

SESSION=$(echo "$RESPONSE" | jq -r '.session')
USER=$(echo "$RESPONSE" | jq -r '.user')
USER_ID=$(echo "$RESPONSE" | jq -r '.user_id')
CONTEXT_ID=$(echo "$RESPONSE" | jq -r '.context_id')
LOCALE=$(echo "$RESPONSE" | jq -r '.locale')
MULTIFACTOR=$(echo "$RESPONSE" | jq -r '.requires_multifactor // false')

P_FOLDERS=$(get_folders "$SESSION")

CAL="not found"
CAL2=$(echo "$P_FOLDERS" | jq -r '.data[] | select(.[1] == "calendar") | .[0]')
CAL=$(echo "$CAL2" | grep '^[0-9]\+$')

TASK="not found"
TASK=$(echo "$P_FOLDERS" | jq -r '.data[] | select(.[1] == "tasks") | .[0]')

CON="not found"
CON2=$(echo "$P_FOLDERS" | jq -r '.data[] | select(.[1] == "contacts") | .[0]')
CON=$(echo "$CON2" | grep '^[0-9]\+$')

case "$TYPE" in
    tasks)
        echo ------------------------------------------------------
        echo "exporting private task folder $TASK:"
        echo ------------------------------------------------------
        export_tasks "$SESSION" "$TASK"
        ;;
    calendar)
        echo ------------------------------------------------------
        echo "exporting private calendar folder $CAL:"
        echo ------------------------------------------------------
        export_calendar "$SESSION" "$CAL"
        ;;
    contacts)
        echo ------------------------------------------------------
        echo "exporting private contacts folder $CON:"
        echo ------------------------------------------------------
        export_contacts "$SESSION" "$CON"
        ;;
    all)
        echo ------------------------------------------------------
        echo "exporting private task folder $TASK:"
        echo ------------------------------------------------------
        export_tasks "$SESSION" $TASK
        echo ------------------------------------------------------
        echo "exporting private calendar folder $CAL:"
        echo ------------------------------------------------------
        export_calendar "$SESSION" "$CAL"
        echo ------------------------------------------------------
        echo "exporting private contacts folder $CON:"
        echo ------------------------------------------------------
        export_contacts "$SESSION" "$CON"
        ;;
esac
