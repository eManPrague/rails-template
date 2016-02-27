# Capistrano 3 config
lock '3.4.0'

set :repo_url, ''
BUILD_VERSION = "0.0.0/#{fetch(:stage}"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
set :scm, 'git'
set :scm_verbose, true

# Default value for :format is :pretty
# set :format, :pretty

set :bundle_flags, '--verbose'

set :default_stage, 'development'

set :rbenv_type, :user
set :rbenv_ruby, '2.3.0'

set :whenever_identifier, -> { "#{fetch(:stage)}" }

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# dirs we want symlinking to shared
set :linked_dirs, %w(log tmp vendor/bundle public/system config/settings)
set :linked_files, %w(config/database.yml config/config.yml config/puma.rb)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      # execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  before :restart, :set_current_revision do
    deploy_date = Time.now.strftime('%F %R')
    build_version = "#{BUILD_VERSION} @#{fetch(:current_revision)} (#{deploy_date})"
    on roles(:web), in: :parallel do
      execute "echo '@#{fetch(:current_revision)} #{release_timestamp}' > #{current_path}/REVISION"
      execute "echo '#{build_version}' > #{current_path}/BUILD_VERSION"
    end
  end
end

after 'deploy:finished', 'airbrake:deploy'
