#!/usr/bin/env bash

filter_logs() {
    exec grep --line-buffered -vie 'NVIDIA.*found in MITIGATION_RETHUNK build' 2> /dev/null
}

exec "$@" > >(filter_logs) 2> >(filter_logs >&2)
