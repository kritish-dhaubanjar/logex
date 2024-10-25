#!/usr/bin/env bats

@test "Display help message" {
  run ./logex.sh --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: logex"* ]]
}


@test "Update logex script" {
  skip "Update functionality is tested manually"
  run ./logex.sh --update
  [ "$status" -eq 0 ]
}

# Add more tests
