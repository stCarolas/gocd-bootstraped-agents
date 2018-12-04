load functions/core

@test "image successfully builds with default args" {
    run docker build . -t test
    [ "$status" -eq 0 ]
    echo $output | grep -q "Successfully built"
}

@test "image with default args can connect to gocd server" {
    gocd_is_up
    agent_is_up
    run curl --silent 'http://localhost:8153/go/api/admin/config.xml'
    [ "$status" -eq 0 ]
    echo $output | grep -q "elasticAgentId=\"test_id\""
}

teardown() {
    docker rm -f gocd-agent || true
    docker rm -f gocd || true
    docker rm -f git || true
}
