DOCKER_IMAGE="theobrown/csgo-docker:latest"
CSGO_DIR="/home/user/csgo-server"

LOCAL_CSGO_VERSION=$(docker inspect --format '{{ index .Config.Labels "csgo_version" }}' $DOCKER_IMAGE)

if [ -z $CSGO_VERSION ]
then
    LOCAL_CSGO_VERSION=0
fi

echo "Current CS:GO version: $LOCAL_CSGO_VERSION"

# Steam API provides a URL that can be used to check whether a specific version of a game is up to date
JSON=$(curl -s "http://api.steampowered.com/ISteamApps/UpToDateCheck/v1?appid=730&version=$LOCAL_CSGO_VERSION" | jq .response)

## If the CSGO install is not up to date, then update the docker image
if ! $(echo $JSON | jq .up_to_date)
then
    LATEST_CSGO_VERSION=$(echo $JSON | jq -r .required_version)
    echo "Latest CS:GO version: $LATEST_CSGO_VERSION"
    echo "Launching container..."
    docker run --name=csgo_update_container -it $DOCKER_IMAGE bash /home/user/server-update.sh
    echo "Committing changes..."
    docker commit --change "LABEL csgo_version=$LATEST_CSGO_VERSION" csgo_update_container $DOCKER_IMAGE
    echo "Deleting container..."
    docker rm -f csgo_update_container
    echo "CS:GO is now up to date (version $LATEST_CSGO_VERSION)."
else
    echo "CS:GO is up to date (version $LOCAL_CSGO_VERSION)."
fi


