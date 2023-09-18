#!/bin/bash

set -eEuo pipefail

USER_ID="${LOCAL_USER_ID:-9001}"
GRP_ID="${LOCAL_GRP_ID:-9001}"
if [ "${USER_ID}" != "0" ]; then
    export USERNAME=test
    getent group "$GRP_ID" &> /dev/null || groupadd -g "$GRP_ID" "$USERNAME"
    id -u "$USERNAME" &> /dev/null || useradd --shell /bin/bash -u "$USER_ID" -g "$GRP_ID" -o -c "" -m "$USERNAME"
    CURRENT_UID="$(id -u "$USERNAME")"
    CURRENT_GID="$(id -g "$USERNAME")"
    export HOME=/home/"$USERNAME"
    if [ "$USER_ID" != "$CURRENT_UID" ] || [ "$GRP_ID" != "$CURRENT_GID" ]; then
        echo "WARNING: User with differing UID ${CURRENT_UID}/GID ${CURRENT_GID} already exists, most likely this container was started before with a different UID/GID. Re-create it to change UID/GID."
    fi
else
    export USERNAME=root
    export HOME=/root
    CURRENT_UID="$USER_ID"
    CURRENT_GID="$GRP_ID"
    echo "WARNING: Starting container processes as root. This has some security implications and goes against docker best practice."
fi

echo "Username: $USERNAME, HOME: $HOME, UID: $CURRENT_UID, GID: $CURRENT_GID"

echo "" && echo "=== Starting database ===" && echo ""
service postgresql start &> /dev/null

echo "" && echo "=== Creating 'test' user in database ===" && echo ""
su postgres <<EOF
  psql -U postgres -c "CREATE USER test NOSUPERUSER INHERIT CREATEDB CREATEROLE" &> /dev/null
  psql -U postgres -c "ALTER USER test PASSWORD 'test'" &> /dev/null
  psql -U postgres -c "ALTER USER postgres PASSWORD 'postgres'" &> /dev/null
EOF

if [ "$USERNAME" = "root" ]; then
  exec "$@"
else
  exec gosu "$USERNAME" "$@"
fi
