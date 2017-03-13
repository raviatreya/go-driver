#!/bin/bash 

if [ -z "$PROJECT" ]; then 
    echo "PROJECT environment variable must be set"
    exit 1 
fi

STARTERVOLUME1=${PROJECT}-test-vol1
STARTERVOLUME2=${PROJECT}-test-vol2
STARTERVOLUME3=${PROJECT}-test-vol3
STARTERCONTAINER1=${PROJECT}-test-s1
STARTERCONTAINER2=${PROJECT}-test-s2
STARTERCONTAINER3=${PROJECT}-test-s3
CMD=$1
DOCKERARGS=
STARTERARGS=

# Cleanup
docker rm -f -v $(docker ps -a | grep ${PROJECT}-test | awk '{print $1}') &> /dev/null
docker volume rm -f ${STARTERVOLUME1} ${STARTERVOLUME2} ${STARTERVOLUME3} &> /dev/null

if [ "$CMD" == "start" ]; then
    if [ -z "$ARANGODB" ]; then 
        echo "ARANGODB environment variable must be set"
        exit 1 
    fi

    # Create volumes
    docker volume create ${STARTERVOLUME1} &> /dev/null
    docker volume create ${STARTERVOLUME2} &> /dev/null
    docker volume create ${STARTERVOLUME3} &> /dev/null

    # Setup args 
    if [ -n "$JWTSECRET" ]; then 
        if [ -z "$TMPDIR" ]; then 
            echo "TMPDIR environment variable must be set"
            exit 1 
        fi
        JWTSECRETFILE="$TMPDIR/$PROJECT-jwtsecret"
        echo "$JWTSECRET" > ${JWTSECRETFILE}
        DOCKERARGS="$DOCKERARGS -v $JWTSECRETFILE:/jwtsecret:ro"
        STARTERARGS="$STARTERARGS --jwtSecretFile=/jwtsecret"
    fi 
    if [ "$SSL" == "auto" ]; then 
        STARTERARGS="$STARTERARGS --sslAutoKeyFile"
    fi

    # Start starters 
    docker run -d --name=${STARTERCONTAINER1} --net=host \
        -v ${STARTERVOLUME1}:/data -v /var/run/docker.sock:/var/run/docker.sock $DOCKERARGS arangodb/arangodb-starter \
        --dockerContainer=${STARTERCONTAINER1} --dockerNetHost --masterPort=7000 --ownAddress=127.0.0.1 --docker=${ARANGODB} $STARTERARGS
    docker run -d --name=${STARTERCONTAINER2} --net=host \
        -v ${STARTERVOLUME2}:/data -v /var/run/docker.sock:/var/run/docker.sock $DOCKERARGS arangodb/arangodb-starter \
        --dockerContainer=${STARTERCONTAINER2} --dockerNetHost --masterPort=7000 --ownAddress=127.0.0.1 --docker=${ARANGODB} $STARTERARGS --join=127.0.0.1
    docker run -d --name=${STARTERCONTAINER3} --net=host \
        -v ${STARTERVOLUME3}:/data -v /var/run/docker.sock:/var/run/docker.sock $DOCKERARGS arangodb/arangodb-starter \
        --dockerContainer=${STARTERCONTAINER3} --dockerNetHost --masterPort=7000 --ownAddress=127.0.0.1 --docker=${ARANGODB} $STARTERARGS --join=127.0.0.1
fi