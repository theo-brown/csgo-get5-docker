###############################################
#          csgo-docker Dockerfile             #
###############################################
##  Docker image containing CSGO with Get5   ##
##      plugin for setting up matches        ##
###############################################
# Developed by: Theo Brown                    #
# GitHub: github.com/theo-brown/csgo-docker   #
# Loosely based on: github.com/CM2Walki/CSGO/ #
###############################################

FROM debian:buster-slim

ENV HOME_DIR=/home/user
ENV STEAMCMD_DIR=$HOME_DIR/Steam \
    CSGO_DIR=$HOME_DIR/csgo-server \
    # URLs for downloads:
    SOURCE_URL=https://raw.githubusercontent.com/theo-brown/csgo-docker/main \
    STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    METAMOD_URL=https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1144-linux.tar.gz \
    SOURCEMOD_URL=https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6504-linux.tar.gz \
    GET5_URL=https://github.com/splewis/get5/releases/download/0.7.2/get5_0.7.2.zip \
    # Set default ports to expose
    PORT=27015 \
    GOTV_PORT=27020 

# Set up filesystem
#    Add a non-root user
#    Create the directories for SteamCMD and the csgo install 
RUN useradd -m user \
    && su user -c \
        "mkdir -p $STEAMCMD_DIR \
         && mkdir -p $CSGO_DIR/csgo" \
    # Install prerequisites
    #    lib32gcc1: prerequisite for steamcmd
    #    lib32stdc++6: prequisite for plugins 
    #    ca-certificates: required to trust downloads from the internet
    #    unzip: used to unzip get5 
    #    wget: used to download steam and plugins
    && apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends --no-install-suggests \
        lib32gcc1 \
        lib32stdc++6 \
        ca-certificates \
        unzip \
        wget \
    # Download and unpack server files
    #    steamcmd
    #    metamod
    #    sourcemod
    #    get5
    # NOTE: due to get5 being shipped as a .zip, we have to be a bit fiddly with unpacking.
    # Downloading and unzipping get5 first means that we can move all of the get5 files to
    # the right places before untarring everything else. Untarring can merge into existing
    # directories, but unzipping and moving cannot, so we unzip first.
    && su user -c \
        "wget -q -O $HOME_DIR/get5.zip $GET5_URL \
         && unzip -q $HOME_DIR/get5.zip -d $HOME_DIR \
         && mv $HOME_DIR/get5/addons $CSGO_DIR/csgo/addons \
         && mv $HOME_DIR/get5/cfg $CSGO_DIR/csgo/cfg \
         && rm -rf $HOME_DIR/get5 $HOME_DIR/get5.zip \
         && wget -q -O - $STEAMCMD_URL | tar -zx -C $STEAMCMD_DIR \
         && wget -q -O - $METAMOD_URL | tar -xz -C $CSGO_DIR/csgo \
         && wget -q -O - $SOURCEMOD_URL | tar -xz -C $CSGO_DIR/csgo" \
    && chmod -R 755 $HOME_DIR

# Get scripts and configs, set permissions
# NOTE: For the exectuable scripts we use RUN + wget rather than COPY 
# so that it only takes one layer to get the scripts on the image with 
# executable permissions

# Download install script and install csgo
RUN su user -c \
     "wget -q -O $HOME_DIR/server-update.sh $SOURCE_URL/server-scripts/server-update.sh \
      && chmod u+x $HOME_DIR/server-update.sh \
      && bash $HOME_DIR/server-update.sh"

# Download launch script
RUN su user -c \
     "wget -q -O $HOME_DIR/server-launch.sh $SOURCE_URL/server-scripts/server-launch.sh \
      && chmod u+x $HOME_DIR/server-launch.sh" \
    # Tidy up
    # Remove all unnecessary installed programs
    # Clear cache
    && apt-get -qq purge -y unzip wget \
    && apt-get -qq autoremove -y \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Copy cfg files
COPY --chown=user cfg/* $CSGO_DIR/csgo/cfg/

# Expose ports
EXPOSE $PORT/tcp \
       $PORT/udp \
       $GOTV_PORT/udp

# Label this image with the image version and installed CSGO version
# To get the version of the latest CSGO patch, run
# curl -s "http://api.steampowered.com/ISteamApps/UpToDateCheck/v1?appid=730&version=0" | jq .response.required_version
ARG CSGO_VERSION=13795
ARG IMAGE_VERSION="1.0.0"
LABEL csgo_version=$CSGO_VERSION \
      image_version=$IMAGE_VERSION

# Check that the installed version of CSGO matches the label of this image
RUN INSTALLED_VERSION="$(sed -rn 's/PatchVersion=([0-9]+).([0-9]+).([0-9]+).([0-9]+)/\1\2\3\4/p' $CSGO_DIR/csgo/steam.inf)" \
    && if [ $INSTALLED_VERSION -ne $CSGO_VERSION ]; then \
       echo "ERROR: Please update the CSGO version label to match the installed version. Labelled: $CSGO_VERSION / Installed: $INSTALLED_VERSION" >&2; \
       exit 1; \
    fi

# Run CSGO
USER user
WORKDIR $HOME_DIR
CMD ["bash", "server-launch.sh"]
