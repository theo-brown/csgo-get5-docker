DOCKER_REPO="theobrown/csgo-docker"
#GHCR_REPO="ghcr.io/theo-brown/csgo-docker"
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

# Extract version information from image metadata
REGISTRY_CSGO_VERSION=$(echo $METADATA | jq '.config.Labels.csgo_version | tonumber')
echo "CS:GO version in $DOCKER_REPO:latest = $REGISTRY_CSGO_VERSION"
REGISTRY_IMAGE_VERSION=$(echo $METADATA | jq .config.Labels.image_version)

# Check the CSGO version of the registry image against the latest version in the Steam API
VERSION_CHECK=$(curl -s "http://api.steampowered.com/ISteamApps/UpToDateCheck/v1?appid=730&version=$REGISTRY_CSGO_VERSION" | jq .response)

# If it's not up to date, update it
if ! $(echo $VERSION_CHECK | jq .up_to_date)
then
    LATEST_CSGO_VERSION=$(echo $VERSION_CHECK | jq .required_version)
    NEW_TAG="$IMAGE_VERSION-$LATEST_CSGO_VERSION"
    echo "Latest CS:GO version = $LATEST_CSGO_VERSION"

    echo "Launching container..."
    docker run --name=csgo_update_container -it "$DOCKER_REPO:latest" bash /home/user/server_update.sh

    echo "Committing changes..."
    docker commit --change "LABEL csgo_version=$LATEST_CSGO_VERSION image_version=$REGISTRY_IMAGE_VERSION" csgo_update_container "$DOCKER_REPO:latest"
    docker image tag "$DOCKER_REPO:latest" "$DOCKER_REPO:$NEW_TAG"

    #docker image tag "$DOCKER_REPO:latest" "$GHCR_REPO:latest"
    #docker image tag "$DOCKER_REPO:latest" "$GHCR_REPO:$NEW_TAG"

    echo "Pushing to registry..."
    docker push "$DOCKER_REPO:latest"
    docker push "$DOCKER_REPO:$NEW_TAG"
    #docker push "$GHCR_REPO:latest"
    #docker push "$GHCR_REPO:$NEW_TAG"

    echo "Deleting container..."
    docker container rm csgo_update_container
fi

echo "CS:GO is up to date (version $REGISTRY_CSGO_VERSION)."
