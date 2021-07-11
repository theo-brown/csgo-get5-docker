# csgo-docker

*Quickly deploy a dedicated CS:GO server for a competitive match*

The image contains Counter-Strike: Global Offensive, [MetaMod](https://www.sourcemm.net/), [SourceMod](https://www.sourcemod.net/), and [splewis' get5 plugin](https://github.com/splewis/get5) for creating matches.


## Contents

* [Introduction](#introduction)
* [Using the image](#using-the-image)
* [Environment variables](#environment-variables)
* [Using Get5 for match creation](#using-get5-for-match-creation)


## Introduction

The intention behind this image is to provide a CSGO server that can **run a competitive match straight out of the box**, with no setup required beyond setting the match parameters.

Everything that can be changed about the server can be set using environment variables passed to Docker on container creation.

[Get5](https://github.com/splewis/get5) is used to set up and manage the match - for further information as to how it works please read
[Using Get5 for match creation](#using-get5-for-match-creation). If you need more detail have a look at the [Get5 documentation](https://github.com/splewis/get5).

This Docker image was once based on [CM2Walki's CSGO Docker image](https://github.com/CM2Walki/CSGO), but it's evolved quite a bit since then.


## Using the image

1. Download the image from [Docker hub](https://hub.docker.com/r/theobrown/csgo-server)
```
docker pull theobrown/csgo-server:latest
```

2. Launch a container
```
docker run --network=host theobrown/csgo-server:latest

```

### Recommended docker launch arguments

`--network=host`: use the host's ports and ip, rather than running within an isolated Docker network that's not visible to the outside world.

`-e PASSWORD=<some password>`: set the password to connect to the server.

`-e RCON_PASSWORD=<some other password>`: set the RCON (admin) password.

`-e SERVER_TOKEN=<your GSLT>`: set a Game Server Login Token so that the server can be connected to by non-LAN clients (see [below](#environment-variables)).


## Environment variables

The image is highly configurable. Setting environment variables when starting a container allows you to manipulate the launch options of the server.

For example, `docker run -e PASSWORD=1234 theobrown/csgo-server:latest` will start a new server with password `1234` by launching the server with `+sv_password 1234`. 

All possible environment variables are displayed in the table below.

| Variable name            | Launch option               | Description                                                                            
| :----------------------- | :-------------------------- | :-------------------------------
| SERVER_TOKEN             | `+sv_setsteamaccount`       | The Steam Game Server Login Token for this instance, required for the server to be accessible to non-LAN connections. Generate one [here](https://steamcommunity.com/dev/managegameservers) (default: not set, ie LAN connections only).
| PASSWORD                 | `+sv_password`              | Password required to connect to the server (default: not set)
| RCON_PASSWORD            | `+rcon_password`            | Password required to establish an RCON (remote console) connection to the server (default: not set)
| PUBLIC_ADDRESS           | `+net_public_adr`           | Set the public IP of the server (default: not set). This should be set to your host machine's public IP.
| PORT                     | `-port`                     | Server port (default: 27015)
| GOTV_PORT                | `+tv_port`                  | GOTV port (default: 27020)
| CLIENT_PORT              | `+clientport`               | Specify the port that the server advertises to clients (default: not set). I'm not entirely sure what this does, so maybe just leave it unset.
| TICKRATE                 | `-tickrate`                 | Server tick rate (64 or 128; default: 128)
| MAXPLAYERS               | `-maxplayers_override`      | Limit how many players the server can contain (default: 30)
| GAMETYPE                 | `+game_type`                | Use GAMETYPE and GAMEMODE to set what game mode is played (default: GAMETYPE=0, GAMEMODE=1 - competitive)
| GAMEMODE                 | `+game_mode`                | See above.
| MAPGROUP                 | `+mapgroup`                 | (default: mg_active)
| MAP                      | `+map`                      | The map that the server starts on. Must be a valid CSGO map, e.g. `de_mirage`. 
| HOST_WORKSHOP_COLLECTION | `+host_workshop_collection` | (default: not set)
| WORKSHOP_START_MAP       | `+workshop_start_map`       | (default: not set)
| WORKSHOP_AUTHKEY         | `-authkey`                  | (default: not set)
| AUTOEXEC                 | `+exec`                     | A `.cfg` file to be executed on startup. Note anything you set here will probably be overwritten by get5 when a match is loaded, so it's fairly useless (default: not set).
| MATCH_CONFIG             |                             | If set to a valid JSON match config, the server starts with the config loaded. If not set, the server starts with `get5_check_auths 0`. [See below](#using-get5-for-match-creation) for more on using get5. (Default: not set.)


Launch options are appended to the following set of basic launch options that are passed as arguments to `srcds`, the dedicated server program.

Basic launch options:

```-game csgo -console -autoupdate -usercon```

## Using Get5 for match creation

*This section is mostly directly copied from [get5's README](https://github.com/splewis/get5/blob/master/README.md)*

Get5 uses JSON-formatted objects to create matches. These set the players who are allowed on the server, the maps to be played, the sides, etc.

The image can start a container with or without a match config, by setting the optional environment variable `MATCH_CONFIG` or leaving it unset.

If started with a match config, only the players specified in the config will be able to connect.
If started with no match config, then any player can connect, and once connected the command `get5_creatematch` needs to be run in console (or `!get5` sent in chat) to set up a match.

### Match Config Schema

Of the below fields, only the team1 and team2 fields are actually required. Reasonable defaults are used for other fields (bo3 series, 5v5, empty strings for team names, etc.)

 * `matchid`: a string matchid used to identify the match
 * `num_maps`: number of maps in the series. This must be an odd number or 2.
 * `maplist`: list of the maps in use (an array of strings), you should always use an odd-sized maplist
 * `skip_veto`: whether the veto will be skipped and the maps will come from the maplist (in the order given)
 * `veto_first`: either "team1", or "team2". If not set, or set to any other value, team 1 will veto first.
 * `side_type`: either "standard", "never_knife", or "always_knife"; standard means the team that doesn't pick a map gets the side choice, never_knife means team1 is always on CT first, and always knife means there is always a knife round
 * `players_per_team`: maximum players per team (doesn't include a coach spot, default: 5)
 * `min_players_to_ready`: minimum players a team needs to be able to ready up (default: 1)
 * `favored_percentage_team1`: wrapper for mp_teamprediction_pct
 * `favored_percentage_text`: wrapper for mp_teamprediction_txt
 * `cvars`: cvars to be set during the match warmup/knife round/live state
 * `spectators`: see the team schema below (only the players and name sections are used for spectators)
 * `team1`: see the team schema below
 * `team2`: see the team schema below

### Team Schema

Only name and players are required.

 * `name`: team name
 * `tag`: team tag - this replaces client "clan tags"
 * `flag`: team flag (2 letter country code)
 * `logo`: team logo
 * `players`: list of Steam IDs for users on the team. You can also force player names in here; you may use either an array of steamids or a dictionary of steamids to names.
 * `series_score`: current score in the series, this can be used to give a team a map advantage, defaults to 0
