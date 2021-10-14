#!/bin/bash

DOCKER_IMAGE="theobrown/csgo-get5-docker:latest"


get_local_csgo_version() {
    LOCAL_CSGO_VERSION=$(docker inspect --format '{{ index .Config.Labels "csgo_version" }}' $DOCKER_IMAGE)

    if [ -z $CSGO_VERSION ]
    then
        LOCAL_CSGO_VERSION=0
    fi

    echo $LOCAL_CSGO_VERSION
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

# Get local CSGO version
LOCAL_CSGO_VERSION=$(get_local_csgo_version)
echo "Local CS:GO version: $LOCAL_CSGO_VERSION"

# Check version against Steam API
LATEST_CSGO_VERSION=$(check_csgo_version $LOCAL_CSGO_VERSION)

if [ $LATEST_CSGO_VERSION -eq 0 ]
then
    echo "CS:GO is already up to date (version $LOCAL_CSGO_VERSION)."
else
    echo "Latest CS:GO version = $LATEST_CSGO_VERSION"

    echo "Launching update container..."
    docker run --name=csgo_update_container -it $DOCKER_IMAGE bash /home/user/server-update.sh
    echo "Committing changes..."
    docker commit --change "LABEL csgo_version=$LATEST_CSGO_VERSION" csgo_update_container $DOCKER_IMAGE
    echo "Deleting container..."
    docker rm -f csgo_update_container

    LOCAL_CSGO_VERSION=$(get_local_csgo_version)
    if [ ! $(check_csgo_version $LOCAL_CSGO_VERSION) ]
    then
       echo "Update failed: local image still does not have latest CSGO version"
       return 1
    else
        echo "CS:GO is up to date (version $LOCAL_CSGO_VERSION)."
        return 0
    fi
fi
