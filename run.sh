#!/bin/bash

set -e

# Close any previous instances of the app
killall "Explorer" || true

./build.sh

# Launch the app
open "Explorer.app"

echo "App launched"