#!/bin/bash
set -eo pipefail

IS_A_RELEASE="false"
export PROD_RELEASE_BRANCH="${PROD_RELEASE_BRANCH:-master}"

mix_version_tag="$(grep -oE 'version: "[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?(-RC[0-9]+)?"' mix.exs | cut -d ' ' -f2 | tr -d '"')"

if [ -z "${TRAVIS_TAG}" ]; then
  echo "TRAVIS_TAG:                     No TAG"
else
  echo "TRAVIS_TAG:                     ${TRAVIS_TAG}"
fi
echo "Production release branch is:   ${PROD_RELEASE_BRANCH}"
echo "Root mix.exs version:           ${mix_version_tag}"


# Functions
function import_gpg_keys() {
  # shellcheck disable=SC2207
  declare -r my_arr=( $(echo "${@}" | tr " " "\n") )

  if [ "${#my_arr[@]}" -eq 0 ]; then
    echo "Warning: there are ZERO gpg keys to import. Please check if *MAINTAINERS_KEYS variable(s) are set correctly. The build is not going to be released ..."
    export IS_A_RELEASE="false"
  else
    # shellcheck disable=SC2145
    printf "%s\n" "Tagged build, fetching keys:" "${@}" ""
    for key in "${my_arr[@]}"; do
      gpg -v --batch --keyserver hkps://keys.openpgp.org --recv-keys "${key}" ||
      gpg -v --batch --keyserver hkp://keyserver.ubuntu.com --recv-keys "${key}" ||
      gpg -v --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "${key}" ||
      gpg -v --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "${key}" ||
      { echo -e "Warning: ${key} can not be found on GPG key servers. Please upload it to at least one of the following GPG key servers:\nhttps://keys.openpgp.org/\nhttps://keyserver.ubuntu.com/\nhttps://pgp.mit.edu/"; export IS_A_RELEASE="false"; }
    done
  fi
}

function check_signed_tag() {
  local tag="${1}"

  if git verify-tag -v "${tag}"; then
    echo "${tag} is a valid signed tag"
  else
    echo "" && echo "=== Warning: GIT's tag = ${tag} signature is NOT valid. The build is not going to be released ... ===" && echo ""
    export IS_A_RELEASE="false"
  fi
}

function  check_versions_match () {
  local versions_to_check=("$@")

  if [ "${#versions_to_check[@]}" -eq 1 ]; then
    echo "Warning: ${FUNCNAME[0]} requires more than one version to be able to compare with.  The build is not going to be released ..."
    export IS_A_RELEASE="false" && return
  fi

  for (( i=0; i<((${#versions_to_check[@]}-1)); i++ )); do
    [ "${versions_to_check[$i]}" != "${versions_to_check[(($i+1))]}" ] &&
    { echo -e "Warning: one or more module(s) versions do NOT match. The build is not going to be released ... !!!\nThe versions are ${versions_to_check[*]}"; export IS_A_RELEASE="false" && return; }
  done

  export IS_A_RELEASE="true"
}

# empty key.asc file in case we're not signing
touch "${HOME}/key.asc"

# Checking if it a release build
if [ -n "${TRAVIS_TAG}" ]; then

  check_versions_match "${TRAVIS_TAG}" "${mix_version_tag}"

  if [ -z "${PROD_MAINTAINERS_KEYS:-}" ]; then
    echo "Warning: PROD_MAINTAINERS_KEYS variable is not set. Make sure to set it up for PROD|DEV release build !!!"
  fi

  if ( git branch -r --contains "${TRAVIS_TAG}" | grep -xqE ". origin\/${PROD_RELEASE_BRANCH}$" ); then

    export IS_A_RELEASE="true"

    import_gpg_keys "${PROD_MAINTAINERS_KEYS}"

    check_signed_tag "${TRAVIS_TAG}"

    # Checking format of production release version
    if ! [[ "${TRAVIS_TAG}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?(-RC[0-9]+)?$ ]]; then
      echo "Warning: package(s) version is in the wrong format for PRODUCTION release. Expecting: d.d.d(-d)?(-RC[0-9]+)?. The build is not going to be released !!!"
      export IS_A_RELEASE="false"
    fi

    # Announcing PROD release
    if [ "${IS_A_RELEASE}" = "true" ]; then
      echo "" && echo "=== Production release ===" && echo ""
    fi
  else
    export IS_A_RELEASE="false"
  fi
fi

# Final check for release vs non-release build
if [ "${IS_A_RELEASE}" = "false" ]; then
  echo "" && echo "=== NOT a release build ===" && echo ""
  export IS_A_RELEASE="false"
fi

set +eo pipefail
