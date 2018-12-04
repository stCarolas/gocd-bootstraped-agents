@test "gradle agent can handle gradle jobs" {
  run echo true
  [ "$status" -eq 0 ]
}
