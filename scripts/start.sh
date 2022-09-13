#!/bin/bash
set -eo pipefail

# Set APPDIR
CURRENTDIR=$(pwd)
APPDIR=$(dirname $CURRENTDIR)
PROJECT_NAME="blockscout"
INDEXER="explorer_indexer"
WEBAPP="explorer_webapp"
SCHEMA_NAME="explorer_schema"

# Catch all for local test only
if [[ -z $CI_COMMIT_SHA ]]
then
    CI_COMMIT_SHA=be123456
fi

# Base Image 
if [[ -z $BASE_IMAGE_LATEST ]]
then
    BASE_IMAGE_LATEST="explorer_base_image:latest"
fi
export ALPINE_VERSION=3.15.0
export ERLANG_VERSION=24.3.3

# Check script arguments
while [[ $# -gt 0 ]]
do
    key="$1"
    shift

    case $key in
        -e)
            ENV="$1"
            shift
            ;;

        -r)
            TODO="$1"
            shift
            ;;

        -i)
            ECRHOST="$1"
            shift
            ;;

        -x)
            set -x
            shift
            ;;

    esac
done

# Catch all for testing only; set as secret
if [[ -z $SECRET_KEY_BASE ]]
then
    SECRET_KEY_BASE=IWTVkfnfrKBta0U6p4UUbajb44wu5lYcrK0B6drT+dvnuTvSN18vliy3cxUnLXt3
fi

# Catch all for testing only
if [[ -z $DATABASE_URL ]]
then
    DATABASE_URL=postgresql://bsuser:QGpLYA3M72YGFS9COCkqD2asCp+OxFX17zoLC5Ffns=@block-explorer-dev-db.c70xizjgjbsm.us-west-2.rds.amazonaws.com:5432/BlockExplorerDevDB
fi

# Catch all for testing only
if [[ -z $ETHEREUM_JSONRPC_HTTP_URL ]]
then
    ETHEREUM_JSONRPC_HTTP_URL=http://172.31.77.121:39796
    ETHEREUM_JSONRPC_WS_URL=ws://172.31.77.121:39795
    ETHEREUM_JSONRPC_TRACE_URL=$ETHEREUM_JSONRPC_HTTP_URL
fi

# Main script
case $TODO in
    build_base_image)
        echo "==> Build blockscout webapp"
        export ALPINE_MIN_VERSION=$( echo $ALPINE_VERSION | sed -ne 's/[^0-9]*\(\([0-9]\.\)\{0,4\}[0-9][^.]\).*/\1/p' )
        export ELIXIR_VERSION=$( cat ../.tool-versions | grep elixir | awk '{print $2}' | awk -F\- '{print $1}' )
        export ELIXIR_MIN_VERSION=$( echo $ELIXIR_VERSION | sed -ne 's/[^0-9]*\(\([0-9]\.\)\{0,4\}[0-9][^.]\).*/\1/p' )

        docker build -f ${APPDIR}/scripts/Dockerfile_base_image \
            --build-arg ALPINE_VERSION=${ALPINE_VERSION} \
            --build-arg ALPINE_MIN_VERSION=${ALPINE_MIN_VERSION} \
            --build-arg ERLANG_VERSION=${ERLANG_VERSION} \
            --build-arg ELIXIR_VERSION=${ELIXIR_MIN_VERSION} \
            --platform linux/amd64 \
            -t $BASE_IMAGE_LATEST .
        ;;

    build_webapp|webapp)
        if [[ -z $(docker ps -a -f NAME=${WEBAPP} | grep ${WEBAPP}) ]]
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
        if [[ -z $(docker ps -a -f NAME=${INDEXER} | grep ${INDEXER}) ]]
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

    run_webapp_local|start_webapp_local)
        echo "==> Starting blockscout webapp"
        if [ "${ENV: -4}" == ".env" ]
        then
            ENV=$( echo $ENV | awk -F\. '{print $1}' )
            ENVFILE="${ENV}.env"
        else
            ENVFILE="${ENV}.env"
        fi
        docker run -d --name ${WEBAPP}_${ENV} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --network host \
            --restart on-failure:3 \
            ${WEBBAPP}:latest /bin/sh -c "mix phx.server" \
            DISABLE_INDEXER=true
        ;;

    run_webapp|start_webapp)
        echo "==> Starting blockscout webapp"
        if [ "${ENV: -4}" == ".env" ]
        then
            ENV=$( echo $ENV | awk -F\. '{print $1}' )
            ENVFILE="${ENV}_webapp.env"
        else
            ENVFILE="${ENV}_webapp.env"
        fi
        docker run -d --name ${WEBAPP}_${ENV} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --network host \
            --restart on-failure:3 \
            --log-driver="awslogs" \
            --log-opt awslogs-region=${REGION} \
            --log-opt awslogs-group=${ENV}-${PROJECT_NAME} \
            --log-opt awslogs-create-group=true \
            --log-opt awslogs-stream=${PROJECT_NAME}-${WEBAPP} \
            ${ECRHOST}/${WEBAPP}:latest /bin/sh -c "mix phx.server" \
            DISABLE_INDEXER=true
        ;;

    run_indexer_local|start_indexer_local)
        echo "==> Starting blockscout indexer"
        if [ "${ENV: -4}" == ".env" ]
        then
            ENV=$( echo $ENV | awk -F\. '{print $1}' )
            ENVFILE="${ENV}.env"
        else
            ENVFILE="${ENV}.env"
        fi
        docker run -d --name ${INDEXER}_${ENV} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            -v ${APPDIR}/scripts/config.exs:/opt/app/apps/indexer/config/config.exs:ro \
            --restart on-failure:3 \
            ${INDEXER}:latest /bin/sh -c "mix phx.server"
        ;;

    run_indexer|start_indexer)
        echo "==> Starting blockscout indexer"
        if [ "${ENV: -4}" == ".env" ]
        then
            ENV=$( echo $ENV | awk -F\. '{print $1}' )
            ENVFILE="${ENV}_indexer.env"
        else
            ENVFILE="${ENV}_indexer.env"
        fi
        docker run -d --name ${INDEXER}_${ENV} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            -v ${APPDIR}/scripts/config.exs:/opt/app/apps/indexer/config/config.exs:ro \
            --restart on-failure:3 \
            --log-driver="awslogs" \
            --log-opt awslogs-region=${REGION} \
            --log-opt awslogs-group=${ENV}-${PROJECT_NAME} \
            --log-opt awslogs-create-group=true \
            --log-opt awslogs-stream=${PROJECT_NAME}-${INDEXER} \
            ${ECRHOST}/${INDEXER}:latest /bin/sh -c "mix phx.server"
        ;;

    schema_aws)
        echo "==> Set up DB schema"
        if [ "${ENV: -4}" == ".env" ]
        then
            ENV=$( echo $ENV | awk -F\. '{print $1}' )
            ENVFILE="${ENV}_indexer.env"
        else
            ENVFILE="${ENV}_indexer.env"
        fi
        docker run --rm --name ${SCHEMA_NAME} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --log-driver="awslogs" \
            --log-opt awslogs-region=${REGION} \
            --log-opt awslogs-group=${ENV}-${PROJECT_NAME} \
            --log-opt awslogs-create-group=true \
            --log-opt awslogs-stream=${PROJECT_NAME}-${INDEXER} \
            ${ECRHOST}/${INDEXER}:latest /bin/sh -c "mix do ecto.create, ecto.migrate"
        ;;

    schema_local)
        echo "==> Set up DB schema"
        if [ "${ENV: -4}" == ".env" ]
        then
            ENV=$( echo $ENV | awk -F\. '{print $1}' )
            ENVFILE="${ENV}.env"
        else
            ENVFILE="${ENV}.env"
        fi
        docker run --rm --name ${SCHEMA_NAME} \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${INDEXER}:latest /bin/sh -c "mix do ecto.create, ecto.migrate"
        ;;

    all_webapp)
        $0 -e $ENV -r build_webapp
        $0 -e $ENV -r schema_webapp
        $0 -e $ENV -r run_webapp
        ;;

    all_indexer)
        $0 -e $ENV -r build_indexer
        $0 -e $ENV -r schema_indexer
        $0 -e $ENV -r run_indexer
        ;;

    stop_webapp)
        echo "==> Stopping webapp"
        if [[ ! -z $(docker ps -a -f NAME=${WEBAPP}_${ENV} | grep ${WEBAPP}_${ENV} ) ]]
        then
            docker stop ${WEBAPP}_${ENV}
            docker rm ${WEBAPP}_${ENV}
        fi
        ;;

    stop_indexer)
        echo "==> Stopping indexer"
        if [[ ! -z $(docker ps -a -f NAME=${INDEXER}_${ENV} | grep ${INDEXER}_${ENV} ) ]]
        then
            docker stop ${INDEXER}_${ENV}
            docker rm ${INDEXER}_${ENV}
        fi
        ;;

    dropdb)
        echo "==> Droping DB and recreating DB schema"
        docker run --rm -i --name ${INDEXER}DROPDB \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${INDEXER}:latest /bin/sh -c "mix do ecto.drop"
        ;;

    keybase)
        echo "==> Generating Secret Key Base"
         docker run --rm --name keybase \
            --env-file ${APPDIR}/scripts/${ENVFILE} \
            --volume ${APPDIR}/logs:/opt/app/logs \
            ${INDEXER}:latest /bin/sh -c "mix phx.gen.secret"
        ;;

    restart_webapp)
        $0 -e $ENV -r stop_webapp
        sleep 10
        $0 -e $ENV -r start_webapp
        ;;

    restart_indexer)
        $0 -e $ENV -r stop_indexer
        sleep 10
        $0 -e $ENV -r start_indexer
        ;;

    cleanup_webapp)
        if [[ -z $(docker ps -a -f NAME=${WEBAPP}_${ENV} | grep  ${WEBAPP}_${ENV}) ]]
        then
            $0 -r stop_webapp
            docker rmi ${WEBAPP}_${ENV}
        fi
        ;;

    cleanup_indexer)
        if [[ -z $(docker ps -a -f NAME=${INDEXER}_${ENV} | grep  ${INDEXER}_${ENV}) ]]
        then
            $0 -r stop_indexer
            docker rmi ${INDEXER}_${ENV}
        fi
        ;;

    bash_webapp)
        #docker run -it ${WEBAPP}_${ENV} bash
        docker exec -it ${WEBAPP} /bin/bash
        ;;

    bash_indexer)
        #docker run -it ${INDEXER}_${ENV} bash
        docker exec -it ${INDEXER} /bin/bash
        ;;

    ai_webapp)
        docker start -ai ${WEBAPP}_${ENV}
        ;;

    ai_indexer)
        docker start -ai ${INDEXER}_${ENV}
        ;;

    *)
        echo
        echo "Usage: $0 -e ENVIRONMENT -r RUN_OPTION [-i AWS_ECR]"
        echo "  ENVIRONMENT:"
        echo "    local           - use local.env"
        echo "    develop         - use sandbox.env"
        echo "    testnet         - use testnet.env"
        echo "    mainnet         - use mainnet.env"
        echo "  RUN_OPTION:"
        echo "    build_webapp    - Build Docker container"
        echo "    build_indexer   - Build Docker container"
        echo "    schema_aws      - Deploy / update Posgres DB Schema on AWS"
        echo "    schema_local    - Deploy / update Posgres DB Schema on local"
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
