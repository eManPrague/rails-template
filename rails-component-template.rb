# Method to change gemspec
def add_dependency(dep, development = false)
  inject_into_file "#{name}.gemspec", after: / +s\.files.*$/ do <<-RUBY
    \n
    s.add_#{development ? 'development_' : ''}dependency '#{dep}'
    RUBY
  end
end

def slim?
  # Templating libraries
  if yes?("Do you want to use SLIM instead of ERB?")
    # Add dependency
    add_dependency('slim-rails')

    true
  else
    false
  end
end

def rspec?
  # Add rspec + spring
  if yes?('Do you want to use RSPEC + SPRING?')
    add_dependency('rspec-rails', true)
    add_dependency('spring', true)

    # Prepare spring environment
    run "echo \"Spring.application_root = './spec/dummy'\" > config/spring.rb"

    # Add test.sh files
    run "curl -o test.sh https://raw.githubusercontent.com/eManPrague/rails-template/master/test.sh"

    # Return true
    true
  else
    false
  end
end

def migrations?
  # Want to use migrations?
  yes?('Do you want use migrations?')
end

def update_engine
  # Change generator and engine file
  engine_filename = File.join('lib', name, 'engine.rb')

  # Add intializer for migrations
  if migrations?
    inject_into_file engine_filename, after: "isolate_namespace #{name.camelize}\n" do <<-RUBY
      # Append migrations
      initializer :append_migrations do |app|
        unless app.root.to_s.match root.to_s + File::SEPARATOR
          config.paths['db/migrate'].expanded.each do |path|
            app.config.paths['db/migrate'] << path
          end
        end
      end
    RUBY
    end
  end

  # Add use_slim and rspec
  use_slim = slim?
  use_rspec = rspec?

  if use_rspec
    after_bundle do
      # Rspec + capybara tests
      run "bundle exec rspec --init"
    end
  end

  if use_slim || use_rspec
    inject_into_file engine_filename, after: "isolate_namespace #{name.camelize}\n" do <<-RUBY
      config.generators do |g|
        #{use_slim ? "g.template_engine :slim" : ""}
        #{use_rspec ? "g.test_framework :rspec" : ""}
      end
    RUBY
    end
  end
end

# Actions
update_engine

