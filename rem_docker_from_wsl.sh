#!/bin/bash

docker_bin=$(which docker 2>/dev/null)

if [[ -n "$docker_bin" ]]; then
    docker_dir=$(dirname "$docker_bin")
    export PATH=$(printf "%s" "$PATH" | tr ':' '\n' | grep -v "^$docker_dir\$" | paste -sd ':' -)
    source ~/.bashrc
fi
