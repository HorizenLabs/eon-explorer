#!/bin/bash

set -eEuo pipefail

echo "" && echo "=== Generating secret key base ===" && echo ""

command="cd /build && MIX_ENV=test mix local.hex --force"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"

command="cd /build && MIX_ENV=test mix phx.gen.secret"
echo "" && echo "====> Running: ${command}" && echo ""
eval "${command}"
