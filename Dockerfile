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

FROM registry.access.redhat.com/ubi9/go-toolset@sha256:52ab391730a63945f61d93e8c913db4cc7a96f200de909cd525e2632055d9fa6 AS builder
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

# Multi-Stage production build
FROM registry.access.redhat.com/ubi9/go-toolset@sha256:52ab391730a63945f61d93e8c913db4cc7a96f200de909cd525e2632055d9fa6 as deploy

LABEL description="Rekor provides an immutable tamper resistant ledger of metadata generated within a software projects supply chain."
LABEL io.k8s.description="Rekor provides an immutable tamper resistant ledger of metadata generated within a software projects supply chain."
LABEL io.k8s.display-name="Rekor container image for Red Hat Trusted Signer"
LABEL io.openshift.tags="rekor trusted-signer"
LABEL summary="The rekor-server binary provides an immutable, tamper-resistant log."

# Retrieve the binary from the previous stage
COPY --from=builder /opt/app-root/src/rekor-server /usr/local/bin/rekor-server

# Set the binary as the entrypoint of the container
CMD ["rekor-server", "serve"]

# debug compile options & debugger
FROM registry.access.redhat.com/ubi9/go-toolset@sha256:7e49e105a854749d67e5e02fb4069b48bd50445098c780b7f808cc351dee2589 as debug
RUN go install github.com/go-delve/delve/cmd/dlv@v1.8.0

# overwrite server and include debugger
COPY --from=builder /opt/app-root/src/rekor-server_debug /usr/local/bin/rekor-server

FROM registry.access.redhat.com/ubi9/go-toolset@sha256:7e49e105a854749d67e5e02fb4069b48bd50445098c780b7f808cc351dee2589 as test

USER root

# Extract the x86_64 minisign binary to /usr/local/bin/
RUN curl -LO https://github.com/jedisct1/minisign/releases/download/0.11/minisign-0.11-linux.tar.gz && \
    tar -xzf minisign-0.11-linux.tar.gz minisign-linux/x86_64/minisign -O > /usr/local/bin/minisign && \
    chmod +x /usr/local/bin/minisign && \
    rm minisign-0.11-linux.tar.gz
    
# Create test directory
RUN mkdir -p /var/run/attestations && \
    touch /var/run/attestations/attestation.json && \
    chmod 777 /var/run/attestations/attestation.json

# overwrite server with test build with code coverage
COPY --from=builder /opt/app-root/src/rekor-server_test /usr/local/bin/rekor-server

# Multi-Stage production build
FROM registry.access.redhat.com/ubi9/go-toolset@sha256:7e49e105a854749d67e5e02fb4069b48bd50445098c780b7f808cc351dee2589 as deploy

LABEL description="Rekor provides an immutable tamper resistant ledger of metadata generated within a software projects supply chain."
LABEL io.k8s.description="Rekor provides an immutable tamper resistant ledger of metadata generated within a software projects supply chain."
LABEL io.k8s.display-name="Rekor container image for Red Hat Trusted Signer"
LABEL io.openshift.tags="rekor trusted-signer"
LABEL summary="The rekor-server binary provides an immutable, tamper-resistant log."

# Retrieve the binary from the previous stage
COPY --from=builder /opt/app-root/src/rekor-server /usr/local/bin/rekor-server

# Set the binary as the entrypoint of the container
CMD ["rekor-server", "serve"]
