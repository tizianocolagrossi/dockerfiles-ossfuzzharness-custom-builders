
docker build -t <tag>  .
DOCKER_BUILDKIT=1 docker build -t builder-enumetric --ssh default=$HOME/.ssh/id_ed25519 .

docker run -it --rm exivtest:latest 

## build
docker run -v /home/tiziano/oss-targets/exiv2/out/:/out -t test/exiv2
## run
docker run -v /home/tiziano/oss-targets/exiv2/out/:/out --cpuset-cpus=0 -e FUZZ_OUT_DIR_NAME=test2 -e FUZZING_ENGINE=libafl-baseline -e TIMEOUT=10s -t oss/base-runner run_fuzzer fuzz-read-print-write