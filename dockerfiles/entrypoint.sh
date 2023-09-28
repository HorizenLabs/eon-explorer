#!/bin/bash
set -eEuo pipefail

USER_ID="${LOCAL_USER_ID:-9001}"
GRP_ID="${LOCAL_GRP_ID:-9001}"

if [ "$USER_ID" != "0" ]; then
  export USERNAME=user
  getent group "$GRP_ID" &>/dev/null || groupadd -g "$GRP_ID" "$USERNAME"
  id -u "$USERNAME" &>/dev/null || useradd --shell /bin/bash -u "$USER_ID" -g "$GRP_ID" -o -c "" -m "$USERNAME"
  CURRENT_UID="$(id -u $USERNAME)"
  CURRENT_GID="$(id -g $USERNAME)"
  if [ "$USER_ID" != "$CURRENT_UID" ] || [ "$GRP_ID" != "$CURRENT_GID" ]; then
    echo -e "WARNING: User with differing UID $CURRENT_UID/GID $CURRENT_GID already exists, most likely this container was started before with a different UID/GID. Re-create it to change UID/GID.\n"
  fi
else
  CURRENT_UID="$USER_ID"
  CURRENT_GID="$GRP_ID"
  echo -e "WARNING: Starting container processes as root. This has some security implications and goes against docker best practice.\n"
fi

# set $HOME
if [ "$CURRENT_UID" != "0" ]; then
  export USERNAME=user
  export HOME=/home/"$USERNAME"
else
  export USERNAME=root
  export HOME=/root
fi

echo -e "\nUsername: $USERNAME, HOME: $HOME, UID: $CURRENT_UID, GID: $CURRENT_GID"

find "${WORKDIR:?}" -writable -print0 | xargs -0 -I{} -P64 -n1 chown -f "${CURRENT_UID}":"${CURRENT_GID}" "{}"

RELEASE_VERSION="$(cut -d' ' -f2 "${WORKDIR:?}/releases/start_erl.data")"
cp "${WORKDIR:?}"/config/config_helper.exs "${WORKDIR:?}"/releases/"${RELEASE_VERSION}"/config_helper.exs

# 'CREATE_AND_MIGRATE': When set to true this variable will enable running the create and migrate function in elixir code.
# When running that function the migration scripts are reviewed and applied to the database. This variable is false by default.
# If changes are needed to be done to the database it needs to be notified and approved.
if [ "${CREATE_AND_MIGRATE:-false}" = "true" ]; then
  echo "Running create and migrate process"
  "${WORKDIR:?}"/bin/blockscout eval "Elixir.Explorer.ReleaseTasks.create_and_migrate()"
fi

gosu_cmd=""
[ "${CURRENT_UID}" -ne 0 ] && gosu_cmd="/usr/local/bin/gosu $USERNAME"
exec $gosu_cmd "$@"
