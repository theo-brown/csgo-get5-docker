#!/bin/bash

DOCKER_REPO="theobrown/csgo-get5-docker"


get_registry_csgo_version() {
    TOKEN_URL="https://auth.docker.io/token?service=registry.docker.io&scope=repository:$DOCKER_REPO:pull"
    HEADER="Accept: application/vnd.docker.distribution.manifest.v2+json"
    MANIFEST_URL="https://registry-1.docker.io/v2/$DOCKER_REPO/manifests/latest"

    # Get auth token from Docker Hub
    TOKEN=$(curl -s "$TOKEN_URL" | jq -r '.token')
    AUTH_HEADER="Authorization: Bearer $TOKEN"

    # Download the image manifest and use it to get the image digest (unique identifier)
    DIGEST=$(curl -s -H "$HEADER" -H "$AUTH_HEADER" "$MANIFEST_URL" | jq -r .config.digest)

    # Download metadata from Docker Hub
    METADATA=$(curl -s -L -H "$HEADER" -H "$AUTH_HEADER" "https://registry-1.docker.io/v2/$DOCKER_REPO/blobs/$DIGEST")

    # Get CSGO version from metadata json
    # -r returns as int rather than str
    echo $(echo $METADATA | jq -r .config.Labels.csgo_version)
}


check_csgo_version() {
    # Takes a CSGO version number as an argument
    # Returns 0 if $1 is the latest CSGO version
    # Returns the latest CSGO version if $1 is not the CSGO latest version

    VERSION_CHECK=$(curl -s "http://api.steampowered.com/ISteamApps/UpToDateCheck/v1?appid=730&version=$1" | jq .response)

    if $(echo $VERSION_CHECK | jq .up_to_date)
    then
        echo 0
    else
        echo $(echo $VERSION_CHECK | jq -r .required_version)
    fi
}


# Get version in registry
REGISTRY_CSGO_VERSION=$(get_registry_csgo_version)
echo "CS:GO version in $DOCKER_REPO:latest = $REGISTRY_CSGO_VERSION"

# Check version
LATEST_CSGO_VERSION=$(check_csgo_version $REGISTRY_CSGO_VERSION)

if [ $LATEST_CSGO_VERSION -eq 0 ]
then
    echo "CS:GO is already up to date (version $REGISTRY_CSGO_VERSION)."
else
    echo "Latest CS:GO version = $LATEST_CSGO_VERSION"

    NEW_TAG="$LATEST_CSGO_VERSION"

    echo "Launching container..."
    docker run --name=csgo_update_container -it "$DOCKER_REPO:latest" bash /home/user/server-update.sh

    echo "Committing changes..."
    docker commit --change "LABEL csgo_version=$LATEST_CSGO_VERSION" csgo_update_container "$DOCKER_REPO:latest"
    docker image tag "$DOCKER_REPO:latest" "$DOCKER_REPO:$NEW_TAG"

    echo "Pushing to registry..."
    docker push "$DOCKER_REPO:latest"
    docker push "$DOCKER_REPO:$NEW_TAG"

    echo "Deleting container..."
    docker rm -f csgo_update_container

    REGISTRY_CSGO_VERSION=$(get_registry_csgo_version)
    if [ ! $(check_csgo_version $REGISTRY_CSGO_VERSION) ]
    then
        echo "Update check failed: registry still does not have latest CSGO version"
        exit 1
    else
        echo "CS:GO is up to date (version $REGISTRY_CSGO_VERSION)."
        exit 0
    fi
fi
