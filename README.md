# docker_build_proto
Builds an minimal Alpine Image for providing Protoc and language specific plugins.
The plugins are built from source and copied from the defined Build Stages.
This results in a minimal image footprint < 100M.
The resulting image can then be used to automatically build proto files for the given languages.
