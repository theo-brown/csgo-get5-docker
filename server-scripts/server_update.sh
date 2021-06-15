bash "${STEAMCMD_DIR}"/steamcmd.sh \
    +login anonymous \
    +force_install_dir "${CSGO_DIR}" \
    +app_update 740 validate \
    +quit

