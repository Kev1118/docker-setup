#!/bin/sh

#start services
service php8.3-fpm stop
service php8.3-fpm start
service nginx start
service supervisor start
service cron start

# start ssh agent
eval "$(ssh-agent -s)"

# add ssh keys from the mounted directory 
if [ -d "ssh" ] && [ "$(ls -A ssh)" ]; then
    for key in ssh/*; do
        ssh-add "$key"
    done
    ssh-add -l
else
    echo "No ssh keys found in the ssh/ directory."
fi

# to verify list out the added ssh keys to the ssh agent
ssh-add -l

# keep the container running
tail -f /dev/null
