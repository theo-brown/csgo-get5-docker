IMAGE_VERSION="v1.0.0"
LATEST_CSGO_VERSION=$(curl -s "http://api.steampowered.com/ISteamApps/UpToDateCheck/v1?appid=730&version=0" | jq .response.required_version)

IMAGE_TAG="csgo-docker:$IMAGE_VERSION-$LATEST_CSGO_VERSION"

docker build . -t $IMAGE_TAG --build-arg CSGO_VERSION=$LATEST_CSGO_VERSION

# Push to GitHub Container Registry
docker image tag $IMAGE_TAG ghcr.io/theo-brown/$IMAGE_TAG
docker push ghcr.io/theo-brown/$IMAGE_TAG

# Push to Docker Hub
#docker image tag $IMAGE_TAG theobrown/$IMAGE_TAG
#docker push theobrown/$IMAGE_TAG

