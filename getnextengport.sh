#!/bin/bash

cat /data01/cv/EngineFactory/bin/*.sh|grep "/Engine"|sort -k4 -n|cut -d '/' -f11
