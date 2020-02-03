# Edge Benchmarking Suite

*A small collection of Edge Computing benchmarking tools*

## How to use

This repository describes setting up three open source Edge Platforms, and includes sample configurations for reading, filtering, and writing to MQTT. 

The MQTT messages are timestamped by each stage in their processing, and the difference in the timestamps are visualized with the help of Node-Red. 

![latency.png](:/55fa409a9c074e6bb3d4dedcf6bc6dd3)



*Below are detailed instructions for setting up the messaging brokers, and each of the platforms evaluated.*

This repository includes:

- A configurable **MQTT Random Number Generator**
- Configurations for **[Eclipse Kura](https://www.eclipse.org/kura/)**
- Configurations for **[Linux Foundation EdgeXFoundry](https://www.edgexfoundry.org/)**
- Configurations for **[TIBCO Flogo](https://www.flogo.io)**

All scripts in the root of this repository are intended for running on ARM architecture (RPi or other)
Some may be appliciable to other architectures. See /x86/

**Tools Used:**
MQTT messaging service (Mosquitto)
node-red (flow creation)
[node-red dashboard](https://flows.nodered.org/node/node-red-dashboard) (visualization)
`time` POSIX terminal applicatoin
`ctop` Container resource monitor



### Starting MQTT messaging service
`snap install mosquitto mosquitto-clients`

-or as a docker image-

`docker run -d --rm --name broker -p 1883:1883 eclipse-mosquitto`

### Starting virtual MQTT device

note:
* replace the below IP with your device IP from `ifconfig`
* replace path where you checked out this repo: `-v /home/pi/edge-benchmarking-suite/vir-mqtt-dev`

on your Raspberry Pi communication node:
```
docker run -d --rm --name=mqtt-scripts \
-v /home/ubuntu/edge-benchmarking-suite/vir-mqtt-dev:/scripts \
dersimn/mqtt-scripts:armhf --url mqtt://192.168.1.1 --dir /scripts
```
* Or on a x86 machine:
```
docker run -d --rm --name=mqtt-scripts \
-v /home/dsouthwi/edge-benchmarking-suite/vir-mqtt-dev:/scripts  \
dersimn/mqtt-scripts --url mqtt://128.141.207.157 --dir /scripts
```

note: if you get problems mounting the `vir-mqtt-dev` folder, try disabling selinux (check `docker logs --latest`)

### Verify readings are being sent to the MQTT broker
Many ways to do this; I chose to use the mosquitto client (snap install mosquitto)
Here, we subscribe to the topic declared by our virtual device in `mqtt/configuration.toml`

You should see output similar to this after 15 seconds (default interval)
```
# mosquitto_sub -v -t '#'
logic/connected 2
DataTopic {"name":"MQ_DEVICE","cmd":"randnum","randnum":"25.6"}
DataTopic {"name":"MQ_DEVICE","cmd":"randnum","randnum":"28.3"}
```

### Start node-red
`nodered-start`
and import the included `nodered-flow.json` for visualizing results

# EdgeX

##### Configuration Installation
Install helper packages used in this repo for lua-based API scripts:
```shell
sudo apt-get install lua5.1 lua-socket lua-dkjson
```
(note any version of Lua will work, the script [shebang](https://bash.cyberciti.biz/guide/Shebang) may need to be updated)
##### Starting EdgeX

Use the `docker-compose.yml` file in the base of this repo:
```
docker-compose pull
docker-compose up -d
```

####### Docker x86

Pull latest docker-compose file

` wget https://github.com/edgexfoundry/developer-scripts/raw/master/releases/edinburgh/compose-files/docker-compose-edinburgh-1.0.1.yml -O docker-compose.yml`

and compose
`docker-compose pull`
`docker-compose up -d`

###### Configuring edgex

***The below steps are already included in the above rpi docker-compose, and helper script***

EdgeX is service based, and actions need to be defined at each service.
First, define the MQTT service and behaviour:
Using `device-mqtt` service block of docker-compose.yml
```docker
  device-mqtt:
    image: edgexfoundry/docker-device-mqtt-go:1.0.0
    ports:
      - "49982:49982"
    container_name: edgex-device-mqtt
    hostname: edgex-device-mqtt
    networks:
      edgex-network:
        aliases:
          - edgex-device-mqtt
    volumes:
      - db-data:/data/db
      - log-data:/edgex/logs
      - consul-config:/consul/config
      - consul-data:/consul/data
      - ./mqtt:/custom-config
    depends_on:
      - data
      - command
    entrypoint:
      - /device-mqtt
      - --registry=consul://edgex-core-consul:8500
      - --confdir=/custom-config
```
start `device-mqtt`
`docker-compose up -d device-mqtt`

Add publishing behaviour as defined in `EdgeX-register-MQTT-publish.lua`:
`./Edgex-register-MQTT-publish.lua 192.168.1.1`
where `192.168.1.1` is the location of your MQTT server to publish to.

Return codes from the command should be the UUID of the new export registration:
`1	146c578b-d5b9-4c39-9e36-65e7a1f4f1d3`


EdgeX stores persistent data in docker volumes. To clear this data, delete the volumes:
Starting from a clean slate: `docker system prune --volumes`

# Kura

##### Installation
https://eclipse.github.io/kura/intro/raspberry-pi-quick-start.html

Alternatively, Kura is available from Dockerhub:
`docker run -d -p 8080:8080 -t eclipse/kura`

Adding kura wires script block from the eclipse store (drag and drop in Kura 'Packages' panel)
https://marketplace.eclipse.org/content/wires-script-filter-kura-4xy

Then import the included kura configurations `kura_settings.xml` into the Kura 'Settings' panel

Testing the included kura topic:
`mosquitto_pub -t "kura/02:42:AC:11:00:03/W1/DataTopic" -m "{ \"sentOn\":1511970625597, \"metrics\":{\"fieldName\":12345},\"body\":12344555}"`

# Flogo

Install golang,
`apt install golang`
export go settings:
```
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
export GOPROXY=direct
```
install Flogo CLI
`go get -u github.com/project-flogo/cli/...`
Build the `flogo.json` FLOW in this repository
```
flogo create -f edge.json edge
cd edge
flogo build -e
```
Deploy the resulting binary in `edge/bin` to your edge device and execute.
