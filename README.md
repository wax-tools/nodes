# WAX Tools

The official WAX builds are based on Docker, so here are a few more utilities that expand on the base image in order to allow easier running and maintenance of your WAX infrastructure.

Whether you're looking to make it as a block producer, or build the next big dApp, or are just a curious community member, there'll be something here for you. No promises.

* [Getting Started](#gogogo)
* [Docker Images](#imagethis)
* [Docker Helper Scripts](#scripts)
* [WAX node Bootstrapper](#yeet)
* [WAX Producer Monitor](#snitch)

# Getting Started

Here's a quick rundown of what you may or may not find lurking in the depths of this repo.

## `/config`
Inside the `config` folder, you'll find some sample config files for `nodeos` and `patroneos` a WAX testnet nodes to get you up and running quick like. 

### nodeos
Config files are organised per environment and per role, so in this directory you'll find a folder for api, seed and producer roles for the WAX testnet. 

There's also a common folder for a given environment, e.g. `wax-testnet` where you can plonk a genesis file. The genesis file is the same regardless of the node type you are running, so there's no point replicating this, unless you're into that sort of thing.

### patroneos

Block.One released [Patroneos](https://github.com/EOSIO/patroneos) in the early days of EOSIO as a security measure for API nodes. The purpose of this little utility is to filter out bad requests to a nodeos API in order to prevent someone from spamming your API and causing a nuisance.

Patroneos configuration is largely the same between instances, however it does need to know where to forward valid requests to an API node. In a future update, we'll make the config file optional and allow the API node URI to be specified as a parameter in to the image because we're nice like that.

## `/docker`

This is where the magic happens. Or not if you don't believe in all that. In the root directory are

`images` contains pretty pictures of Docker setups. Wait, no. It contains Dockerfiles and supporting files so that you can create the images that are used here.

`scripts` is a collection of bash scripts that are handy for working with nodeos running in a Docker container. You can find a list of the files and their purpose in the [scripts](#scripts) section.

`compose`, rather surprisingly, contains a few docker-compose definitions for working with containers created from images in the `images` folder.

# Docker Images

The `docker/images` is where you'll find docker images. Each image follows the recipe of having a Dockerfile, a `lib` folder and a `build.sh` file.

The `lib` folder contains any binaries/scripts/plumbuses you might need to construct a Docker image such as your `docker-entrypoint.sh` or a build script etc. 

## WAX.nodeos

This Dockerfile is used to create a Docker image specifically for running nodeos. It contains a helper script that takes some of the hassle out of starting a node.

Nodeos is pretty easy to start once everything is configured, however booting from genesis or using a snapshot to get up and running quickly can be a little cumbersome. The custom entry point in this image handles a few common startup tasks.

### Examples

1. Configure the .env file to point to somewhere sensible. The default settings will work, although you might want to point the `$NODEOS_DATA_ROOT` variable somewhere with a healthy amount of disk space as this is where the nodeos data directory will sit. *NOTE:* Docker needs absolute paths to places, otherwise it gets confused and thinks you might want to refer to a Docker volume.

2. From a terminal, run the following command:

`./start-wax.sh testnet api "" genesis`

This will start a new API node, booting from genesis.

3. Run `docker logs --follow --tail 10 wax-testnet-api` to see what's going on. If everything is configured properly, you should see you node syncing away like a happy little bunny. If that's not the case, then you clearly need to try harder.

## Patroneos

This Dockerfile takes the Patroneos source, compiles it in to a cute little binary and runs it in a Docker container. We've also gone and created a docker-compose definition so you can run this in tandem with your API nodes!

# Docker Helper Scripts
Docker is great, but some of the commands can be a little verbose. Like if you want to use the IP address of a container in a script, or list out the processor affinity of all your containers. We have a list of scripts that can take some of the pain away there.

[docker_container_affinity.sh](docker/scripts/docker_container_affinity.sh) will get a list of container names from Docker and print them out along with the PID of the container. For those of you who like to run your infrastructure on bare metal (who doesn't right?), this is a great time saver for working with isolated cores. The only thing missing is a script that takes this information and spreads your containers across your isolated cores... Does anyone want to make a pull-request?

[docker_follow.sh](docker/scripts/docker_follow.sh) for when you're hacking away at the terminal and find yourself hammering out the same damn 'docker --follow --tail 10 CONTAINER_NAME' line. Instead, just pass the container name to docker_follow.sh and save those precious key-presses! And sure, you could alias this, but that's a little less portable.

[docker_ip.sh](docker/scripts/docker_ip.sh) for when you absolutely need to get the IP of a container. This comes in to play in some other scripts for interacting with our nodeos instance inside a container without having to exec commands against the container. nodeos has its own API after all so why not use it?

[docker_list.sh](docker/scripts/docker_list.sh) isn't much, but it prints a list of container names. A tl;dr of docker ps if you will.

[nodeos_all_is_paused.sh](docker/scripts/nodeos_all_is_paused.sh) this will run through your producer containers and tell you if production is paused on it or not. This is awesome for when your're working with a local testnet, or testing things with multiple producers and want to make sure that only one (or maybe all) is producing blocks.

[nodeos_is_paused.sh](docker/scripts/nodeos_is_paused.sh) simply tells you if a producer node is paused!

[nodeos_production_resume.sh](docker/scripts/nodeos_production_resume.sh) uses an API call to instruct nodos to start producing blocks!

[nodeos_production_pause.sh](docker/scripts/nodeos_production_pause.sh) uses an API call to... That's right! Instruct nodeos to stop producing blocks. Everyone needs a break some time.

[nodeos_request.sh](docker/scripts/nodeos_request.sh) is a small wrapper script that forwards an HTTP request to the nodeos API

[run_portainer.sh](docker/scripts/run_portainer.sh) if you want a quick and easy GUI for your local Docker setup, run Portainer! With a bit of elbow grease, you can also get Portainer to connect to remote Docker instances too. More on that in a future update!

That's it for now! Check back later to see what else appears here. Or if you have an idea for something, create a pull-requ

## Makefile

You might have noticed a Makefile in the root of this repository. We wanted to create something that's flexible and easy to use without having to worry about lots of command line parameters and environment variables, so have kept things as lean as possible.

The Makefile allows us to do some funky stuff with templates, making it easier to pass parameters in to docker-compose, reducing the number of compose files and config files that we need.

Make is great at running simple recipes, although it's primarily built for building files. We've added some thin wrappers around Make to simplify things even further.

# Concepts
## Bootstrapping a WAX node
If you're running a new node and syncing from genesis, you need to pass a genesis file in to nodeos. The genesis file is only useful in this case and has to be provided to nodeos as a path to a file. Wouldn't it be cool if you could just provide a URL and tell nodeos to go figure? Now you can!

Your node has been up and running for a while and suddenly BOOM! Disaster stikes. Your node has died and you need to bring it back online. Your state is corrupted though. What do? Well you could replay the blockchain, but that's boring. Use a snapshot instead! Starting nodeos with a snapshot is pretty simple, just download the snapshot, un tar it and tell nodeos where to find it when launching. But wait, that's also really boring! Can't I just give nodeos a URL? YES!