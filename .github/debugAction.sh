#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if ! test -e debug
then echo no debug ; exit 0
fi

if [[ -z "$NGROK_TOKEN" ]]
then echo "Please set 'NGROK_TOKEN'"
     exit 1
fi

if [[ -z "$NGROK_PASSWORD" ]]
then echo "Please set 'NGROK_PASSWORD'"
     exit 1
fi

# Determine OS and architecture
OS=$(uname -s)
ARCH=$(uname -m)

echo "### Install ngrok ###"
# Set the download URL based on OS and architecture
if [ "$OS" = "Linux" ]; then
  if [ "$ARCH" = "x86_64" ]; then
    NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
  elif [ "$ARCH" = "aarch64" ]; then
    NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
  else
    echo "Unsupported Linux architecture: $ARCH"
    exit 1
  fi
elif [ "$OS" = "Darwin" ]; then
  if [ "$ARCH" = "x86_64" ]; then
    NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.tgz"
  elif [ "$ARCH" = "arm64" ]; then
    NGROK_URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.tgz"
  else
    echo "Unsupported macOS architecture: $ARCH"
    exit 1
  fi
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Download and install ngrok if not already present
if ! test -e ./ngrok; then
  echo "Downloading ngrok from $NGROK_URL"
  wget -q $NGROK_URL -O ngrok.tgz
  tar xzvf ngrok.tgz
  chmod +x ./ngrok
  rm ngrok.tgz
else
  echo "ngrok already installed"
fi

#echo "### Update user: $USER password ###"
#if [ "$OS" = "Linux" ]; then
#  echo -e "$NGROK_PASSWORD\n$NGROK_PASSWORD" | sudo passwd "$USER"
#elif [ "$OS" = "Darwin" ]; then
#
#fi
echo "### Adding ssh key to user ###"
mkdir -p ~/.ssh && chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
echo "$SSH_KEY" >> ~/.ssh/authorized_keys
cat ~/.ssh/authorized_keys

echo "### Start ngrok proxy for 22 port ###"

rm -f .ngrok.log
./ngrok authtoken "$NGROK_TOKEN"
./ngrok tcp 22 --log ".ngrok.log" &

sleep 10
HAS_ERRORS=$(grep "command failed" < .ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  MSG="To connect: $(grep -o -E "tcp://(.+)" < .ngrok.log | sed "s/tcp:\/\//ssh $USER@/" | sed "s/:/ -p /")"
  echo ""
  echo "=========================================="
  echo "$MSG"
  echo "=========================================="
else
  echo "$HAS_ERRORS"
  exit 1
fi