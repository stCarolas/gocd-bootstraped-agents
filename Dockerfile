ARG PRIVATE_REPO=""
FROM ${PRIVATE_REPO}docker:dind

ARG GO_BOOTSTRAPPER_URL="https://github.com/ketan/gocd-golang-bootstrapper/releases/download/2.3/go-bootstrapper-2.3.linux.amd64"
ARG AGENT_TYPE="gradle"

# The directory and user that'll be used for the gocd agent process. Currently hardcoded in the bootstrapper ;-/
RUN \
    addgroup -g 992 dockerroot && adduser -G dockerroot -h /go go -D \
    && apk add --no-cache openjdk8-jre-base git mercurial subversion openssh-client bash curl

# Download and ensure that the binary is executable
RUN \
    curl --fail --silent --location ${GO_BOOTSTRAPPER_URL} > /go-agent && \
    chmod 755 /go-agent

ADD data/  /data/
ADD configs/  /configs/
ADD scripts/$AGENT_TYPE  /scripts/
ADD bootstrap.d/ /bootstrap.d/

RUN chmod -R 777 /bootstrap.d/ && \
    PATH=$PATH:/bootstrap.d/ && \
    for file in $(cat /configs/${AGENT_TYPE}); do echo "Start runnig $file:" && "$file" && echo "End running $file"; done

CMD export GO_EA_SSL_NO_VERIFY=true && \
    (nohup /usr/local/bin/dockerd-entrypoint.sh > /dev/null &) && \
    sleep 5 && \
    /go-agent
