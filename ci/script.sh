#!/bin/bash

set -eEuo pipefail

echo "=== Local variables ==="
ENABLE_LOGS="${ENABLE_LOGS:-true}"
ALLOW_AUDIT_FAILURES="${ALLOW_AUDIT_FAILURES:-false}"
ALLOW_TEST_FAILURES="${ALLOW_TEST_FAILURES:-false}"
PROD_RELEASE_BRANCH="${PROD_RELEASE_BRANCH:-master}"
DEV_RELEASE_BRANCH="${DEV_RELEASE_BRANCH:-development}"
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-zencash/blockscout}"
TEST_IMAGE_NAME="${TEST_IMAGE_NAME:-hexpm/elixir}"
TEST_IMAGE_TAG="${TEST_IMAGE_TAG:-1.14.5-erlang-25.3.2.6-ubuntu-jammy-20230126}"

# absolute path to project from relative location of this script
workdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"
echo "=== Workdir: ${workdir} ==="

command -v docker &> /dev/null && have_docker="true" || have_docker="false"

# Functions
function fn_die() {
  echo -e "$1" >&2
  exit "${2:-1}"
}

echo "=== Checking if GITHUB_TOKEN is set ==="
if [ -z "${GITHUB_TOKEN:-}" ]; then
  fn_die "GITHUB_TOKEN variable is not set. Exiting ..."
fi

echo "=== Checking if DOCKER_WRITER_PASSWORD is set ==="
if [ -z "${DOCKER_WRITER_PASSWORD:-}" ]; then
  fn_die "DOCKER_WRITER_PASSWORD variable is not set. Exiting ..."
fi

echo "=== Checking if DOCKER_WRITER_USERNAME is set ==="
if [ -z "${DOCKER_WRITER_USERNAME:-}" ]; then
  fn_die "DOCKER_WRITER_USERNAME variable is not set. Exiting ..."
fi

# Audit, Compile and run Tests
echo "=== Audit, Compile and run Tests ==="
if [ "${have_docker}" = "true" ]; then
  docker build -q \
    -f ci/Dockerfile \
    --build-arg ARG_TEST_IMAGE_NAME="${TEST_IMAGE_NAME}" \
    --build-arg ARG_TEST_IMAGE_VERSION="${TEST_IMAGE_TAG}" \
    -t ci-blockscout:test .
  docker run --rm -t -v "$workdir":/build \
    --entrypoint /build/ci/entrypoint.sh \
    -e LOCAL_USER_ID="$(id -u)" \
    -e LOCAL_GRP_ID="$(id -g)" \
    -e ENABLE_LOGS \
    -e ALLOW_TEST_FAILURES \
    -e ALLOW_AUDIT_FAILURES \
    ci-blockscout:test /build/ci/test.sh
else
  "${workdir:-.}/ci/test.sh"
fi

docker_tag=""
if [ "${IS_A_RELEASE}" = "true" ]; then
  docker_tag="${TRAVIS_TAG}"
elif [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then
  if [ "${TRAVIS_BRANCH}" = "${PROD_RELEASE_BRANCH}" ]; then
    docker_tag=latest
  elif [ "${TRAVIS_BRANCH}" = "${DEV_RELEASE_BRANCH}" ]; then
    docker_tag=dev
  fi
fi

if [ "${docker_tag}" = "" ]; then
  echo "" && echo "=== Feature branch, no Docker image is generated ===" && echo ""
else
  echo "" && echo "=== Building and publishing docker image ===" && echo ""
  echo "$DOCKER_WRITER_PASSWORD" | docker login -u "$DOCKER_WRITER_USERNAME" --password-stdin
  docker build -f "dockerfiles/Dockerfile" -t "${DOCKER_IMAGE_NAME}:${docker_tag}" .
  docker push "${DOCKER_IMAGE_NAME}:${docker_tag}"
fi

# If a release push Release to GitHub
if [ "${IS_A_RELEASE}" = "true" ]; then
  echo "" && echo "=== Generating Release ${TRAVIS_TAG} for ${TRAVIS_REPO_SLUG} ===" && echo ""
  curl -X POST -H "Accept: application/vnd.github+json" -H "Authorization: token ${GITHUB_TOKEN}" https://api.github.com/repos/"${TRAVIS_REPO_SLUG}"/releases -d "{\"tag_name\":\"${TRAVIS_TAG}\",\"generate_release_notes\":true}"
fi
