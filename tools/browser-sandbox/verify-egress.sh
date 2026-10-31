#!/usr/bin/env bash
# Proves the browser sandbox: the app is reachable, everything else is not.
# Uses the same image as the MCP server, so the test runs in the browser's own environment.
set -u

NETWORK=invoice-browser-sandbox
IMAGE=mcr.microsoft.com/playwright/mcp:v0.0.83
failures=0

probe() {
  local expectation="$1" url="$2" outcome
  if docker run --rm --network "$NETWORK" --entrypoint node "$IMAGE" -e \
    "fetch('$url',{signal:AbortSignal.timeout(5000)}).then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))" \
    >/dev/null 2>&1; then outcome=reachable; else outcome=blocked; fi

  if [ "$outcome" = "$expectation" ]; then
    echo "PASS  $url is $outcome"
  else
    echo "FAIL  $url is $outcome, expected $expectation"
    failures=$((failures + 1))
  fi
}

probe reachable http://app:5000/
probe blocked   https://example.com
probe blocked   http://1.1.1.1
probe blocked   http://host.docker.internal:5000

[ "$failures" -eq 0 ] && echo "Egress restriction holds." || { echo "$failures check(s) failed."; exit 1; }
