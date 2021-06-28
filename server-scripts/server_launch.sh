cd $CSGO_DIR

ARGS="-game csgo -console -autoupdate -usercon $ARGS"

if [ -v SERVER_TOKEN ]
then
    ARGS="$ARGS +sv_setsteamaccount $SERVER_TOKEN"
fi
if [ -v PASSWORD ]
then
    ARGS="$ARGS +sv_password $PASSWORD"
fi
if [ -v RCON_PASSWORD ]
then
    ARGS="$ARGS +rcon_password $RCON_PASSWORD"
fi
if [ -v  PUBLIC_ADDRESS ]
then
    ARGS="$ARGS +net_public_adr $PUBLIC_ADDRESS"
fi
if [ -v IP ]
then
    ARGS="$ARGS -ip $IP"
fi
if [ -v PORT ]
then
    ARGS="$ARGS -port $PORT"
fi
if [ -v GOTV_PORT ]
then
    ARGS="$ARGS +tv_port $GOTV_PORT"
fi
if [ -v CLIENT_PORT ]
then
    ARGS="$ARGS +clientport $CLIENT_PORT"
fi
if [ -v TICKRATE ]
then
    ARGS="$ARGS -tickrate $TICKRATE"
fi
if [ -v MAXPLAYERS ]
then
    ARGS="$ARGS -maxplayers_override $MAXPLAYERS"
fi
if [ -v GAMETYPE ]
then
    ARGS="$ARGS +game_type $GAMETYPE"
fi
if [ -v GAMEMODE ]
then
    ARGS="$ARGS +game_mode $GAMEMODE"
fi
if [ -v MAPGROUP ]
then
    ARGS="$ARGS +mapgroup $MAPGROUP"
fi
if [ -v MAP ]
then
    ARGS="$ARGS +map $MAP"
fi
if [ -v HOST_WORKSHOP_COLLECTION ]
then
    ARGS="$ARGS +host_workshop_collection $HOST_WORKSHOP_COLLECTION"
fi
if [ -v WORKSHOP_START_MAP ]
then
    ARGS="$ARGS +workshop_start_map $WORKSHOP_START_MAP"
fi
if [ -v WORKSHOP_AUTHKEY ]
then
    ARGS="$ARGS -authkey $WORKSHOP_AUTHKEY"
fi
if [ -v INITIAL_CONFIG ]
then
    ARGS="$ARGS +exec $INITIAL_CONFIG"
fi

./srcds_run $ARGS

