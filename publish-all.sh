#!/bin/bash

# build every image in this repository, push it and upload its README.md to Docker Hub

for dir in $(find . -type f -name project.sh | sed 's/project\.sh//g' | sort); do
    (cd "$dir" && ./project.sh combo && ./project.sh publish) || echo "FAILED: $dir"
done
