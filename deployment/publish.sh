cd configs
docker login -u $DOCKERHUB_LOGIN -p $DOCKERHUB_PASSWORD
for file in *
do
  docker build -t stcarolas/gocd-agent-$file:latest --build-arg AGENT_TYPE=$file ../
  docker push stcarolas/gocd-agent-$file:latest
done
