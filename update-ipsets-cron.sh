#!/bin/bash
if update-ipsets
then
  cp -r /etc/firehol/ipsets /ipsets
  echo "[INFO] IPsets successfully updated at $(date)" >> /ipsets/update.log
else
  "echo [ERROR] IPset update failed at $(date)"
fi
