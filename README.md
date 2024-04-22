
docker build -t <tag>  .
DOCKER_BUILDKIT=1 docker build -t builder-enumetric --ssh default=$HOME/.ssh/id_ed25519 .

docker run -it --rm exivtest:latest 
