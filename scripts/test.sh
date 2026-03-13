#!/usr/bin/env bash

PLENARY_DIR="/tmp/plenary.nvim"

if [ ! -d "$PLENARY_DIR" ]; then
    echo "Plenary not found in /tmp. Downloading for tests..."
    git clone --depth 1 https://github.com/nvim-lua/plenary.nvim "$PLENARY_DIR"
fi

export PLENARY_PATH="$PLENARY_DIR"

nvim --headless \
    --noplugin \
    -u tests/minimal_init.lua \
    -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}" \
    # -c "qa!"

EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo "SOME TESTS FAILED!"
else
    echo "ALL TESTS PASSED!"
fi

exit $EXIT_CODE
