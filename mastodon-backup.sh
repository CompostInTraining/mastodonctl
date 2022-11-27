#!/usr/bin/env -S bash -xe

ROOTDIR=$(dirname "$(readlink -f "$0")")
source "$ROOTDIR/.env"
now=$(date --iso-8601=seconds)

# postgres
echo "Postgres..."
cd ~ && pg_dump -Fc mastodon_production -f postgres.dump
aws s3 cp /home/mastodon/postgres.dump s3://$S3_BUCKET_NAME/backup-postgres/$now/

# config...on sundays
if [ "$(date +%u)" == "7" ]; then
  echo "Config..."
  cd ~
  age -o .env.production.age -R $BACKUP_RECIPIENTS live/.env.production
  aws s3 cp /home/mastodon/.env.production.age s3://$S3_BUCKET_NAME/backup-config/$now/
fi

# heartbeat
curl $HEART_BEAT_URL