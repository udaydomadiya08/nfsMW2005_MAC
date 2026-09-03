#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/launch.sh" "$SCRIPT_DIR" 2>/dev/null || true
