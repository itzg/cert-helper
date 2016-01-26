# cert-helper
A Docker image that helps with self-signed/cluster signed certificate creation for use in other Docker containers

## Usage

Create a volume to be re-used for signing the server, client certs:

   docker volume create --name ca-certs

Initialize the CA certs:

    docker run -it -v ca-certs:/ca itzg/cert-helper init
    
Generate a signed certificate:

    docker volume create --name server-certs
    docker run -it -v ca-certs:/ca:ro -v server-certs:/certs itzg/cert-helper create
