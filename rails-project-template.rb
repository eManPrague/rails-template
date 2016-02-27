# base and useful gems
gem 'annotate'
gem 'pry-rails'
gem 'config'

gem_group :development, :test do
  gem 'byebug'
  gem 'spring'
  gem 'better_errors'
  gem 'binding_of_caller'
end

# base commands
run "echo -n > README.md"
run "echo -n > INSTALL.md"

# remove unneeded files
if no?("Do you want to use rdoc?") then
  run "rm README.rdoc"
end

# test libs
tests = false
if yes?("Do you want to write tests?") then
  gem_group :development, :test do
    gem "rspec-rails"
    gem 'simplecov'
    gem 'factory_girl_rails'
    gem 'faker'
    gem 'database_cleaner'
    gem 'spring-commands-rspec'
    gem 'guard-rspec'
    gem 'capybara'
    gem 'capybara-webkit'
  end
  
  tests = true
end

if yes?("Do you want to use puma?") then
  gem 'puma'
elsif yes?("Do you want to use thin?")
  gem 'thin'
else yes?("Do you want to use unicorn")
  gem 'unicorn'
end

# deployment tools
mina = capistrano = false
if yes?("Do you want to use capistrano for deploy?") then
  gem 'capistrano', '~> 3.3.0'
  gem 'capistrano-faster-assets'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  capistrano = true
elsif yes?("Do you want to use mina for deploy?")
  gem 'mina', '~> 0.3.8'
  gem 'mina-multistage', require: false
  mina = true
end

# static code analysis
rubocop = false
if yes?("Do you want to use code analytic tools and generate graphs?") then
  rubocop = true
  gem_group :development, :test do
    gem 'brakeman'
    gem 'railroady'
    gem "rubycritic"
    gem 'rubocop'
    gem 'traceroute'
    gem "rails_best_practices"
    gem 'ruby-graphviz', :require => 'graphviz'
  end
end

# prepare errbit
if yes?('Do you want to configure errbit?') then
  gem 'airbrake', '~> 4.3.5'

  errbit_key = ask("Errbit API key: ")
  errbit_host = ask("Errbit host: ")
  errbit_port = ask("Errbit port: ")

initializer 'errbit.rb', <<-CODE
Airbrake.configure do |config|
  config.api_key = '#{errbit_key}'
  config.host    = '#{errbit_host}'
  config.port    = '#{errbit_port}'
  config.secure  = config.port == 443
end
  CODE
end

after_bundle do
  # mina setup
  if mina == true then
    run "bundle exec mina init"
    run "echo -e \"set :stages, %w(development staging production)\nset :stages_dir, 'config/deploy'\nset :default_stage, 'development'\n\nrequire 'mina/multistage'\" | cat - config/deploy.rb > minatmp; mv minatmp config/deploy.rb"
    run "sed -i '/require \'mina/rbenv\'/s/\# //' config/deploy.rb"
    run "sed -i '/rbenv:load/s/\# //' config/deploy.rb"
    run "bundle exec mina multistage:init"
  end

  # capistrano setup
  if capistrano == true then
    run "bundle exec cap install STAGES=staging,development,production"
    run "curl -o Capfile https://raw.githubusercontent.com/eManPrague/rails-template/master/Capfile"
    run "curl -o config/deploy.rb https://raw.githubusercontent.com/eManPrague/rails-template/master/config/deploy.cap.rb"
  end

  # Rspec + capybara tests
  if tests
    run "bundle exec rspec:install"
  end

  # git setup
  git :init

  # install rubcop hook if rubocop turned on
  if rubocop == true then
    run "curl -o .git/hooks/pre-commit https://raw.githubusercontent.com/eManPrague/rails-template/master/hooks/pre-commit"
    run "chmod +x .git/hooks/pre-commit"
    run "curl -o .rubocop.yml https://raw.githubusercontent.com/eManPrague/rails-template/master/.rubocop.yml"
  end

  run "curl -o .gitignore https://raw.githubusercontent.com/eManPrague/rails-template/master/.gitignore"
  git add: ".gitignore"
  git commit: %Q{ -m 'default .gitignore commit'}
  git add: "."
  git commit: %Q{ -m 'Initial commit' }

end
