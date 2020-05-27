#!/usr/bin/env bash
set -x
test_future_perfection() {
    echo "nothing up my sleeve"
    {
        # set -x
        type jq openssl
        # set +x
    } && true
}

test_openssl() {
    openssl_sh
}

test_libressl() {
    libressl_sh
}

source libressl.sh
