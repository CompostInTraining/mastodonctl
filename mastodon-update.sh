#!/usr/bin/env -S bash -e

now=$(date --iso-8601=seconds)

echo $now

sudo -u mastodon zsh <<"EOF"
export RAILS_ENV=production
cd /home/mastodon/live
source /home/mastodon/.zshrc
git pull
bundle install
yarn install --pure-lockfile
echo Running pre-deployment migrations...
SKIP_POST_DEPLOYMENT_MIGRATIONS=true bundle exec rails db:migrate
echo Compiling assets...
bundle exec rails assets:precompile
EOF

echo Restarting services...
sudo systemctl reload mastodon-web.service
sudo systemctl restart mastodon-sidekiq.service mastodon-streaming.service
# Uncomment following line if you run ES on the same server as Mastodon.
# sudo systemctl start elasticsearch

sudo -u mastodon zsh <<"EOF"
export RAILS_ENV=production
cd /home/mastodon/live
source /home/mastodon/.zshrc
echo Clearing cache...
./bin/tootctl cache clear
echo Running post-deployment migrations...
bundle exec rails db:migrate
echo Rebuilding feeds...
./bin/tootctl feeds clear
./bin/tootctl feeds build
EOF
