#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
readonly GRAFANA_BASE_URL="${GRAFANA_BASE_URL:-http://localhost:3000}"

info() {
    local MESSAGE="${1}"

    echo "${MESSAGE}"
}

fail() {
    local MESSAGE="${1}"
    local EXIT_CODE="${2:-1}"

    echo "${MESSAGE}"
    exit "${EXIT_CODE}"
}

wait_for_url() {
    declare url="$1" max_retries="${2:-100}"
    for _ in $(seq 1 "${max_retries}"); do
        wget -O /dev/null -q "${url}" \
            && return 0

        sleep 1
    done

    return 1  # fail if we didn't return earlier
}

add_data_sources() {
    for data_source_file in ${SCRIPT_DIR}/configuration/data_sources/*.json; do
        wget -O /dev/null -q \
            --header 'Content-Type: application/json;charset=UTF-8' \
            --post-file "${data_source_file}" \
            "${GRAFANA_BASE_URL}/api/datasources"
    done
}

main() {
    info "Waiting for Grafana..."

    if ! wait_for_url "${GRAFANA_BASE_URL}"; then
        fail "Failed to connect to Grafana at ${GRAFANA_BASE_URL}"
    fi

    info "Adding data sources..."

    if ! add_data_sources; then
        fail "Failed to add data sources..."
    fi

    info "Finished successfully"

    exec sleep infinity  # sleep to keep other processes in the container alive
}

main
