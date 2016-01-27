#!/bin/bash

set -e

KEY_BITS=2048
CERT_DURATION="-days 1825"

init() {
  is_redo=
  while [ $# -gt 0 ]; do
    case $1 in
      -redo)
        is_redo=true
        shift 1 ;;
      *)
        echo "Usage: $0 init [ -redo ]"
        exit 1 ;;
    esac
  done

  if [ "$is_redo" = true ]; then
    rm -f /ca/ca-key.pem /ca/ca.pem
  fi

  openssl req -new -x509 $CERT_DURATION -extensions v3_ca -keyout /ca/ca-key.pem -out /ca/ca.pem
  chmod -c 400 /ca/ca-key.pem
  chmod -c 444 /ca/ca.pem

  echo "
Created CA cert and key in /ca
"
}

check_init() {
  if [ ! -f /ca/ca-key.pem -o ! -f /ca/ca.pem ]; then
    init
  fi
}

create() {
  is_redo=
  is_server=
  is_client=

  if [ $# = 0 ]; then
    echo "
NOTE: use -h to see extra options to use when creating certs
"
  fi

  while [ $# -gt 0 ]; do
    case $1 in
      -cn)
        cn=$2
        shift 2 ;;
      -alt)
        subjectAltName=$2
        shift 2 ;;
      -client)
        is_client=true
        shift 1 ;;
      -server)
        is_server=true
        shift 1 ;;
      -redo)
        is_redo=true
        shift 1 ;;
      -h|-help|--help|*)
        echo "
Usage: $0 create -cn SUBJECT_CN [-alt SUBJECT_ALT_NAME] [-server] [-client] [-redo]

where SUBJECT_ALT_NAME can be values like
        email:copy,email:my@other.address,URI:http://my.url.here/
        IP:192.168.7.1
        otherName:1.2.3.4;UTF8:some other identifier
        subjectAltName=dirName:dir_sect

"
        exit 1
    esac
  done

  check_init

  cd /certs

  if [ -z "$cn" ]; then
    read -p "Subject canonical name: " cn
  fi
  if [ -z "$is_client" -a -z "$is_server" ]; then
    read -n 1 -p "Usage is for (c)lient, (s)erver, or [b]oth: " ans
    case "$ans" in
      c|C)
        is_client=true ;;
      s|S)
        is_server=true ;;
      *)
        is_client=true
        is_server=true
        ;;
    esac
  fi
  if [ "$is_redo" = true ]; then
    rm -f {key,cert,bundle}.pem
  fi

  cnf_file="extfile.$$.cnf"
  trap "rm -f $cnf_file csr" EXIT
  touch $cnf_file

  if [ ! -f cert.pem -o ! -f key.pem ]; then
    openssl req -subj "/CN=$cn" -new -nodes -keyout key.pem -out csr

    echo >> $cnf_file <<END
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
END
    if [ -n "$subjectAltName" ]; then
      if [[ ! $subjectAltName =~ ((email|URI|DNS|RID|IP|dirName|otherName):) ]]; then
        echo "
ERROR: subjectAltName is missing types. See http://bit.ly/subjectAltName
" > /dev/stderr
        exit 2
      fi

      echo "subjectAltName = $subjectAltName" >> $cnf_file
    fi
    if [ "$is_client" = true -a "$is_server" = true ]; then
      echo "extendedKeyUsage = serverAuth,clientAuth" >> $cnf_file
    elif [ "$is_client" = true ]; then
      echo "extendedKeyUsage = clientAuth" >> $cnf_file
    elif [ "$is_server" = true ]; then
      echo "extendedKeyUsage = serverAuth" >> $cnf_file
    fi

    if [ -f $cnf_file ]; then
      ext_arg="-extfile $cnf_file"
    fi

    openssl x509 -req $CERT_DURATION -in csr \
      -CA /ca/ca.pem -CAkey /ca/ca-key.pem \
      -CAserial /ca/ca-serial.dat -CAcreateserial \
      -out cert.pem $ext_arg

    cp /ca/ca.pem ca.pem

    chmod -c 0400 key.pem
  fi

  cat /ca/ca.pem cert.pem > bundle.pem
  chmod -c 0444 cert.pem ca.pem bundle.pem

  echo "
Created key and cert in $(pwd)
"
}

show() {
  echo "
Files:"
  ls /ca /certs

echo ""
  if [ -f cert.pem ]; then
    openssl x509 -in cert.pem -text
  else
    echo NO CERTIFICATE created yet. Use 'create -h' to see how to do that.
  fi
}

case $1 in
  init|create|show)
    cmd="$1"
    shift
    $cmd $@
    ;;
  -h|-help|--help|*)
    echo "Usage: $0 init|create|show"
    ;;
esac
