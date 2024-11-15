#!/bin/bash
# this is meant to be sourced from stepNN-*.sh

clear_text=$(printf '\e[0m')
start_bold=$(printf '\e[1m')
clear_bold=$(printf '\e[22m')
red_color=$(printf '\e[1;31m')
green_color=$(printf '\e[1;32m')
blue_color=$(printf '\e[1;34m')
reset_color=$(printf '\e[1;0m')

params_file="$script_dir/bluesky-params.env"

function show_heading {
  echo
  echo -n "$blue_color""$start_bold"$1 "$clear_bold"
  shift 1
  echo "$@""$clear_text"
  echo
}

function show_error {
  echo -n "$red_color""$start_bold"$1 "$clear_bold"
  shift 1
  echo "$@""$clear_text"
}

function show_success {
  echo "${green_color}OK${reset_color}"
}

function show_failure {
  echo "${red_color}Fail${reset_color}"
}

