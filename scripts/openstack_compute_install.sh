#!/bin/bash -x

# Configure compute nodes
salt "cmp*" state.apply
salt "cmp*" state.apply

# Reboot compute nodes
echo "Rebooting compute nodes ..."

salt "cmp*" system.reboot
