#
# Copyright 2021 The Sigstore Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM registry.access.redhat.com/ubi9/go-toolset@sha256:e91cbbd0b659498d029dd43e050c8a009c403146bfba22cbebca8bcd0ee7925f AS builder
ENV APP_ROOT=/opt/app-root
ENV GOPATH=$APP_ROOT

WORKDIR $APP_ROOT/src/
ADD go.mod go.sum $APP_ROOT/src/
RUN go mod download

# Add source code
ADD ./cmd/ $APP_ROOT/src/cmd/
ADD ./pkg/ $APP_ROOT/src/pkg/

ARG SERVER_LDFLAGS
RUN go build -ldflags "${SERVER_LDFLAGS}" ./cmd/rekor-server
RUN CGO_ENABLED=0 go build -gcflags "all=-N -l" -ldflags "${SERVER_LDFLAGS}" -o rekor-server_debug ./cmd/rekor-server
RUN go test -c -ldflags "${SERVER_LDFLAGS}" -cover -covermode=count -coverpkg=./... -o rekor-server_test ./cmd/rekor-server

# debug compile options & debugger
FROM registry.access.redhat.com/ubi9/go-toolset@sha256:e91cbbd0b659498d029dd43e050c8a009c403146bfba22cbebca8bcd0ee7925f as debug
RUN go install github.com/go-delve/delve/cmd/dlv@v1.8.0

# overwrite server and include debugger
COPY --from=builder /opt/app-root/src/rekor-server_debug /usr/local/bin/rekor-server

FROM registry.access.redhat.com/ubi9/go-toolset@sha256:e91cbbd0b659498d029dd43e050c8a009c403146bfba22cbebca8bcd0ee7925f as test

USER root

# Install minisign
RUN curl -LO https://github.com/aead/minisign/releases/download/v0.2.0/minisign-linux-amd64.tar.gz && \
    tar -xzf minisign-linux-amd64.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/minisign && \
    rm minisign-linux-amd64.tar.gz

# Install Docker
RUN yum install -y yum-utils && \
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo && \
    yum install -y docker-ce docker-ce-cli containerd.io

# Install netcat
RUN yum install -y nmap-ncat

RUN mkdir -p /var/run/attestations && \
    touch /var/run/attestations/attestation.json && \
    chmod 777 /var/run/attestations/attestation.json

# overwrite server with test build with code coverage
COPY --from=builder /opt/app-root/src/rekor-server_test /usr/local/bin/rekor-server

# Multi-Stage production build
FROM registry.access.redhat.com/ubi9/go-toolset@sha256:e91cbbd0b659498d029dd43e050c8a009c403146bfba22cbebca8bcd0ee7925f as deploy

LABEL description="Rekor provides an immutable tamper resistant ledger of metadata generated within a software projects supply chain."
LABEL io.k8s.description="Rekor provides an immutable tamper resistant ledger of metadata generated within a software projects supply chain."
LABEL io.k8s.display-name="Rekor container image for Red Hat Trusted Signer"
LABEL io.openshift.tags="rekor trusted-signer"
LABEL summary="The rekor-server binary provides an immutable, tamper-resistant log."

# Retrieve the binary from the previous stage
COPY --from=builder /opt/app-root/src/rekor-server /usr/local/bin/rekor-server

# Set the binary as the entrypoint of the container
CMD ["rekor-server", "serve"]
