#!/usr/bin/bash

task context none
task +home export > home.json
python tw2ics.py home.json

task +work export > work.json
python tw2ics.py work.json

task +phd export > phd.json
python tw2ics.py phd.json
