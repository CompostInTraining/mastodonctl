#!/usr/bin/env -S bash -e

sudo -u mastodon zsh <<"EOF"
export RAILS_ENV=production
cd /home/mastodon/live
source /home/mastodon/.zshrc
git pull
bundle install
yarn install
SKIP_POST_DEPLOYMENT_MIGRATIONS=true bundle exec rails db:migrate
bundle exec rails assets:precompile
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
