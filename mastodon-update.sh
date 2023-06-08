#!/usr/bin/env -S bash -e

ROOTDIR=$(dirname "$(readlink -f "$0")")
source "$ROOTDIR/.env"

sudo -u mastodon zsh <<"EOF"
export RAILS_ENV=production
cd /home/mastodon/live
source /home/mastodon/.zshrc
git pull
bundle install
yarn install --pure-lockfile
SKIP_POST_DEPLOYMENT_MIGRATIONS=true bundle exec rails db:migrate
bundle exec rails assets:precompile
EOF

lftp -u $ASSETS_FTP_USER,"$ASSETS_FTP_PASS" $ASSETS_FTP_HOST <<EOF
mirror -R -P20 -e /home/mastodon/live/public/* .
EOF

sudo systemctl reload mastodon-web.service
sudo systemctl restart mastodon-sidekiq.service mastodon-streaming.service
# Uncomment following line if you run ES on the same server as Mastodon.
# sudo systemctl start elasticsearch

sudo -u mastodon zsh <<"EOF"
export RAILS_ENV=production
cd /home/mastodon/live
source /home/mastodon/.zshrc
./bin/tootctl cache clear
bundle exec rails db:migrate
./bin/tootctl feeds clear
./bin/tootctl feeds build
EOF
