#!/bin/bash
set -eo pipefail

# Set APPDIR
CURRENTDIR=$(pwd)
APPDIR=$(dirname $CURRENTDIR)
INDEXER="explorer_indexer"
WEBAPP="explorer_webapp"
WEBAPPIMAGE="769325152790.dkr.ecr.us-west-2.amazonaws.com/${WEBAPP}"
if [[ -z $CI_COMMIT_SHA ]]
then
    CI_COMMIT_SHA=bs123456
fi

if [[ -z $SECRET_KEY_BASE ]]
then
    SECRET_KEY_BASE=IWTVkfnfrKBta0U6p4UUbajb44wu5lYcrK0B6drT+dvnuTvSN18vliy3cxUnLXt3
fi

if [[ -z $DATABASE_URL ]]
then
    DATABASE_URL=postgresql://bsuser:QGpLYA3M72YGFS9COCkqD2asCp+OxFX17zoLC5Ffns=@block-explorer-dev-db.c70xizjgjbsm.us-west-2.rds.amazonaws.com:5432/BlockExplorerDevDB
fi

if [[ -z $ETHEREUM_JSONRPC_HTTP_URL ]]
then
    ETHEREUM_JSONRPC_HTTP_URL=http://172.31.77.121:39796
    ETHEREUM_JSONRPC_WS_URL=ws://172.31.77.121:39795
    ETHEREUM_JSONRPC_TRACE_URL=$ETHEREUM_JSONRPC_HTTP_URL
fi

#
case $1 in
    build_webapp|webapp)
        if [[ -z $(docker ps -a -f NAME=${WEBAPP} | grep  $1) ]]
        then
            echo "==> Build blockscout webapp"
            docker build -f ${APPDIR}/scripts/Dockerfile_webapp -t ${WEBAPP}:$CI_COMMIT_SHA ../
            docker tag ${WEBAPP}:$CI_COMMIT_SHA ${WEBAPP}:latest
            docker rmi ${WEBAPP}:$CI_COMMIT_SHA
        else
            echo "==> Build blockscout webapp"
            docker build -f ${APPDIR}/scripts/Dockerfile_webapp -t ${WEBAPP}:$CI_COMMIT_SHA ../
            docker stop ${WEBAPP}
            docker rm ${WEBAPP}
            docker tag ${WEBAPP}:$CI_COMMIT_SHA ${WEBAPP}:latest
            docker rmi ${WEBAPP}:$CI_COMMIT_SHA
        fi
        ;;

    build_indexer|indexer)
        if [[ -z $(docker ps -a -f NAME=${INDEXER} | grep  $1) ]]
        then
            echo "==> Build blockscout indexer"
            docker build -f ${APPDIR}/scripts/Dockerfile_indexer -t ${INDEXER}:$CI_COMMIT_SHA ../
            docker tag ${INDEXER}:$CI_COMMIT_SHA ${INDEXER}:latest
            docker rmi ${INDEXER}:$CI_COMMIT_SHA
        else
            echo "==> Build blockscout indexer"
            docker build -f ${APPDIR}/scripts/Dockerfile_indexer -t ${INDEXER}:$CI_COMMIT_SHA ../
            docker stop ${INDEXER}
            docker rm ${INDEXER}
            docker tag ${INDEXER}:$CI_COMMIT_SHA ${INDEXER}:latest
            docker rmi ${INDEXER}:$CI_COMMIT_SHA
        fi
        ;;

    run_webapp|start_webapp)
        echo "==> Starting blockscout webapp"
        docker run -d --name ${WEBAPP} \
            --env-file ${APPDIR}/scripts/sandbox.env \
            --volume ${APPDIR}/logs:/opt/app/logs \
            --network host \
            ${WEBAPPIMAGE}:latest /bin/sh -c "mix phx.server" \
            DISABLE_WEBAPP=false
        ;;

    run_indexer|start_indexer)
        echo "==> Starting blockscout indexer"
        docker run -d --name ${INDEXER} \
            --env-file ${APPDIR}/scripts/sandbox.env \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${INDEXER}:latest /bin/sh -c "mix phx.server"
            #DISABLE_WEBAPP=true
        ;;

    schema_webapp)
        echo "==> Set up DB schema"
        docker run --rm --name ${WEBAPP}DB \
            --env-file ${APPDIR}/scripts/sandbox.env \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${WEBAPP}:latest /bin/sh -c "mix do ecto.create, ecto.migrate"
        ;;

    schema_indexer)
        echo "==> Set up DB schema"
        docker run --rm --name ${INDEXER}DB \
            --env-file ${APPDIR}/scripts/sandbox.env \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${INDEXER}:latest /bin/sh -c "mix do ecto.create, ecto.migrate"
        ;;

    all_webapp)
        $0 build_webapp
        #$0 schema_webapp
        $0 run_webapp
        ;;

    all_indexer)
        $0 build_indexer
        $0 schema_indexer
        $0 run_indexer
        ;;

    stop_webapp)
        echo "==> Stopping webapp"
        if [[ ! -z $(docker ps -a -f NAME=${WEBAPP} | grep ${WEBAPP} ) ]]
        then
            docker stop ${WEBAPP}
            docker rm ${WEBAPP}
        fi
        ;;

    stop_indexer)
        echo "==> Stopping indexer"
        if [[ ! -z $(docker ps -a -f NAME=${INDEXER} | grep  ${INDEXER} ) ]]
        then
            docker stop ${INDEXER}
            docker rm ${INDEXER}
        fi
        ;;

    dropdb)
        echo "==> Droping DB and recreating DB schema"
        docker run --rm -i --name ${INDEXER}DROPDB \
            --env-file ${APPDIR}/scripts/sandbox_indexer.env \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${INDEXER}:latest /bin/sh -c "mix do ecto.drop"
        ;;

    restart_webapp)
        $0 stop_webapp
        sleep 10
        $0 start_webapp
        ;;

    restart_indexer)
        $0 stop_indexer
        sleep 10
        $0 start_indexer
        ;;

    cleanup_webapp)
        if [[ -z $(docker ps -a -f NAME=${WEBAPP} | grep  $1) ]]
        then
            $0 stop_webapp
            docker rmi ${WEBAPP}
        fi
        ;;

    cleanup_indexer)
        if [[ -z $(docker ps -a -f NAME=${INDEXER} | grep  $1) ]]
        then
            $0 stop_indexer
            docker rmi ${INDEXER}
        fi
        ;;

    bash_webapp)
        docker run -it ${WEBAPP} bash
        #docker exec -it ${WEBAPP} /bin/bash
        ;;

    bash_indexer)
        docker run -it ${INDEXER} bash
        #docker exec -it ${INDEXER} /bin/bash
        ;;

    ai_webapp)
        docker start -ai ${WEBAPP}
        ;;

    ai_indexer)
        docker start -ai ${INDEXER}
        ;;

    *)
        echo
        echo "Usage: $0 option"
        echo "  Options:"
        echo "    build_webapp    - Build Docker container"
        echo "    build_indexer   - Build Docker container"
        echo "    schema          - Deploy / update Posgres DB Schema"
        echo "    run_webapp      - Run Docker container"
        echo "    run_indexer     - Run Docker container"
        echo "    all_webapp      - Build and run webapp Docker container"
        echo "    all_indexer     - Build and run indexer Docker container"
        echo ""
        echo "    stop_webapp     - Stop docker container"
        echo "    stop_indexer    - Stop docker container"
        echo "    cleanup_webapp  - Remove webapp docker image"
        echo "    cleanup_indexer - Remove webapp docker image"
        echo "    dropdb          - Drop and recreate DB schema"
        echo
        exit
        ;;
esac
