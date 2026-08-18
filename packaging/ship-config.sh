#!/bin/bash
# Shared paths for the engine/driver pair used by shipping and validation.
# Keep these defaults in the repository so `make app` works from a clean clone.
# Environment overrides remain available for CI lanes and local experiments.

SHIP_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BAR="${BAR:-$(cd "$SHIP_CONFIG_DIR/.." && pwd)}"

# The release package must contain the same engine and Mesa pair that the
# release gates validate. build-engine.sh builds the driver automatically when
# this prefix is missing or stale.
SHIP_ENGINE_BUILD="${SHIP_ENGINE_BUILD:-$BAR/build-engine}"
SHIP_MESA_PREFIX="${SHIP_MESA_PREFIX:-$BAR/deps/mesa-native-release}"