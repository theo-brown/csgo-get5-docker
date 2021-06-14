# Modified from:
# https://github.com/CM2Walki/steamcmd 
# https://github.com/CM2Walki/CSGO/
# https://github.com/FragSoc/csgo-server-scrim

FROM debian:buster-slim

ENV USER user
ENV HOME_DIR "/home/${USER}"
ENV STEAMCMD_DIR "${HOME_DIR}/steamcmd" 
ENV CSGO_DIR "${HOME_DIR}/csgo-server"

# Install prerequisites
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        lib32gcc1 \
        ca-certificates \
        wget \
        unzip \
    # Install steamcmd
    && mkdir -p "${STEAMCMD_DIR}" \
    && cd "${STEAMCMD_DIR}" \
    && wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    && tar -xf steamcmd_linux.tar.gz \
    && rm steamcmd_linux.tar.gz

# Install CSGO
RUN cd "${STEAMCMD_DIR}" \
    && ./steamcmd.sh +login anonymous +force_install_dir "${CSGO_DIR}" +app_update 740 +quit

# Install plugins
RUN cd "${CSGO_DIR}/csgo" \
    && wget https://mms.alliedmods.net/mmsdrop/1.11/mmsource-1.11.0-git1144-linux.tar.gz \
    && wget https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6503-linux.tar.gz \
    && wget https://github.com/splewis/get5/releases/download/0.7.1/get5_0.7.1.zip \
    && tar xf mmsource-1.11.0-git1144-linux.tar.gz \
    && tar xf sourcemod-1.10.0-git6503-linux.tar.gz \
    && unzip get5_0.7.1.zip \
    && rm *.tar.gz *.zip
