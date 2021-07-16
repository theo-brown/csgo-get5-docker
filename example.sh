source .env
docker run -it --network=host \
 -e SERVER_TOKEN=$SERVER_TOKEN \
 -e PASSWORD=justclickhead \
 -e RCON_PASSWORD=justclickheadmore \
 -e GOTV_PASSWORD=nostreamsniping \
 -e PORT=27015 \
 -e GOTV_PORT=27115 \
 -e WORKSHOP_AUTHKEY=$WORKSHOP_AUTHKEY \
 -e HOST_WORKSHOP_COLLECTION=1594247524 \
 -e WORKSHOP_START_MAP=1594218755 \
 theobrown/csgo-docker:latest

