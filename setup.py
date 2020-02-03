#!/usr/bin/env python3
import platform

#platform=linux for now
platform=platform.system()
#release=fedora
release=platform.linux_distribution()[0]

MQTT_port=
