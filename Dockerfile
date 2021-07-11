# Loosely based on:
# https://github.com/CM2Walki/steamcmd 
# https://github.com/CM2Walki/CSGO/
# https://github.com/FragSoc/csgo-server-scrim

FROM debian:buster-slim

ENV USER=user
ENV HOME_DIR=/home/$USER
ENV STEAMCMD_DIR=$HOME_DIR/Steam \
    CSGO_DIR=$HOME_DIR/csgo-server

ENV SOURCE_URL=https://raw.githubusercontent.com/theo-brown/csgo-docker/main \
    STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    METAMOD_URL=https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1144-linux.tar.gz \
    SOURCEMOD_URL=https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6504-linux.tar.gz \
    GET5_URL=https://github.com/splewis/get5/releases/download/0.7.2/get5_0.7.2.zip

# Set up filesystem
#    Add a non-root user
#    Create the directories for SteamCMD and the csgo install 
RUN useradd -m $USER \
    && su $USER -c \
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
    && su $USER -c \
        "wget -q -O $HOME_DIR/get5.zip $GET5_URL \
         && unzip -q $HOME_DIR/get5.zip -d $HOME_DIR \
         && mv $HOME_DIR/get5/addons $CSGO_DIR/csgo/addons \
         && mv $HOME_DIR/get5/cfg $CSGO_DIR/csgo/cfg \
         && rm -rf $HOME_DIR/get5 $HOME_DIR/get5.zip \
         && wget -q -O - $STEAMCMD_URL | tar -zx -C $STEAMCMD_DIR \
         && wget -q -O - $METAMOD_URL | tar -xz -C $CSGO_DIR/csgo \
         && wget -q -O - $SOURCEMOD_URL | tar -xz -C $CSGO_DIR/csgo" \
   && chmod -R 755 $HOME_DIR

# Download install script and install csgo
# NOTE: We use a RUN block here rather than a COPY block so that it only takes one layer
# to get the install script on the image with the right permissions
RUN su $USER -c \
     "wget -q -O $HOME_DIR/server_update.sh $SOURCE_URL/server-scripts/server_update.sh \
      && chmod u+x $HOME_DIR/server_update.sh \
      && bash $HOME_DIR/server_update.sh" 

# Download launch script and set perms
RUN su $USER -c \
     "wget -q -O $HOME_DIR/server_launch.sh $SOURCE_URL/server-scripts/server_launch.sh \
      && chmod u+x $HOME_DIR/server_launch.sh"

# Copy cfg files across
# This requiring two layers is a bit of a pain, but we can't download whole directories
# from $SOURCE_URL, so this is the easiest way of doing it 
COPY cfg/* $CSGO_DIR/csgo/cfg/
RUN chown -R $USER $CSGO_DIR/csgo/cfg \
    # Tidy up
    # Remove all unnecessary installed programs
    # Clear cache
    && apt-get -qq purge -y unzip wget \
    && apt-get -qq autoremove -y \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

USER $USER
WORKDIR $HOME_DIR

# Set default values for environment variables
# Setting IP to 0.0.0.0 means that it is forced to listen on all interfaces (wildcard) - don't change this
ENV IP="0.0.0.0" \
    PORT=27015 \
    GOTV_PORT=27020 \
    TICKRATE=128 \
    MAXPLAYERS=30 \
    GAMETYPE=0 \
    GAMEMODE=1 \
    MAPGROUP="mg_active" \
    MAP="de_mirage"

# Expose ports
EXPOSE $PORT/tcp \
       $PORT/udp \
       $GOTV_PORT/udp

# Run CSGO
CMD ["bash", "server_launch.sh"]
