#!/bin/sh

#Publish Docker Container To Registry
####################################################

# exit when any command fails
set -e

#check inputs
if [[ -z "$INPUT_REGISTRY" ]]; then
    echo "Set the REGISTRY input."
    exit 1
fi

if [[ -z "$INPUT_USERNAME" ]]; then
	echo "Set the USERNAME input."
	exit 1
fi

if [[ -z "$INPUT_PASSWORD" ]]; then
	echo "Set the PASSWORD input."
	exit 1
fi

if [[ -z "$INPUT_IMAGE_NAME" ]]; then
	echo "Set the IMAGE_NAME input."
	exit 1
fi

if [[ -z "$INPUT_BUILD_CONTEXT" ]]; then
    echo "Set the BUILD_CONTEXT input."
    exit 1
fi

if [[ -z "$INPUT_DOCKERFILE_PATH" ]]; then
	echo "Set the DOCKERFILE_PATH input."
	exit 1
fi

# The following environment variables will be provided by the environment automatically: GITHUB_REPOSITORY, GITHUB_SHA, GITHUB_REF

# send credentials through stdin (it is more secure)
echo ${INPUT_PASSWORD} | docker login -u ${INPUT_USERNAME} --password-stdin ${INPUT_REGISTRY}

if [ "${INPUT_REGISTRY}" == "docker.pkg.github.com" ]; then
    # try to pull container if exists
    BASE_NAME="${INPUT_REGISTRY}/${GITHUB_REPOSITORY}/${INPUT_IMAGE_NAME}"
else
    BASE_NAME="${INPUT_REGISTRY}/${INPUT_USERNAME}/${INPUT_IMAGE_NAME}"
fi

echo "BASE_NAME set to ${BASE_NAME}"

# Add Arguments For Caching
BUILDPARAMS=""
if [ "${INPUT_CACHE}" == "true" ]; then
   # try to pull container if exists
   if docker pull ${BASE_NAME} 2>/dev/null; then
      echo "Attempting to use ${BASE_NAME} as build cache."
      BUILDPARAMS=" --cache-from ${BASE_NAME}"
   fi
fi

# Build The Container
docker build $BUILDPARAMS --tag ${BASE_NAME} --file ${INPUT_DOCKERFILE_PATH} ${INPUT_BUILD_CONTEXT}

if [ "${INPUT_TAG_REF}" == "true" ]; then
    REF_TAG=$(basename ${GITHUB_REF})
    echo "tagging as ${BASE_NAME}:${REF_TAG}"
    docker tag ${BASE_NAME} ${BASE_NAME}:${REF_TAG}
    docker push ${BASE_NAME}:${REF_TAG}
fi

if [ "${INPUT_TAG_LATEST}" == "true" ]; then
    echo "tagging as ${BASE_NAME}:latest"
    docker tag ${BASE_NAME} "${BASE_NAME}:latest"
    docker push "${BASE_NAME}:latest"
fi

if [ "${INPUT_TAG_VERSION}" == "true" ]; then
    VERSION_TAG=$(docker inspect ${BASE_NAME} | jq -r .[0].ContainerConfig.Labels.version) 
    
    if [ "${VERSION_TAG}" != "null" ]; then
        echo "tagging as ${BASE_NAME}:${VERSION_TAG}"
        docker tag ${BASE_NAME} "${BASE_NAME}:${VERSION_TAG}"
        docker push "${BASE_NAME}:${VERSION_TAG}"
    fi
fi

if [ "${INPUT_TAG_SHA}" == "true" ]; then
    # Set Local Variables
    SHORT_SHA=$(echo "${GITHUB_SHA}" | cut -c1-12)
    echo "tagging as ${BASE_NAME}:${SHORT_SHA}"
    docker tag ${BASE_NAME} "${BASE_NAME}:${SHORT_SHA}"
    docker push "${BASE_NAME}:${shortSHA}"
fi

if [ "${INPUT_TAG_TIMESTAMP}" == "true" ]; then
    # Set Local Variables
    TIMESTAMP_TAG=$(date +%Y-%m-%d_%HH%MM%SS%N)
    echo "tagging as ${BASE_NAME}:${TIMESTAMP_TAG}"
    docker tag ${BASE_NAME} "${BASE_NAME}:${TIMESTAMP_TAG}"
    docker push "${BASE_NAME}:${TIMESTAMP_TAG}"
fi

docker logout
