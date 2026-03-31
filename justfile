default:
  @just --list

all:
  #! /usr/bin/env bash
  echo "NOT IMPLEMENTED!"
  exit 1

run target:
  brew bundle exec esphome run "./{{target}}.yml"

compile target:
  brew bundle exec esphome compile "./{{target}}.yml"

compress target: (compile target)
  gzip -fk ".esphome/build/{{target}}/.pioenvs/{{target}}/firmware.bin"

dist target: (compress target)
  cp ".esphome/build/{{target}}/.pioenvs/{{target}}/firmware.bin.gz" "./dist/{{target}}.bin.gz"
