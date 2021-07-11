DOCKER_IMAGE="theobrown/csgo-server:latest"
CSGO_DIR="/home/user/csgo-server"

CSGO_VERSION=$(docker inspect --format '{{ index .Config.Labels "csgo_version" }}' $DOCKER_IMAGE)

if [ -z $CSGO_VERSION ]
then
    CSGO_VERSION=0
fi

echo "Current CS:GO version: $CSGO_VERSION"

# Steam API provides a URL that can be used to check whether a specific version of a game is up to date
JSON=$(curl -s "http://api.steampowered.com/ISteamApps/UpToDateCheck/v1?appid=730&version=$CSGO_VERSION" | jq .response)

## If the CSGO install is not up to date, then update the docker image
if ! $(echo $JSON | jq .up_to_date)
then
    LATEST_VERSION=$(echo $JSON | jq .required_version)
    echo "Latest CS:GO version: $LATEST_VERSION"
    echo "Launching container..."
    docker run --name=csgo_update_container -it $DOCKER_IMAGE bash /home/user/server_update.sh
    echo "Committing changes..."
    docker commit --change "LABEL csgo_version=$LATEST_VERSION" csgo_update_container $DOCKER_IMAGE
    echo "Pushing to registry..."
    docker push $DOCKER_IMAGE
    echo "Deleting container..."
    docker container rm csgo_update_container
fi

echo "CS:GO is up to date."

