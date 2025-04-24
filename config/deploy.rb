# config valid for current version and patch releases of Capistrano
lock "~> 3.19.2"

set :application, "PlanningCenterYoutube"
set :repo_url, "git@github.com:bemky/planning-center-youtube.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/srv/yt-pc"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
append :linked_files, "config/credentials.yml.enc" #, "config/database.yml", "db/production.sqlite3"

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure
set :ssh_options, {
  :user           => 'yt-pc',
  # :forward_agent  => true,
  # :auth_methods   => %w(publickey)
}

set :default_env, {
  'RACK_ENV'  => fetch(:stage),
  'RAILS_ENV' => fetch(:stage)
}