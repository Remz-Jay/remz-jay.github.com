#!/bin/bash

gsutil rm gs://rem-co/timeline.json
docker run -it --rm -v $HOME/.twurlrc:/root/.twurlrc twips:latest twurl "/1.1/statuses/user_timeline.json?screen_name=remzjay&count=10" > timeline.json
gsutil -h "Content-Type:application/json" -h "Cache-Control:public, max-age=86400" cp -z json timeline.json gs://rem-co/
rm timeline.json
