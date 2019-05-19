# TODO: This is not going to run multiple times. Need a way of ignoring some 
#       migrations. Then combine this with recreating the needed credentials and certificates. 
#       Should name files z-always-run-migration-name-migrate.sh then look for z-always-run to ignore.
if [ -f "/data/gen-secrets" ]; then
    rm /data/gen-secrets
    echo "Removed first run flag."
fi
