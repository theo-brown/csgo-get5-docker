# Modified from:
# https://github.com/CM2Walki/steamcmd 
# https://github.com/CM2Walki/CSGO/
# https://github.com/FragSoc/csgo-server-scrim

FROM debian:buster-slim

ENV USER=user
ENV HOME_DIR=/home/$USER
ENV STEAMCMD_DIR=$HOME_DIR/steamcmd \
    CSGO_DIR=$HOME_DIR/csgo-server

# Set up filesystem
RUN useradd -m $USER \
    && mkdir -p $STEAMCMD_DIR \
    && mkdir -p $CSGO_DIR/csgo/cfg

# Install prerequisites
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        lib32gcc1 \
        ca-certificates \
        wget \
        unzip \
    # Download and unpack steamcmd
    && cd $STEAMCMD_DIR \
    && wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz \
    # Download and unpack plugins
    && cd $CSGO_DIR/csgo \
    && wget https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1144-linux.tar.gz \
    && wget https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6503-linux.tar.gz \
    && wget https://github.com/splewis/get5/releases/download/0.7.1/get5_0.7.1.zip \
    && tar xf mmsource-1.11.0-git1144-linux.tar.gz \
    && tar xf sourcemod-1.10.0-git6503-linux.tar.gz \
    && unzip get5_0.7.1.zip \
    && rm *.tar.gz *.zip \
    # Fix permissions
    && chown -R $USER:$USER $HOME_DIR \
    # Tidy up
    && apt-get purge -y wget unzip \
    && apt-get autoremove -y

USER $USER

# Copy scripts
COPY server-scripts/* $HOME_DIR/

# Install CSGO
RUN bash $HOME_DIR/server_update.sh

# Copy plugin settings
COPY cfg/* $CSGO_DIR/csgo/cfg/

WORKDIR $HOME_DIR

# Set default values for environment variables
ENV RCON_PASSWORD="admin" \
    PORT=27015 \
    GOTV_PORT=27020 \
    TICKRATE=128 \
    MAXPLAYERS=30 \
    GAMETYPE=0 \
    GAMEMODE=1 \
    MAPGROUP="mg_active" \
    MAP="de_mirage" \
    INITIAL_CONFIG="lobby"

# Expose ports
EXPOSE $PORT/tcp \
       $PORT/udp \
       $GOTV_PORT/udp

# Run CSGO
CMD ["bash", "server_launch.sh"]
