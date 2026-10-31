#!/bin/bash

# upload every image's README.md to Docker Hub (no build, no push) with:
# DOCKERHUB_TOKEN=dckr_pat_xxxxxxxx ./readme-all.sh

for dir in $(find . -type f -name project.sh | sed 's/project\.sh//g' | sort); do
    (cd "$dir" && ./project.sh readme) || echo "FAILED: $dir"
done
