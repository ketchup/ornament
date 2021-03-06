class OrnamentGenerator < Rails::Generators::Base

  source_root File.expand_path("../templates", __FILE__)

  class_option :components,   :type => :boolean, :default => true
  class_option :core,         :type => :boolean, :default => true
  class_option :development,  :type => :boolean, :default => false
  class_option :gems,         :type => :boolean, :default => true
  class_option :layouts,      :type => :boolean, :default => true
  class_option :styleguide,   :type => :boolean, :default => true
  class_option :example,      :type => :boolean, :default => false
  class_option :uploader,     :type => :boolean, :default => true
  class_option :helpers,      :type => :boolean, :default => true

  GEMS = {
    'htmlentities'      => '~> 4.3.4',
    'simple-navigation' => '~> 3.14.0',
    'webpacker'         => '~> 3.5',
    'foreman'           => '~> 0.64.0',
    'react_on_rails'    => '~> 11.1.4',
  }

  def generate

    if options.gems?
      gemfile = File.read('Gemfile')
      GEMS.each do |name, version|
        unless gemfile.include?(name)
          if version.present?
            gem name.dup, version
          else
            gem name.dup
          end
        end
      end
      Bundler.with_clean_env do
        run "bundle install"
      end
    end

    unless options.development?

      if options.core?

        # Install webpacker
        Bundler.with_clean_env do
          if Rails::VERSION::MAJOR == 5
            run "bundle exec rails webpacker:install"
            run "bundle exec rails webpacker:install:react"
          else
            run "bundle exec rake webpacker:install"
            run "bundle exec rake webpacker:install:react"
          end
        end

        # Install react on rails
        run "rails generate react_on_rails:install --ignore-warnings"

        # Clean up after react on rails
        remove_file "app/controllers/hello_world_controller.rb"
        remove_file "app/javascript"
        remove_file "app/views/layouts/hello_world.html.erb"
        remove_file "app/views/hello_world"
        gsub_file "config/routes.rb", "get 'hello_world', to: 'hello_world#index'", ""

        # Remove default assets
        remove_file "app/assets/stylesheets/application.css"
        remove_file "app/assets/javascripts/application.js"

        # Copy frontend assets
        remove_file "app/javascript"
        directory "../../../../test/dummy/app/frontend", "app/frontend"

        # Copy over webpacker configs
        directory "../../../../test/dummy/config/webpack", "config/webpack"
        copy_file "../../../../test/dummy/config/webpacker.yml", "config/webpacker.yml"
        copy_file "../../../../test/dummy/package.json", "package.json"

        # Linters
        copy_file "../../../../test/dummy/.babelrc", ".babelrc"
        copy_file "../../../../test/dummy/.browserslistrc", ".browserslistrc"
        copy_file "../../../../test/dummy/.editorconfig.ini", ".editorconfig.ini"
        copy_file "../../../../test/dummy/.eslintrc.json", ".eslintrc.json"
        copy_file "../../../../test/dummy/.postcssrc.yml", ".postcssrc.yml"
        copy_file "../../../../test/dummy/.sass-lint.yml", ".sass-lint.yml"
        copy_file "../../../../test/dummy/.nvmrc", ".nvmrc"
        copy_file "../../../../test/dummy/Procfile.dev", "Procfile.dev"
        copy_file "../../../../test/dummy/Procfile.dev-server", "Procfile.dev-server"

        # Rerun yarn
        Bundler.with_clean_env do
          run "yarn"
        end

        # Koi sprockets files
        directory "app/assets/stylesheets/koi"
        copy_file "config/initializers/ornament.rb"

        # Public folder with custom error and maintenance templates
        directory "public"

        # simple_form config
        copy_file "config/initializers/simple_form.rb"

        # Custom datetime formats
        copy_file "../../../../test/dummy/config/initializers/datetime_formats_ornament.rb", "config/initializers/datetime_formats_ornament.rb"

        # Default language file
        copy_file "config/locales/en.yml"
      end

      # Uploader files
      if options.uploader?
        unless options.example?
          # drag and drop image uploader dependancies
          route "end"
          route "  post :image, on: :collection"
          route "resources :uploads do"
          copy_file "app/controllers/uploads_controller.rb"
        end
        copy_file "app/views/koi/crud/_form_field_uploader.html.erb"
      end

      # Rails views and layouts
      if options.layouts?
        directory "app/views/layouts"
        directory "app/views/errors"
        directory "app/views/kaminari"
        directory "app/views/shared"
        directory "app/views/service_worker"
      end

      # Rails helpers
      if options.helpers?
        copy_file "../../../../test/dummy/app/helpers/ornament_google_maps_helper.rb", "app/helpers/ornament_google_maps_helper.rb"
        copy_file "../../../../test/dummy/app/helpers/ornament_helper.rb", "app/helpers/ornament_helper.rb"
        copy_file "../../../../test/dummy/app/helpers/ornament_koi_helper.rb", "app/helpers/ornament_koi_helper.rb"
        copy_file "../../../../test/dummy/app/helpers/ornament_seo_helper.rb", "app/helpers/ornament_seo_helper.rb"
        copy_file "../../../../test/dummy/app/helpers/ornament_styleguide_helper.rb", "app/helpers/ornament_styleguide_helper.rb"
        copy_file "../../../../test/dummy/app/helpers/ornament_svg_helper.rb", "app/helpers/ornament_svg_helper.rb"
        copy_file "../../../../test/dummy/app/renderers/ornament_nav_renderer.rb", "app/renderers/ornament_nav_renderer.rb"
      end

      # Styleguide files
      if options.styleguide?
        directory "app/views/styleguide"
        copy_file "../../../../test/dummy/config/styleguide_sample_navigation.rb", "config/styleguide_sample_navigation.rb"

        # These lines can be added to example app manually, they should only be added once and will just
        # get in the way when generating again, so can be avoided with --example
        unless options.example?
          route "get '/service-worker' => 'service_worker#index', format: :js, as: :service_worker"
          route "get '/site' => 'service_worker#webmanifest', format: :webmanifest, as: :webmanifest"
          route "# PWA Routes"
          route "get '/styleguide/:action' => 'styleguide' if Rails.env.development?"
          route "get '/styleguide' => 'styleguide#index' if Rails.env.development?"
          copy_file "app/controllers/styleguide_controller.rb"
          copy_file "app/controllers/service_worker_controller.rb"
          copy_file "../../../../test/dummy/app/helpers/ornament_helper.rb", "app/helpers/ornament_helper.rb"
          copy_file "../../../../test/dummy/app/helpers/ornament_google_maps_helper.rb", "app/helpers/ornament_google_maps_helper.rb"
          copy_file "../../../../test/dummy/app/helpers/ornament_koi_helper.rb", "app/helpers/ornament_koi_helper.rb"
          copy_file "../../../../test/dummy/app/helpers/ornament_seo_helper.rb", "app/helpers/ornament_seo_helper.rb"
        end

      end

    end

    puts ""
    puts "Ornament is now installed! But wait, in case you haven't already, please follow these manual steps to complete installation:"
    puts ""
    puts "Please ensure the following gems are in your local Gemfile:"
    puts ""
    GEMS.each do |name, version|
    puts "   gem #{name}, #{version}"
    end
    puts ""
    puts "Then bundle and restart your server"
    puts ""

  end

end
