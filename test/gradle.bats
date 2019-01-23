load functions/core

@test "gradle agent can handle gradle jobs" {
    built_agent gradle
    has_git_repo gradle-hello-world
    gitserver_is_up
    gocd_is_up
    has_docker_agents_plugin_configured
    has_agent_profile
    has_config_repo gradle-hello-world
    sleep 120
    pipeline_status=$(curl --silent http://localhost:8153/go/api/pipelines/mypipe/instance/1 | jq .stages[0].result)
    echo $pipeline_status
    [ "$pipeline_status" == "\"Passed\"" ]
}

teardown() {
    docker rm -f gocd || true
    docker rm -f git || true
    rm -rf ./ssh || true
    rm -rf test/repos/*/.git || true
}
