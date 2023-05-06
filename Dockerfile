# Use the alpine image as the base
FROM alpine:latest

# Install dependencies
RUN apk add --no-cache git go protobuf dart

# Install protoc-gen-go and protoc-gen-go-grpc
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.27.1 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1.0

# Install Dart protoc_plugin
RUN pub global activate protoc_plugin

# Set the necessary paths
ENV PATH="/root/go/bin:${PATH}"
ENV PATH="/root/.pub-cache/bin:${PATH}"

# Create a working directory
RUN mkdir /app
WORKDIR /app

# Clone the repository
ARG GIT_REPO_URL
ARG GIT_USER
ARG GIT_EMAIL
ARG GIT_CREDENTIAL_HELPER_SCRIPT
RUN git config --global user.name "${GIT_USER}" && \
    git config --global user.email "${GIT_EMAIL}" && \
    git config --global credential.helper "${GIT_CREDENTIAL_HELPER_SCRIPT}" && \
    git clone "${GIT_REPO_URL}" .

# Build the .proto files
RUN mkdir -p generated && \
    find . -name '*.proto' -exec protoc \
    --proto_path=. \
    --go_out=generated --go_opt=paths=source_relative \
    --go-grpc_out=generated --go-grpc_opt=paths=source_relative \
    --dart_out=grpc:generated \
    {} +

# Commit and push the generated files
RUN git add -A && \
    git commit -m "Generated Go and Dart files from .proto files" && \
    git push
