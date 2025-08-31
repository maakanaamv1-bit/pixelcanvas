# pixelcanvas/Rakefile

require_relative 'config/application'

# Load Rails application
Rails.application.load_tasks

# Default rake task
task default: [:environment]

# Database tasks
namespace :db do
  desc "Create the database"
  task :create => :environment do
    Rails.logger.info "Creating database..."
    Rake::Task['db:create'].invoke
  end

  desc "Drop the database"
  task :drop => :environment do
    Rails.logger.info "Dropping database..."
    Rake::Task['db:drop'].invoke
  end

  desc "Migrate the database"
  task :migrate => :environment do
    Rails.logger.info "Running migrations..."
    Rake::Task['db:migrate'].invoke
  end

  desc "Seed the database"
  task :seed => :environment do
    Rails.logger.info "Seeding database..."
    Rake::Task['db:seed'].invoke
  end

  desc "Reset the database (drop, create, migrate, seed)"
  task :reset => :environment do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:seed'].invoke
  end
end

# Assets tasks
namespace :assets do
  desc "Precompile assets for production"
  task :precompile => :environment do
    Rails.logger.info "Precompiling assets..."
    Rake::Task['assets:precompile'].invoke
  end

  desc "Clean precompiled assets"
  task :clean => :environment do
    Rails.logger.info "Cleaning assets..."
    Rake::Task['assets:clean'].invoke
  end
end

# Custom tasks
namespace :pixelcanvas do
  desc "Clear temporary files"
  task :clear_tmp => :environment do
    Rails.logger.info "Clearing tmp files..."
    Rake::Task['tmp:clear'].invoke
  end

  desc "Display current environment"
  task :env => :environment do
    puts "Current Rails environment: #{Rails.env}"
  end

  desc "Restart server (useful for Heroku)"
  task :restart_server do
    puts "Restarting server..."
    system("touch tmp/restart.txt")
  end
end

# Load additional Rake tasks if any exist
Dir.glob('lib/tasks/**/*.rake').each { |r| import r }
