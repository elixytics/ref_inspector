#!/usr/bin/env bash
cd "${TRAVIS_BUILD_DIR}/verify"

mix compile
mix ref_inspector.yaml.download --force
mix ref_inspector.verify
