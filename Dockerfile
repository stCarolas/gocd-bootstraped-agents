FROM docker.io/docker:edge-dind

ARG AGENT_TYPE="gradle"

# The directory and user that'll be used for the gocd agent process. Currently hardcoded in the bootstrapper ;-/
RUN \
    addgroup -g 992 dockerroot && adduser -G dockerroot -h /go go -D \
    && apk add --no-cache git openssh-client bash curl nss
RUN \
    cd /tmp \
    && curl --location -o jdk.tar.gz https://cdn.azul.com/zulu/bin/zulu11.29.11-ca-jdk11.0.2-linux_musl_x64.tar.gz \
    && tar -xzvf jdk.tar.gz \
    && mv zulu* zulu \
    && rm -f jdk.tar.gz \
    && mv zulu /usr/lib/jvm/ \
    && chmod -R 777 /usr/lib/jvm \
    && echo "export PATH=$PATH:/usr/lib/jvm/bin" >> /etc/profile.d/enviroment.sh \
    && echo "export JAVA_HOME=/usr/lib/jvm" >> /etc/profile.d/enviroment.sh

# Download and ensure that the binary is executable
RUN \
    curl --fail --silent --location "https://github.com/ketan/gocd-golang-bootstrapper/releases/download/2.3/go-bootstrapper-2.3.linux.amd64" > /go-agent && \
    chmod 755 /go-agent

ADD data/  /data/
ADD configs/  /configs/
ADD bootstrap  /
ADD scripts/  /scripts/
ADD bootstrap.d/ /bootstrap.d/

RUN /bootstrap

CMD export GO_EA_SSL_NO_VERIFY=true && \
    chmod 777 /etc/profile.d/* && \
    source /etc/profile && \
    (nohup /usr/local/bin/dockerd-entrypoint.sh > /dev/null &) && \
    sleep 5 && \
    /go-agent
