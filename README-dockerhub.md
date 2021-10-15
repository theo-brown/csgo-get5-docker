<h1 align="center">
    csgo-get5-docker
</h1>
<p align="center">
    <em>
        Quickly deploy a dedicated CS:GO server for a competitive match
    </em>
</p>
<p align="center">
    <a href="https://github.com/theo-brown/csgo-get5-docker/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/theo-brown/csgo-get5-docker">
    </a>
    <img src="https://img.shields.io/maintenance/yes/2021">
    <a href="https://github.com/theo-brown/csgo-get5-docker/actions/workflows/check-latest-csgo-version.yml">
        <img src="https://github.com/theo-brown/csgo-get5-docker/actions/workflows/check-latest-csgo-version.yml/badge.svg">
    </a>
</p>
<p align="center">
    <em>
        This README is replicated from the <a href="https://github.com/theo-brown/csgo-get5-docker">GitHub repo</a>
    </em>
</p>

## Contents

1. [Introduction](#1-introduction)

2. [Using the image](#2-using-the-image)

    2.1 [Quickstart](#21-quickstart)

    2.2 [Recommended Docker launch arguments](#22-recommended-docker-launch-arguments)

    2.3 [Examples](#23-examples)

3. [Environment variables](#3-environment-variables)

4. [Using Get5 for match creation](#4-using-get5-for-match-creation)

    4.1 [Match config schema](#41-match-config-schema)

    4.2 [Team schema](#42-team-schema)

5. [Keeping the image up to date](#5-keeping-the-image-up-to-date)

   5.1 [Updates on launch](#51-updates-on-launch)

   5.2 [Scheduled and manual updates](#52-scheduled-and-manual-updates)


## 1. Introduction

This image aims to provide a CS:GO server that can **run a competitive match straight out of the box**, with no setup
required beyond setting the match parameters.

Everything that can be changed about the server can be **set using environment variables** passed to Docker on container
creation.

[Get5](https://github.com/splewis/get5) is used to set up and manage the match - for further information as to how it 
works please read [Using Get5 for match creation](#using-get5-for-match-creation). If you need more detail have a look 
at the [Get5 documentation](https://github.com/splewis/get5).


## 2. Using the image

### 2.1 Quickstart

1. Download the image from [Docker hub](https://hub.docker.com/r/theobrown/csgo-server):
```
docker pull theobrown/csgo-get5-docker:latest
```

2. Launch a container:
```
docker run --network=host theobrown/csgo-get5-docker:latest
```

### 2.2 Recommended Docker launch arguments

At minimum, you'll probably want to launch the container with the following environment variables set:

* `--network=host`: use the host machine's ports and IP address, rather than running within an isolated Docker 
  network that's not visible to the outside world.

* `-e PASSWORD=<some password>`: set the password to connect to the server.

* `-e RCON_PASSWORD=<some other password>`: set the RCON (admin) password.

* `-e GOTV_PASSWORD=<another password>`: set the GOTV password.

* `-e SERVER_TOKEN=<your GSLT>`: set a Game Server Login Token so that the server can be connected to by 
  non-LAN clients (see [below](#3-environment-variables)).

If you want to start the server with a loaded config, set:

* `-e MATCH_CONFIG=<your match config>`: start the server with the given JSON config loaded with Get5.

### 2.3 Examples

#### 2.3.1 Starting a server with no match config (BO1 only)

Start a server with:
- The host machine's IP address 
- The specified port, GOTV port, password, RCON password, GOTV password, and server token

```
docker run --network=host \
 -e PORT=1234 \
 -e GOTV_PORT=1235
 -e PASSWORD=mypass \
 -e RCON_PASSWORD=adminpass \
 -e GOTV_PASSWORD=gotvpass \
 -e SERVER_TOKEN=A1B2C3D4E5F6G7H8I9J0 \
 theobrown/csgo-get5-docker:latest
```

Any player can connect to the server.
Once players are connected, to start a match, run the following in the in-game console: 
1. Set the rcon password to the one set in the Docker launch command, e.g. `rcon_password adminpass`
2. Set the map to the desired map using rcon and SourceMod commands, e.g. `rcon sm_map de_dust2`
3. Start the match using `rcon get5_creatematch`

Once the players ready up, the game will begin.

If the host machine had public IP `251.131.41.166` and port 1234 was visible to the outside world then running the 
following command in the CS:GO in-game console would connect to the server:
```
connect 251.131.41.166:1234; password mypass 
```

Running the following command in the CS:GO in-game console would connect to the GOTV stream:
```
connect 251.131.41.166:1235; password gotvpass
```

#### 2.3.2 Starting a server with a match config and in-server veto

Start a server with:
- The host machine's IP address 
- The specified port, GOTV port, password, RCON password, GOTV password, and server token 
- The given Get5 config loaded

Once the players are connected and ready up, the map veto will start. Once the veto is complete, the game will begin.
```
docker run --network=host \
 -e PASSWORD=mypass \
 -e RCON_PASSWORD=adminpass \
 -e GOTV_PASSWORD=gotvpass \
 -e SERVER_TOKEN=A1B2C3D4E5F6G7H8I9J0 \
 -e MATCH_CONFIG="{'matchid': '81a99ef9a2844c278c2bda2f5a77a793', \
                   'num_maps': 3, \
                   'maplist': ['de_dust2', 'de_inferno', 'de_mirage', 'de_nuke', 'de_overpass', 'de_train', 'de_vertigo'], \
                   'skip_veto': False, \
                   'team1': {'name': 'Astralis', \
                             'tag': 'AST', \
                             'players': {698652696634933762: 'gla1ve', \
                                         234783204182937471: 'Magisk', \
                                         389371614622221912: 'dev1ce', \
                                         951311418417028314: 'dupreeh', \
                                         369417162788295143: 'Xyp9x'}}, \
                   'team2': {'name': 'Natus Vincere', \
                             'tag': 'NAVI', \
                             'players': {875407653610178066: 's1mple', \
                                         979550479724346962: 'Boombl4', \
                                         186841562108230104: 'electronic', \
                                         726408891643982724: 'Perfecto', \
                                         512316566954794515: 'flamie'}}}" \
 theobrown/csgo-get5-docker:latest
```

#### 2.3.3 Starting a server with a match config with preset maps

Start a server with:
- The host machine's IP address 
- The specified port, GOTV port, password, RCON password, GOTV password, and server token 
- The given Get5 config loaded

Once the players are connected and ready up, the game will begin.

```
docker run --network=host \
 -e PASSWORD=mypass \
 -e RCON_PASSWORD=adminpass \
 -e GOTV_PASSWORD=gotvpass \
 -e SERVER_TOKEN=A1B2C3D4E5F6G7H8I9J0 \
 -e MATCH_CONFIG="{'matchid': '81a99ef9a2844c278c2bda2f5a77a793', \
                   'num_maps': 3, \
                   'maplist': ['de_dust2', 'de_inferno', 'de_overpass'], \
                   'skip_veto': True, \
                   'map_sides': ['team1_ct', 'team2_ct', 'knife'], \
                   'team1': {'name': 'Astralis', \
                             'tag': 'AST', \
                             'players': {698652696634933762: 'gla1ve', \
                                         234783204182937471: 'Magisk', \
                                         389371614622221912: 'dev1ce', \
                                         951311418417028314: 'dupreeh', \
                                         369417162788295143: 'Xyp9x'}}, \
                   'team2': {'name': 'Natus Vincere', \
                             'tag': 'NAVI', \
                             'players': {875407653610178066: 's1mple', \
                                         979550479724346962: 'Boombl4', \
                                         186841562108230104: 'electronic', \
                                         726408891643982724: 'Perfecto', \
                                         512316566954794515: 'flamie'}}}" \
 theobrown/csgo-get5-docker:latest
```


## 3. Environment variables

Setting environment variables when starting a container allows you to manipulate the launch options of the server.

For example, `docker run -e PASSWORD=1234 theobrown/csgo-server:latest` will start a new server with password `1234` 
by launching the server with `+sv_password 1234`. 

All possible environment variables are displayed in the table below.

| Variable name            | Launch option               | Description                                                                            
| :----------------------- | :-------------------------- | :-------------------------------
| SERVER_TOKEN             | `+sv_setsteamaccount`       | The Steam Game Server Login Token for this instance, required for the server to be accessible to non-LAN connections. Generate one [here](https://steamcommunity.com/dev/managegameservers) (default: not set, ie LAN connections only).
| PASSWORD                 | `+sv_password`              | Password required to connect to the server (default: not set)
| RCON_PASSWORD            | `+rcon_password`            | Password required to establish an RCON (remote console) connection to the server (default: not set)
| PORT                     | `-port`                     | Server port (default: 27015)
| GOTV_PORT                | `+tv_port`                  | GOTV port (default: 27020)
| GOTV_PASSWORD            | `+tv_password`              | GOTV password (default: not set)
| TICKRATE                 | `-tickrate`                 | Server tick rate (64 or 128; default: 128)
| MAXPLAYERS               | `-maxplayers_override`      | Limit how many players the server can contain (default: 30)
| GAMETYPE                 | `+game_type`                | Use GAMETYPE and GAMEMODE to set what game mode is played (default: GAMETYPE=0, GAMEMODE=1, which sets game mode to competitive). Note this will be overriden by Get5.
| GAMEMODE                 | `+game_mode`                | See above.
| MAPGROUP                 | `+mapgroup`                 | The map group to cycle through. Given this will be overridden by Get5, probably leave it as default (default: mg_active).
| MAP                      | `+map`                      | The map that the server starts on. Must be a valid CSGO map, e.g. `de_mirage`. 
| HOST_WORKSHOP_COLLECTION | `+host_workshop_collection` | Set the maps in specified workshop collection as the server's map list (default: not set)
| WORKSHOP_START_MAP       | `+workshop_start_map`       | Get the latest version of the workshop map with the specified ID and set it as the starting map (default: not set)
| WORKSHOP_AUTHKEY         | `-authkey`                  | Set a Steam Web API authkey, required to download maps from the workshop. Generate one [here](https://steamcommunity.com/dev/apikey) (default: not set).
| AUTOEXEC                 | `+exec`                     | A `.cfg` file to be executed on startup. Note anything you set here will probably be overwritten by Get5 when a match is loaded, so it's fairly useless (default: not set).
| UPDATE_ON_LAUNCH         | `-autoupdate`               | 1: Check for CS:GO updates on container launch, 0: do not check for updates. (default: 1)
| CUSTOM_ARGS              |                             | A string containing any additional launch options to pass to the dedicated server (default: not set)
| MATCH_CONFIG             |                             | If set to a valid JSON match config, the server starts with the config loaded. If not set, the server starts with `get5_check_auths 0`. [See below](#using-get5-for-match-creation) for more on using Get5. (Default: not set.)


Launch options are appended to the following set of basic launch options that are passed as arguments to `srcds`, the 
dedicated server program:
```
-game csgo -console -usercon -steam_dir $STEAMCMD_DIR -steamcmd_script $STEAMCMD_DIR/steamcmd.sh -ip 0.0.0.0
```


## 4. Using Get5 for match creation

*This section is mostly directly copied from [Get5's README](https://github.com/splewis/get5/blob/master/README.md)*

Get5 uses JSON-formatted objects to create matches. These set the players who are allowed on the server, the maps to be 
played, the sides, etc.

The image can start a container with or without a match config, by setting the optional environment variable 
`MATCH_CONFIG` or leaving it unset.

If started with a match config, only the players specified in the config will be able to connect.
If started with no match config, then any player can connect, and once connected the command `rcon get5_creatematch`
needs to be run in console to set up a match.

### 4.1 Match Config Schema

Of the below fields, only the team1 and team2 fields are actually required. Reasonable defaults are used for other
fields (bo3 series, 5v5, empty strings for team names, etc.)

| Element                    | Description 
| :------------------------- | :--------------------- 
| `matchid`                  | A string used to identify the match
| `num_maps`                 | Number of maps in the series. This must be an odd number or 2.
| `maplist`                  | An odd-length array of strings identifying the maps to use.
| `skip_veto`                | If true, the veto will be skipped and the maps will come from the maplist in the order given. If false, use Get5's built in veto menu.
| `veto_first`               | Either `"team1"`, or `"team2"`. If not set, or set to any other value, team 1 will veto first.
| `side_type`                | Either `"standard"` (team that didn't pick the map chooses which side to start on), `"never_knife"` (team1 starts as CT), or `"always_knife"` (play a knife round at the beginning of each map)
| `map_sides`                | If `skip_veto` is true, then the starting sides for each map need to be set here in an array of strings. Possible values: `"team1_t"`, `"team1_ct"`, `"team2_t"`, `"team2_ct"`, `"knife"`.
| `players_per_team`         | Maximum number of players per team, excluding coach (default: 5)
| `min_players_to_ready`     | Minimum number of connected players a team needs to be able to ready up (default: 1)
| `favored_percentage_team1` | Predicted percentage probability that team1 win (wrapper for mp_teamprediction_pct), displayed in GOTV.
| `favored_percentage_text`  | Text to accompany the prediction percentage displayed in GOTV (wrapper for mp_teamprediction_txt)
| `cvars`                    | Cvars to be set during the match warmup/knife round/live state
| `spectators`               | See the team schema below (only the players and name sections are used for spectators)
| `team1`                    | See the team schema below
| `team2`                    | See the team schema below

### 4.2 Team Schema

| Element        | Description
| :------------- | :---------------------
| `name`         | Team name (optional)
| `tag`          | Team tag - replaces client clan tags (optional)
| `flag`         | 2 letter country code to set the team's flag (optional)
| `logo`         | Team logo (optional)
| `players`      | Either an array of steamIDs or, to override in-game player names, a dictionary of steamIDs to names (**required**)
| `series_score` | Current score in the series. This can be used to give a team a map advantage (default: 0)


## 5. Keeping the image up to date

### 5.1 Updates on launch

By default, when a container is started from the image, it checks for CS:GO updates and installs them. Note that this 
will not modify your local copy of the image, so future containers will also have to download the update.
To disable checking for updates on launch, set the environment variable `UPDATE_ON_LAUNCH` to be `0`.

### 5.2 Scheduled and manual updates

For ensuring that an image contains the latest CS:GO version, two scripts are provided, one for local images and one for
the image in the DockerHub repo.
These can be run manually or at scheduled intervals. They run the following steps:
1. Check the version of CS:GO installed on the image 
2. If the version differs from the latest version of CS:GO according the Steam Web API, then a container is spawned 
   running `server-scripts/server-update.sh`, which installs CS:GO updates
3. The changes to the container are committed to the image and the image label updated to show the version of CS:GO 
   installed 
4. The image is pushed to the registry (`image_update/update-image-remote.sh` only)

The image updater scripts use `jq` to parse JSON objects from the Steam Web API. Install it using `sudo apt install jq`.

#### 5.2.1 Local version

To keep your local image up to date, you can schedule a `cron` job to run `updated-local-image.sh` at given intervals.
For example:

1. Run `crontab -e` to edit the crontab for the current user 
2. Add the following line to the opened file: 
```bash
10 * * * * /home/myuser/csgo-get5-docker/update-local-image.sh > /home/myuser/csgo-get5-docker/cron.log
```
This will run the script `/home/myuser/csgo-get5-docker/update-local-image.sh ` at 10 minutes past the hour every hour, and 
log the output to `/home/myuser/csgo-get5-docker/cron.log`.

#### 5.2.2 Version on DockerHub

The workflow ["Uses latest CS:GO version"](https://github.com/theo-brown/csgo-get5-docker/actions/workflows/check-csgo-version.yml)
checks that the version of CSGO on the image in the DockerHub registry matches the latest CS:GO patch released on Steam.

The script `image_update/update-image-remote.sh` is run remotely to periodically check for CS:GO updates and keep the 
registry image up to date. The update-push process can take a while, so it may be a little delayed.
