#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "nomos version" nomos version

reportResults
