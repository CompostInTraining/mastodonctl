#!/usr/bin/env -S bash -xe

ROOTDIR=$(dirname "$(readlink -f "$0")")
source "$ROOTDIR/.env"
now=$(date --iso-8601=seconds)

# postgres
echo "Postgres..."
cd ~ && pg_dump -Fc mastodon_production -f postgres.dump
aws s3 cp /home/mastodon/postgres.dump s3://$S3_BUCKET_NAME/backup-postgres/$now/
curl $HEART_BEAT_URL
