#!/usr/bin/env bash
cd /var/log
for l in $(ls -p | grep '/'); do
    echo -n >$l &>/dev/null
    echo clean file $l...
done
echo Finished!