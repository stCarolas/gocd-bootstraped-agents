load functions/core

@test "node_v8_15_0 agent can handle node jobs" {
    built_agent node_v8_15_0
    has_git_repo node-hello-world
    gitserver_is_up
    gocd_is_up
    has_docker_agents_plugin_configured
    has_agent_profile
    has_config_repo node-hello-world
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
