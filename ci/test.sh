#!/bin/bash

set -eEuo pipefail

# Required test.sh script vars
ALLOW_AUDIT_FAILURES="${ALLOW_AUDIT_FAILURES:-false}"
ALLOW_TEST_FAILURES="${ALLOW_TEST_FAILURES:-false}"
ENABLE_LOGS="${ENABLE_LOGS:-true}"
NULL_REDIRECT="$( [ "$ENABLE_LOGS" == "false" ] && echo ' &> /dev/null' || echo '' )"

# Required runtime vars
export CHAIN_ID=77
export ETHEREUM_JSONRPC_CASE=EthereumJSONRPC.Case.Nethermind.Mox
export ETHEREUM_JSONRPC_WEB_SOCKET_CASE=EthereumJSONRPC.WebSocket.Case.Mox
export API_V2_ENABLED=true
export API_RATE_LIMIT_DISABLED=true

echo "" && echo "=== Compile Elixir code and Audit Elixir dependencies ===" && echo ""

command="cd /build && MIX_ENV=test mix local.hex --force ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"

command="cd /build && MIX_ENV=test mix do deps.get, local.rebar --force, deps.compile, compile ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"

command="cd /build && MIX_ENV=test mix format ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"

command="cd /build && MIX_ENV=test mix credo --strict ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_AUDIT_FAILURES}" = "true" ] && true || false; }

command="cd /build && MIX_ENV=test mix dialyzer ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_AUDIT_FAILURES}" = "true" ] && true || false; }

command="cd /build/apps/explorer && MIX_ENV=test mix sobelow --config ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_AUDIT_FAILURES}" = "true" ] && true || false; }

command="cd /build/apps/block_scout_web && MIX_ENV=test mix sobelow --config ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_AUDIT_FAILURES}" = "true" ] && true || false; }

echo "" && echo "=== Compile Nodejs code and Audit npm dependencies ===" && echo ""

command="cd /build/apps/explorer && npm ci ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"

command="cd /build/apps/explorer && npm audit --omit=dev --audit-level=high ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_AUDIT_FAILURES}" = "true" ] && true || false; }

command="cd /build/apps/block_scout_web/assets && npm ci ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"

command="cd /build/apps/block_scout_web/assets && npm audit --omit=dev --audit-level=high ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_AUDIT_FAILURES}" = "true" ] && true || false; }

command="cd /build/apps/block_scout_web/assets && npm run build ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"

command="cd /build/apps/block_scout_web/assets && npm run eslint ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_AUDIT_FAILURES}" = "true" ] && true || false; }

echo "" && echo "=== Running tests ===" && echo ""

command="cd /build/apps/block_scout_web/assets && npm run test ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_TEST_FAILURES}" = "true" ] && true || false; }

command="cd /build && MIX_ENV=test mix do ecto.create --quiet, ecto.migrate --quiet ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"

command="cd /build/apps/indexer && MIX_ENV=test mix test --exclude no_nethermind --no-start ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_TEST_FAILURES}" = "true" ] && true || false; }

command="cd /build/apps/explorer && MIX_ENV=test mix test --no-start ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_TEST_FAILURES}" = "true" ] && true || false; }

command="cd /build/apps/block_scout_web && MIX_ENV=test mix test --no-start ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_TEST_FAILURES}" = "true" ] && true || false; }

command="cd /build/apps/ethereum_jsonrpc && MIX_ENV=test mix test --exclude no_nethermind --no-start ${NULL_REDIRECT}"
echo "" && echo "====> Running: ${command}" && echo ""
# shellcheck disable=SC2015
eval "${command}" || { [ "${ALLOW_TEST_FAILURES}" = "true" ] && true || false; }
