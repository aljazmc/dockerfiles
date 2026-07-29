#!/bin/sh
set -e

if [ ! -d /home/aljazmc/.local/share/aws-cli ]; then
    curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash
fi

exec "$@"
