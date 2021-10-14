###############################################
#        csgo-get5-docker Dockerfile          #
###############################################
##  Docker image containing CSGO with Get5   ##
##      plugin for setting up matches        ##
###############################################
#    github.com/theo-brown/csgo-get5docker    #
###############################################

FROM debian:buster-slim

#####################
# SET UP FILESYSTEM #
#####################
RUN useradd -m user
WORKDIR /home/user/

################
# INSTALL CSGO #
################
# Copy install script
# Set permissions
# Install prerequisites
#   lib32gcc1: prerequisite for steamcmd
#   ca-certificates: required to trust downloads from the internet
#   wget: used to download steam and plugins
#   lib32stdc++6: required for source plugins
#   unzip: required to unzip get5
#   rsync: required to merge get5 directories
# Create directories
# Install SteamCMD
# Install CSGO
# Install plugins
# Clean up
ENV HOME_DIR=/home/user \
    STEAMCMD_DIR=/home/user/Steam \
    CSGO_DIR=/home/user/csgo-server \
    STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    METAMOD_URL=https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1144-linux.tar.gz \
    SOURCEMOD_URL=https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6504-linux.tar.gz \
    GET5_URL=https://github.com/splewis/get5/releases/download/0.7.2/get5_0.7.2.zip
COPY server-scripts/server-update.sh $HOME_DIR/
RUN chown user $HOME_DIR/server-update.sh \
    && chmod 755 $HOME_DIR/server-update.sh \
    && apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends --no-install-suggests \
        lib32gcc1 \
        ca-certificates \
        wget \
        lib32stdc++6 \
        unzip \
        rsync \
    && su user -c  \
       "mkdir $STEAMCMD_DIR $CSGO_DIR \
       && wget -q -O - $STEAMCMD_URL | tar -zx -C $STEAMCMD_DIR \
       && bash server-update.sh \
       && wget -q -O - $METAMOD_URL | tar -xz -C $CSGO_DIR/csgo \
       && wget -q -O - $SOURCEMOD_URL | tar -xz -C $CSGO_DIR/csgo \
       && wget -q -O get5.zip $GET5_URL \
       && unzip -q get5.zip \
       && rsync -aq get5/addons $CSGO_DIR/csgo/addons \
       && rsync -aq get5/cfg $CSGO_DIR/csgo/cfg \
       && rm -rf get5 get5.zip" \
    && apt-get -qq purge -y unzip rsync wget ca-certificates \
    && apt-get -qq autoremove -y \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

######################
# COPY LAUNCH SCRIPT #
######################
USER user
COPY server-scripts/server-launch.sh .

################
# COPY CONFIGS #
################
COPY cfg/* $CSGO_DIR/csgo/cfg/

###################
# CHECK LABELLING #
###################
# Label this image with the image version and installed CSGO version
# To get the version of the latest CSGO patch, run
# curl -s "http://api.steampowered.com/ISteamApps/UpToDateCheck/v1?appid=730&version=0" | jq .response.required_version
ARG CSGO_VERSION=13805
LABEL csgo_version=$CSGO_VERSION

# Check that the installed version of CSGO matches the label of this image
RUN INSTALLED_VERSION="$(sed -rn 's/PatchVersion=([0-9]+).([0-9]+).([0-9]+).([0-9]+)/\1\2\3\4/p' $CSGO_DIR/csgo/steam.inf)" \
    && if [ $INSTALLED_VERSION -ne $CSGO_VERSION ]; then \
       echo "ERROR: Please update the CSGO version label to match the installed version. Labelled: $CSGO_VERSION / Installed: $INSTALLED_VERSION" >&2; \
       exit 1; \
    fi

############
# RUN CSGO #
############
ENV UPDATE_ON_LAUNCH=1
CMD ["bash", "server-launch.sh"]
