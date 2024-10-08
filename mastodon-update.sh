#!/usr/bin/env -S bash -e

now=$(date --iso-8601=seconds)

echo $now

# Check rbenv version
sudo -u mastodon zsh <<"EOF"
cd /home/mastodon/live
source /home/mastodon/.zshrc
ruby_version=$(cat .ruby-version)
installed_ruby_version=$(rbenv local)
if [ "$ruby_version" != "$installed_ruby_version" ]; then
    echo Upgrading Ruby...
    git -C "$(rbenv root)"/plugins/ruby-build pull
    rbenv install "$ruby_version"
else
    echo Ruby does not need upgrading.
fi
EOF

sudo -u mastodon zsh <<"EOF"
export RAILS_ENV=production
cd /home/mastodon/live
source /home/mastodon/.zshrc
git pull
bundle install
yarn install
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

# Comment the following lines if your instances does not uses ES for search
sudo -u mastodon zsh <<"EOF"
export RAILS_ENV=production
cd /home/mastodon/live
source /home/mastodon/.zshrc
echo Deploying search...
./bin/tootctl search deploy
EOF
