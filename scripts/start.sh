#!/bin/bash
set -eo pipefail
set -x
​
# Set APPDIR
CURRENTDIR=$(pwd)
APPDIR=$(dirname $CURRENTDIR)
PROJECT_NAME="blockscout"
INDEXER="explorer_indexer"
WEBAPP="explorer_webapp"
SCHEMA_NAME="explorer_schema"
​
# Check script arguments
while [[ $# -gt 0 ]]
do
    key="$1"
    shift
​
    case $key in
        -e)
            ENV="$1"
            ENVFILE="${ENV}.env"
            shift
            ;;
​
        -r)
            TODO="$1"
            shift
            ;;
​
        -i)
            IMAGE="$1"
            shift
            ;;
​
        -x)
            set -x
            shift
            ;;
​
    esac
done
​
# Catch all for testing only
if [[ -z $CI_COMMIT_SHA ]]
then
    CI_COMMIT_SHA=bs123456
fi
​
# Catch all for testing only; set as secret
if [[ -z $SECRET_KEY_BASE ]]
then
    SECRET_KEY_BASE=IWTVkfnfrKBta0U6p4UUbajb44wu5lYcrK0B6drT+dvnuTvSN18vliy3cxUnLXt3
fi
​
if [[ -z $DATABASE_URL ]]
then
    DATABASE_URL=postgresql://bsuser:QGpLYA3M72YGFS9COCkqD2asCp+OxFX17zoLC5Ffns=@block-explorer-dev-db.c70xizjgjbsm.us-west-2.rds.amazonaws.com:5432/BlockExplorerDevDB
fi
​
if [[ -z $ETHEREUM_JSONRPC_HTTP_URL ]]
then
    ETHEREUM_JSONRPC_HTTP_URL=http://172.31.77.121:39796
    ETHEREUM_JSONRPC_WS_URL=ws://172.31.77.121:39795
    ETHEREUM_JSONRPC_TRACE_URL=$ETHEREUM_JSONRPC_HTTP_URL
fi
​
if [[ -z $IMAGE ]]
then
    IMAGE="${WEBAPP}"
fi
​
#
echo $TODO
case $TODO in
    build_webapp|webapp)
        if [[ -z $(docker ps -a -f NAME=${WEBAPP} | grep  ${WEBAPP}) ]]
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
​
    build_indexer|indexer)
        if [[ -z $(docker ps -a -f NAME=${INDEXER} | grep  ${INDEXER}) ]]
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
​
    run_webapp_local|start_webapp_local)
        echo "==> Starting blockscout webapp"
        docker run -d --name ${WEBAPP} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --network host \
            --restart on-failure:3 \
            ${WEBAPP}:latest /bin/sh -c "mix phx.server" \
            DISABLE_INDEXER=true
        ;;
​
    run_webapp|start_webapp)
        echo "==> Starting blockscout webapp"
        docker run -d --name ${WEBAPP} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --network host \
            --restart on-failure:3 \
            --log-driver="awslogs" \
            --log-opt awslogs-region=${REGION} \
            --log-opt awslogs-group=${ENV}-${PROJECT_NAME} \
            --log-opt awslogs-create-group=true \
            --log-opt awslogs-stream=${PROJECT_NAME}-${WEBAPP} \
            ${IMAGE}/${WEBAPP}:latest /bin/sh -c "mix phx.server" \
            DISABLE_INDEXER=true
        ;;
​
    run_indexer_local|start_indexer_local)
        echo "==> Starting blockscout indexer"
        docker run -d --name ${INDEXER} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --restart on-failure:3 \
	    --add-host mainnet.energi.cloudns.cl:127.0.0.1 \
            ${INDEXER}:latest /bin/sh -c "mix phx.server"
        ;;
​
    run_indexer|start_indexer)
        echo "==> Starting blockscout indexer"
        docker run -d --name ${INDEXER} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --network host \
            --restart on-failure:3 \
            --log-driver="awslogs" \
            --log-opt awslogs-region=${REGION} \
            --log-opt awslogs-group=${ENV}-${PROJECT_NAME} \
            --log-opt awslogs-create-group=true \
            --log-opt awslogs-stream=${PROJECT_NAME}-${INDEXER} \
            ${IMAGE}/${WEBAPP}:latest /bin/sh -c "mix phx.server"
        ;;
​
    schema_aws)
        echo "==> Set up DB schema"
        docker run --rm --name ${SCHEMA_NAME} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --log-driver="awslogs" \
            --log-opt awslogs-region=${REGION} \
            --log-opt awslogs-group=${ENV}-${PROJECT_NAME} \
            --log-opt awslogs-create-group=true \
            --log-opt awslogs-stream=${PROJECT_NAME}-${WEBAPP} \
            ${IMAGE}/${WEBAPP}:latest /bin/sh -c "mix do ecto.create, ecto.migrate"
        ;;
​
    schema_local)
        echo "==> Set up DB schema"
        docker run --rm --name ${SCHEMA_NAME} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${INDEXER}:latest /bin/sh -c "mix do ecto.create, ecto.migrate"
        ;;
​
    all_webapp)
        $0 -e $ENV -r build_webapp
        $0 -e $ENV -r schema_webapp
        $0 -e $ENV -r run_webapp
        ;;
​
    all_indexer)
        $0 -e $ENV -r build_indexer
        $0 -e $ENV -r schema_indexer
        $0 -e $ENV -r run_indexer
        ;;
​
    stop_webapp)
        echo "==> Stopping webapp"
        if [[ ! -z $(docker ps -a -f NAME=${WEBAPP} | grep ${WEBAPP} ) ]]
        then
            docker stop ${WEBAPP}
            docker rm ${WEBAPP}
        fi
        ;;
​
    stop_indexer)
        echo "==> Stopping indexer"
        if [[ ! -z $(docker ps -a -f NAME=${INDEXER} | grep  ${INDEXER} ) ]]
        then
            docker stop ${INDEXER}
            docker rm ${INDEXER}
        fi
        ;;
​
    dropdb)
        echo "==> Droping DB and recreating DB schema"
        docker run --rm -i --name ${INDEXER}DROPDB \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${WEBAPP}:latest /bin/sh -c "mix do ecto.drop"
        ;;
​
    keybase)
        echo "==> Generating Secret Key Base"
         docker run --rm --name keybase \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${WEBAPP}:latest /bin/sh -c "mix phx.gen.secret"
        ;;
    
    restart_webapp)
        $0 -e $ENV -r stop_webapp
        sleep 10
        $0 -e $ENV -r start_webapp
        ;;
​
    restart_indexer)
        $0 -e $ENV -r stop_indexer
        sleep 10
        $0 -e $ENV -r start_indexer
        ;;
​
    cleanup_webapp)
        if [[ -z $(docker ps -a -f NAME=${WEBAPP} | grep  $1) ]]
        then
            $0 stop_webapp
            docker rmi ${WEBAPP}
        fi
        ;;
​
    cleanup_indexer)
        if [[ -z $(docker ps -a -f NAME=${INDEXER} | grep  $1) ]]
        then
            $0 -e $ENV -r stop_indexer
            docker rmi ${INDEXER}
        fi
        ;;
​
    bash_webapp)
        docker run -it ${WEBAPP} bash
        #docker exec -it ${WEBAPP} /bin/bash
        ;;
​
    bash_indexer)
        docker run -it ${INDEXER} bash
        #docker exec -it ${INDEXER} /bin/bash
        ;;
​
    ai_webapp)
        docker start -ai ${WEBAPP}
        ;;
​
    ai_indexer)
        docker start -ai ${INDEXER}
        ;;
​
    *)
        echo
        echo "Usage: $0 -e ENVIRONMENT -r RUN_OPTION [-i AWS_ECR]"
	echo "  ENVIRONMENT:"
	echo "    local           - local"
	echo "    develop         - sandbox"
	echo "    testnet         - testnet"
	echo "    mainnet         - mainnet"
        echo "  RUN_OPTION:"
        echo "    build_webapp    - Build Docker container"
        echo "    build_indexer   - Build Docker container"
        echo "    schema_webapp   - Deploy / update Posgres DB Schema"
        echo "    schema_indexer  - Deploy / update Posgres DB Schema"
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
        echo ""
        echo "    bash_webapp     - bash shell to WEBAPP docker"
        echo "    bash_indexer    - bash shell to INDEXER docker"
        echo
        exit
        ;;
esac