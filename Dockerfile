FROM golang:1.17-alpine3.14 as go-builder

# Install dependencies
RUN apk add --no-cache git protobuf

# Clone and build protoc-gen-go
WORKDIR /app
RUN git clone https://github.com/protocolbuffers/protobuf-go.git /app/protoc-gen-go
WORKDIR /app/protoc-gen-go/cmd/protoc-gen-go
RUN go build -o /go/bin/protoc-gen-go .

# Clone and build protoc-gen-go-grpc
WORKDIR /app
RUN git clone https://github.com/grpc/grpc-go.git
WORKDIR /app/grpc-go/cmd/protoc-gen-go-grpc
RUN go build -o /go/bin/protoc-gen-go-grpc .

# Dart build stage
FROM dart:stable as dart-builder
RUN mkdir /app
WORKDIR /app
RUN apt-get update && apt-get install -y git
RUN git clone https://github.com/google/protobuf.dart.git
WORKDIR /app/protobuf.dart/protoc_plugin
RUN dart pub get
RUN dart compile exe bin/protoc_plugin.dart -o bin/protoc-gen-dart
RUN chmod +x bin/protoc-gen-dart

# Java build stage
FROM openjdk:11-jdk-slim as java-builder
WORKDIR /app
RUN apt-get update && apt-get install -y git protobuf-compiler build-essential
RUN git clone https://github.com/grpc/grpc-java.git
WORKDIR /app/grpc-java
RUN ./gradlew java_pluginExecutable -PskipAndroid=true
RUN mv ./compiler/build/exe/java_plugin/protoc-gen-grpc-java /usr/local/bin


# Python build stage
FROM python:3.9-slim as python-builder
WORKDIR /app
RUN apt-get update && apt-get install -y git protobuf-compiler
RUN git clone https://github.com/grpc/grpc.git
WORKDIR /app/grpc
RUN git submodule update --init
RUN make grpc_python_plugin
RUN mv ./bins/opt/grpc_python_plugin /usr/local/bin/protoc-gen-grpc-python

# Final stage
FROM alpine:3.14

# Install Git
RUN apk add --no-cache protoc protobuf protobuf-dev
# Create a working directory

# Copy the Go and Dart binaries and libraries from the build stages
# Dart comes with its own runtime, so we copy that as well
# We only use the base runtime; the rest of the libraries are not needed

COPY --from=dart-builder /runtime/ /
COPY --from=dart-builder /app/protobuf.dart/protoc_plugin/bin/protoc-gen-dart /usr/bin
COPY --from=go-builder /go/bin/protoc-gen-go /usr/bin/protoc-gen-go
COPY --from=go-builder /go/bin/protoc-gen-go-grpc /usr/bin/protoc-gen-go-grpc
COPY --from=java-builder /usr/local/bin/protoc-gen-grpc-java /usr/bin
COPY --from=python-builder /usr/local/bin/protoc-gen-grpc-python /usr/bin

# Set the necessary paths for Go and Dart
ENV PATH="/usr/local/go/bin:/usr/bin:${PATH}"
