docker login -u $DOCKERHUB_LOGIN -p $DOCKERHUB_PASSWORD
docker build -t stcarolas/gocd-agent-$AGENT:latest --build-arg AGENT_TYPE=$AGENT .
docker push stcarolas/gocd-agent-$AGENT:latest
