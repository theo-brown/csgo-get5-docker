source .env
docker run -it --network=host \
 -e SERVER_TOKEN=$SERVER_TOKEN \
 -e PASSWORD=password \
 -e RCON_PASSWORD=rconpassword \
 -e GOTV_PASSWORD=gtovpassword \
 -e PORT=27115 \
 -e GOTV_PORT=27120 \
 theobrown/csgo-get5-docker:latest

