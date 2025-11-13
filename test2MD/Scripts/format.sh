#!/usr/bin/env bash
set -euo pipefail

swiftformat "$(dirname "$0")/.." --config "$(dirname "$0")/../.swiftformat"
