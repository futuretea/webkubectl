FROM golang:1.18-alpine as gotty-build

ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GO111MODULE=on

WORKDIR /tmp
COPY gotty gotty
RUN apk add --update git make && \
  cd gotty && \
  make gotty && cp gotty / && ls -l /gotty && /gotty -v


FROM alpine:3.20.2

USER root

COPY --from=gotty-build /gotty /usr/bin/
RUN ARCH=$(uname -m) && case $ARCH in aarch64) ARCH="arm64";; x86_64) ARCH="amd64";; esac && echo "ARCH: " $ARCH && \
    apk update && apk upgrade && apk add --update --no-cache bash bash-completion curl git wget openssl iputils busybox-extras vim fzf jq python3 ansible && sed -i "s/nobody:\//nobody:\/nonexistent/g" /etc/passwd && \
    curl -sLf https://storage.googleapis.com/kubernetes-release/release/v1.30.3/bin/linux/${ARCH}/kubectl > /usr/bin/kubectl && chmod +x /usr/bin/kubectl && \
    git clone --branch master --depth 1 https://github.com/ahmetb/kubectl-aliases /opt/kubectl-aliases && chmod -R 755 /opt/kubectl-aliases && \
    cd /tmp/ && wget https://github.com/derailed/k9s/releases/download/v0.32.5/k9s_Linux_${ARCH}.tar.gz && tar -xvf k9s_Linux_${ARCH}.tar.gz && chmod +x k9s && mv k9s /usr/bin && \
    ARCH=$(uname -m) && case $ARCH in aarch64) ARCH="arm64";; x86_64) ARCH="x86_64";; esac && echo "ARCH: " $ARCH && \
    KUBECTX_VERSION=v0.9.5 && wget https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_${ARCH}.tar.gz && tar -xvf kubens_${KUBECTX_VERSION}_linux_${ARCH}.tar.gz && chmod +x kubens && mv kubens /usr/bin && \
    wget https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_${ARCH}.tar.gz && tar -xvf kubectx_${KUBECTX_VERSION}_linux_${ARCH}.tar.gz && chmod +x kubectx && mv kubectx /usr/bin && \
    curl -L https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash && \
    chmod +x /usr/bin/gotty && chmod 555 /bin/busybox && \
    apk del git && rm -rf /tmp/* /var/tmp/* /var/cache/apk/* && \
    chmod -R 755 /tmp && mkdir -p /opt/webkubectl

RUN ARCH=$(uname -m) && case $ARCH in aarch64) ARCH="arm64";; x86_64) ARCH="x86_64";; esac && echo "ARCH: " $ARCH && \
    KUBECAPACITY_VERSION=v0.8.0 && wget https://github.com/robscott/kube-capacity/releases/download/${KUBECAPACITY_VERSION}/kube-capacity_${KUBECAPACITY_VERSION}_linux_${ARCH}.tar.gz && tar -xvf kube-capacity_${KUBECAPACITY_VERSION}_linux_${ARCH}.tar.gz && chmod +x kube-capacity && mv kube-capacity /usr/bin/kubectl-capacity && \
    KUBEIEXEC_VERSION=v1.19.14 && wget https://github.com/gabeduke/kubectl-iexec/releases/download/${KUBEIEXEC_VERSION}/kubectl-iexec_${KUBEIEXEC_VERSION}_Linux_${ARCH}.tar.gz && tar -xvf kubectl-iexec_${KUBEIEXEC_VERSION}_Linux_${ARCH}.tar.gz && chmod +x kubectl-iexec && mv kubectl-iexec /usr/bin/kubectl-iexec
RUN ARCH=$(uname -m) && case $ARCH in aarch64) ARCH="arm64";; x86_64) ARCH="amd64";; esac && echo "ARCH: " $ARCH && \
    KUBETAIL_VERSION=1.6.20 && wget https://raw.githubusercontent.com/johanhaleby/kubetail/${KUBETAIL_VERSION}/kubetail && chmod +x kubetail && mv kubetail /usr/bin && \
    KRUISE_VERSION=v1.1.7 && wget https://github.com/openkruise/kruise-tools/releases/download/${KRUISE_VERSION}/kubectl-kruise-linux-${ARCH}-${KRUISE_VERSION}.tar.gz && tar -xvf kubectl-kruise-linux-${ARCH}-${KRUISE_VERSION}.tar.gz && chmod +x linux-${ARCH}/kubectl-kruise && mv linux-${ARCH}/kubectl-kruise /usr/bin/kubectl-kruise && \
    KUBELINEAGE_VERSION=v0.5.0-harvester && wget https://github.com/futuretea/kube-lineage/releases/download/${KUBELINEAGE_VERSION}/kube-lineage_linux_${ARCH}.tar.gz && tar -xvf kube-lineage_linux_${ARCH}.tar.gz && chmod +x kube-lineage && mv kube-lineage /usr/bin/kubectl-lineage && \
    KUBECTL_NODE_MAINTAIN_VERSION=0.0.2 && wget https://github.com/futuretea/kubectl-node-maintain/releases/download/v${KUBECTL_NODE_MAINTAIN_VERSION}/kubectl-node-maintain_${KUBECTL_NODE_MAINTAIN_VERSION}_linux_${ARCH}.tar.gz && tar -xvf kubectl-node-maintain_${KUBECTL_NODE_MAINTAIN_VERSION}_linux_${ARCH}.tar.gz && chmod +x kubectl-node-maintain && mv kubectl-node-maintain /usr/bin/kubectl-node-maintain && \
    HARVESTER_INVENTORY_VERSION=v0.1.2 && wget https://github.com/futuretea/harvester-inventory/releases/download/${HARVESTER_INVENTORY_VERSION}/harvester-inventory-amd64.tar.gz && tar -xvf harvester-inventory-amd64.tar.gz && chmod +x harvester-inventory && mv harvester-inventory /usr/bin/harvester-inventory

COPY vimrc.local /etc/vim
COPY start-webkubectl.sh /opt/webkubectl
COPY start-session.sh /opt/webkubectl
COPY init-kubectl.sh /opt/webkubectl
RUN chmod -R 700 /opt/webkubectl /usr/bin/gotty


ENV SESSION_STORAGE_SIZE=10M
ENV WELCOME_BANNER="Welcome to Web Kubectl, try kubectl --help."
ENV KUBECTL_INSECURE_SKIP_TLS_VERIFY=true
ENV GOTTY_OPTIONS="--port 8080 --permit-write --permit-arguments"

CMD ["sh","/opt/webkubectl/start-webkubectl.sh"]
