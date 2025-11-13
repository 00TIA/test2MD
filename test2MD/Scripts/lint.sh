#!/usr/bin/env bash
set -euo pipefail

swiftlint --config "$(dirname "$0")/../.swiftlint.yml"
