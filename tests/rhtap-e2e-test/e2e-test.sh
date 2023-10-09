#!/bin/bash
#
# Copyright 2022 The Sigstore Authors.
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

set -e
testdir=$(dirname "$0")

echo "installing gocovmerge"
make gocovmerge

echo "building CLI and server"
dir=$(git rev-parse --show-toplevel)
go test -c ./cmd/rekor-cli -o rekor-cli -cover -covermode=count -coverpkg=./...
go test -c ./cmd/rekor-server -o rekor-server -covermode=count -coverpkg=./...

echo "running tests"
REKORTMPDIR="$(mktemp -d -t rekor_test.XXXXXX)"
cp $dir/rekor-cli $REKORTMPDIR/rekor-cli
touch $REKORTMPDIR.rekor.yaml
trap "rm -rf $REKORTMPDIR" EXIT
if ! REKORTMPDIR=$REKORTMPDIR go test  -tags=e2e $(go list ./... | grep -v ./tests) ; then
   exit 1
fi

echo "generating code coverage"
# merging coverage reports and filtering out /pkg/generated from final report
hack/tools/bin/gocovmerge /tmp/pkg-rekor-*.cov | grep -v "/pkg/generated/" > /tmp/pkg-rekor-merged.cov
echo "code coverage $(go tool cover -func=/tmp/pkg-rekor-merged.cov | grep -E '^total\:' | sed -E 's/\s+/ /g')"
