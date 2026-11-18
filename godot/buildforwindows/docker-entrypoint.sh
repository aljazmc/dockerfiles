#!/bin/bash
set -e

if [ "$#" -gt 0 ]; then
    exec bash -c "$*"
fi
