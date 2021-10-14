###############################################
#        csgo-get5-docker Dockerfile          #
###############################################
##  Docker image containing CSGO with Get5   ##
##      plugin for setting up matches        ##
###############################################
#    github.com/theo-brown/csgo-get5docker    #
###############################################

FROM debian:buster-slim

WORKDIR /home

# INSTALL CSGO
# Copy install script
# Install prerequisites
#   lib32gcc1: prerequisite for steamcmd
#   ca-certificates: required to trust downloads from the internet
#   wget: used to download steam and plugins
# Add user
# Create directories
# Set permissions
# Install SteamCMD
# Install CSGO
ENV STEAMCMD_DIR=/home/steam \
    CSGO_DIR=/home/csgo-server \
    STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
COPY server-scripts/server-update.sh .
RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends --no-install-suggests \
        lib32gcc1 \
        ca-certificates \
        wget \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p $STEAMCMD_DIR $CSGO_DIR \
    && useradd user \
    && chown -R user /home \
    && chmod -R 755 /home \
    && su user -c  \
       "wget -q -O - https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz| tar -zx -C $STEAMCMD_DIR \
       && bash server-update.sh"

# INSTALL PLUGINS
# Install prerequisites
#     lib32stdc++6: required for source plugins
#     unzip: required to unzip get5
# Install plugins
# Clean up
ENV METAMOD_URL=https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1144-linux.tar.gz \
    SOURCEMOD_URL=https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6504-linux.tar.gz \
    GET5_URL=https://github.com/splewis/get5/releases/download/0.7.2/get5_0.7.2.zip
RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends --no-install-suggests \
        lib32stdc++6 \
        unzip \
    && su user -c \
       "wget -q -O get5.zip $GET5_URL \
       && unzip -q get5.zip \
       && cp -rf get5 $CSGO_DIR/csgo \
       && rm -rf get5 get5.zip \
       && wget -q -O - $METAMOD_URL | tar -xz -C $CSGO_DIR/csgo \
       && wget -q -O - $SOURCEMOD_URL | tar -xz -C $CSGO_DIR/csgo" \
    && apt-get -qq purge -y unzip wget ca-certificates \
    && apt-get -qq autoremove -y \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

USER user

# Copy CSGO launch script
COPY server-scripts/server-launch.sh .

# Copy cfg files
COPY cfg/* $CSGO_DIR/csgo/cfg/

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

# Run CSGO
ENV UPDATE_ON_LAUNCH=1
CMD ["bash", "server-launch.sh"]
