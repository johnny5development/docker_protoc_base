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

# Final stage
FROM alpine:3.14

# Install Git
RUN apk add --no-cache protoc protobuf protobuf-dev
# Create a working directory

# Copy the Go and Dart binaries and libraries from the build stages
COPY --from=dart-builder /runtime/ /
COPY --from=dart-builder /app/protobuf.dart/protoc_plugin/bin/protoc-gen-dart /usr/bin
COPY --from=go-builder /go/bin/protoc-gen-go /usr/bin/protoc-gen-go
COPY --from=go-builder /go/bin/protoc-gen-go-grpc /usr/bin/protoc-gen-go-grpc

# Set the necessary paths for Go and Dart
ENV PATH="/usr/local/go/bin:/usr/bin:${PATH}"
