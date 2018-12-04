gocd_is_up() {
    tmp_dir="/tmp/gocd-server"
    _ensure_has_tmp_dir $tmp_dir
    cp -r ~/.ssh $tmp_dir

    docker rm -f gocd || true
    docker run -d \
        -p 8153:8153 -p 8154:8154 \
        -v $tmp_dir:/home/go \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e GOCD_PLUGIN_INSTALL_docker-elastic-agents=https://github.com/gocd-contrib/docker-elastic-agents/releases/download/v1.0.2/docker-elastic-agents-1.0.2-143.jar \
        --name gocd \
        gocd/gocd-server:v18.9.0
    sleep 120
}

_get_gocd_address() {
    docker inspect \
        --format='{{(index (index .NetworkSettings.IPAddress))}}' \
        gocd 
}

_get_git_address() {
    docker inspect \
        --format='{{(index (index .NetworkSettings.IPAddress))}}' \
        git
}

_get_access_token() {
    curl 'http://localhost:8153/go/api/admin/config.xml' \
        | grep -E -o "agentAutoRegisterKey=\"[0-9a-z\-]*\"" \
        | sed "s/agentAutoRegisterKey=\"\([0-9a-z\-]*\)\"/\1/g"
}

_ensure_has_tmp_dir() {
    local target=$1
    if [ -d $target ]
    then
        rm -rf $target
    fi
    mkdir $target
}

agent_is_up() {
    tmp_dir="/tmp/gocd-agent"
    _ensure_has_tmp_dir $tmp_dir
    cp -r ~/.ssh $tmp_dir

    docker rm -f gocd-agent || true
    docker rmi gocd-agent || true
    docker build . -t gocd-agent
    token=$(_get_access_token)
    address=$(_get_gocd_address)
    docker run -d \
        -e GO_EA_SSL_NO_VERIFY="true" \
        -e GO_EA_AUTO_REGISTER_KEY=$token \
        -e GO_EA_AUTO_REGISTER_ELASTIC_AGENT_ID=test_id \
        -e GO_EA_AUTO_REGISTER_ELASTIC_PLUGIN_ID=bats-test \
        -e GO_EA_SERVER_URL="https://$address:8154/go" \
        -v $tmp_dir:/go \
        --name gocd-agent \
        gocd-agent
    sleep 5
}

built_agent() {
    local agent_type=$1

    docker build . -t gocd-agent --build-arg AGENT_TYPE=$agent_type
    cp -r ~/.ssh ssh
    cp -f data/config ssh/config
    docker build . -f Dockerfile-test -t gocd-agent-test
}

has_config_repo() {
    local repo=$1

    docker exec gocd su go -c "ssh-keyscan -H $(_get_git_address) >> ~/.ssh/known_hosts"

    curl "http://$(_get_gocd_address):8153/go/api/admin/config_repos" \
        -H 'Accept:application/vnd.go.cd.v1+json' \
        -H 'Content-Type:application/json' \
        -X POST -d '{
    "id": "repo",
    "plugin_id": "yaml.config.plugin",
    "material": {
        "type": "git",
        "attributes": {
            "url": "ssh://git@'$(_get_git_address)':22/git-server/repos/'$repo'.git",
            "name": null,
            "branch": "master",
            "auto_update": true
        }
    }
}'
}

has_docker_agents_plugin_configured() {
    echo "gocd_ip: $(_get_gocd_address)" > /tmp/data
    mustache /tmp/data test/files/docker_plugin_settings > /tmp/request
    curl "http://$(_get_gocd_address):8153/go/api/admin/plugin_settings" \
        -H 'Accept: application/vnd.go.cd.v1+json' \
        -H 'Content-Type:application/json' \
        -X POST -d @/tmp/request
}

has_gradle_agent_profile() {
    curl "http://$(_get_gocd_address):8153/go/api/elastic/profiles" \
        -H 'Accept: application/vnd.go.cd.v1+json' \
        -H 'Content-Type:application/json' \
        -X POST -d @test/files/agent_profile
}

has_git_repo() {
    local repo=$1

    tmp_dir="/tmp/git"
    _ensure_has_tmp_dir $tmp_dir

    repos_dir="/tmp/git/repos"
    _ensure_has_tmp_dir $repos_dir

    cd test/repos/$repo
    rm -rf .git
    git init --shared=true
    git add .
    git commit -m "my first commit"
    cd ../../..
    git clone --bare test/repos/$repo $repos_dir/$repo.git
}

gitserver_is_up() {
    keys_dir="/tmp/git/keys"
    _ensure_has_tmp_dir $keys_dir
    cp ~/.ssh/* $keys_dir

    docker rm -f git || true
    docker run -d \
        -p 2222:22 \
        -v $keys_dir:/git-server/keys \
        -v $repos_dir:/git-server/repos \
        --name git \
        jkarlos/git-server-docker
    sleep 5
}
