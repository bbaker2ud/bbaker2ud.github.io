#!/bin/bash
echo "Checking for updates..." &&
apt update && 
echo "Upgrading..." &&
apt -y upgrade && 
echo "Removing unused dependencies..." &&
apt -y autoremove &&
echo "Done."
