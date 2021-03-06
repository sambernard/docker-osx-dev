#!/bin/bash
#
# Automated tests for docker-osx-dev

#set -e

# Test file constants
readonly TEST_FOLDER="test-project"
readonly TEST_FILE="test-file"
readonly TEST_FILE_CONTENTS="test file contents"
readonly TEST_IMAGE="gliderlabs/alpine:3.2"

# Console colors
readonly COLOR_INFO='\033[0;3m[TEST_INFO]'
readonly COLOR_WARN='\033[1;33m[TEST_WARN]'
readonly COLOR_ERROR='\033[0;31m[TEST_ERROR]'
readonly COLOR_END='\033[0m'

# Docker Machine constants
readonly VM_NAME='docker-osx-dev-test'

function log_info {
  log "$1" $COLOR_INFO
}

function log_warn {
  log "$1" $COLOR_WARN
}

function log_error {
  log "$1" $COLOR_ERROR
}

function log {
  local readonly message=$1
  local readonly color=$2 || $COLOR_INFO
  echo -e "${color} ${message}${COLOR_END}"
}

function assert_equals {
  local readonly left=$1
  local readonly right=$2

  if [[ "$left" -ne "$right" ]]; then
    echo "Assertion failure: $left != $right"
    exit 1
  fi
}

function cleanup {
  log_info "Cleaning up old test environment"
  if [[ -n $(docker-machine ls | grep -o "^$VM_NAME") ]]; then
    log_info "Removing old machine"
    docker-machine rm "$VM_NAME"
  else
    log_info "No old machine found"
  fi
}

function create_machine {
  log_info "Creating machine"
  docker-machine create "$VM_NAME" --driver=virtualbox
}

function start_machine {
  log_info "Starting machine"
  eval $(docker-machine env "$VM_NAME")
  docker-machine start "$VM_NAME"
}

function test_setup {
  log_info "Testing the install command"
  # We're just looking for the script to run without errors
  ./src/docker-osx-dev install
}

function create_test_project {
  log_info "Creating test project in $TEST_FOLDER"
  mkdir "$TEST_FOLDER"
  cd "$TEST_FOLDER"
  echo "$TEST_FILE_CONTENTS" > "$TEST_FILE"
}


function test_docker_osx_dev {
  log_info "Running docker-osx-dev"

  # This should start syncing in the background
  docker-osx-dev &
}

function test_docker_run {
  log_info "Testing docker run with Alpine Linux image"
  local readonly out=$(docker run --rm $TEST_IMAGE uname)
  assert_equals "$out" "Linux"
}

function test_docker_mount {
  log_info "Testing mounting a folder with Alpine Linux image"
  local readonly out=$(docker run --rm -v $(pwd):/src gliderlabs/alpine:3.2 /bin/sh -c "cat /src/$TEST_FOLDER/$TEST_FILE")
  assert_equals "$out" "$TEST_FILE_CONTENTS"
}

cleanup
create_machine
start_machine
test_setup
create_test_project
test_docker_osx_dev
test_docker_run
test_docker_mount
