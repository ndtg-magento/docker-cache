#!/bin/bash

set -e

# logging functions
log() {
	local type="$1"; shift
	printf '%s [%s] [Magento Setup]: %s\n' "$(date --rfc-3339=seconds)" "$type" "$*"
}
note() {
	log Note "$@"
}
warn() {
	log Warn "$@" >&2
}
error() {
	log ERROR "$@" >&2
}
