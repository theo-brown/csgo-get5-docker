bash $HOME_DIR/server_update.sh

bash $CSGO_DIR/srcds_run \
    -game csgo -console -autoupdate -usercon \
    +sv_setsteamaccount "${SERVER_TOKEN}" \
#    +net_public_adr "${PUBLIC_ADDRESS}" \
#    -ip "${IP}" \
#    -port "${PORT}" \
#    +tv_port "${GOTV_PORT}" \
#    +clientport "${CLIENT_PORT}" \
#    -tickrate "${TICKRATE}" \
#    -maxplayers_override "${MAXPLAYERS}" \
#    +game_type "${GAMETYPE}" \
#    +game_mode "${GAMEMODE}" \
#    +mapgroup "${MAPGROUP}" \
#    +map "${MAP}" \
#    +host_workshop_collection "${HOST_WORKSHOP_COLLECTION}" \
#    +workshop_start_map "${WORKSHOP_START_MAP}" \
#    -authkey "${WORKSHOP_AUTHKEY}"
