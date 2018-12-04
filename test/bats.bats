load functions/core

@test "bats agent can run bats tests" {
    built_agent bats
    has_git_repo bats-test-pipeline
    gitserver_is_up
    gocd_is_up
    has_docker_agents_plugin_configured
    has_gradle_agent_profile
    has_config_repo bats-test-pipeline
    sleep 120
    pipeline_status=$(curl --silent http://localhost:8153/go/api/pipelines/mypipe/instance/1 | jq .stages[0].result)
    echo $pipeline_status
    [ "$pipeline_status" == "\"Passed\"" ]
}

teardown() {
    echo "tear down"
    docker rm -f gocd || true
    docker rm -f git || true
    rm -rf ./ssh || true
    rm -rf test/repos/*/.git || true
}
