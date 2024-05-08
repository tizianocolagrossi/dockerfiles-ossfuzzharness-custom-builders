
docker build -t <tag>  .
DOCKER_BUILDKIT=1 docker build -t builder-enumetric --ssh default=$HOME/.ssh/id_ed25519 .

docker run -it --rm exivtest:latest 

## build
docker run -v /home/tiziano/oss-targets/exiv2/out/:/out -t test/exiv2
## run
docker run -v <fuzzer-build-dir>:/out -v <fuzzer-out-directory>:/fuzz_out --cpuset-cpus=<cpu-id> -e FUZZING_ENGINE=libafl -e TIMEOUT=<max-time> -t oss-base-runner run_fuzzer <fuzzer-name>