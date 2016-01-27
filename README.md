# cert-helper
A Docker image that helps with self-signed/cluster signed certificate creation for use in other Docker containers

## Usage

If you plan on creating more than one certificate to be signed by the same CA
it is very important to either attach a host directory to `/ca` or create a
volume to be re-used on subsequent `run` invocations:

To create a volume:

    docker volume create --name ca-certs

### Initialize the CA

Use the `init` command to initialize the `/ca` volume:

    docker run -it -v ca-certs:/ca itzg/cert-helper init

or if you're attaching a host directory called `ca` in the current directory:

    docker run -it -v $(pwd)/ca:/ca itzg/cert-helper init

### Generate a signed certificate

Using a Docker volume to be attached to a server/application container for TLS
usage:

    docker volume create --name server-certs
    docker run -it -v <host volume>:/ca -v server-certs:/certs itzg/cert-helper create

or if you're attaching a host directory called `certs`:

    docker run -it -v <host volume>:/ca -v $(pwd)/certs:/certs itzg/cert-helper create

In both of the above, `<host volume>` is either the explicitly created
volume or the host directory used in the `init` invocation above.

To confirm the content of the created certificate:

    docker run -it -v <ca host volume>:/ca:ro -v <certs host volume>:/certs:ro cert-helper show

Notice the volumes can (and should be) attached **read-only** using the `:ro`
attachment option. This is also how the certificates should be attached to
your server/application container to avoid accidental corruption.


## TODO

**NOTE**: This image does not yet handle re-issuing an expired CA or signed
certificates.
