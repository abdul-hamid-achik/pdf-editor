namespace :services do
  desc "Setup development environment with Docker"
  task :setup do
    puts "\e[32mSetting up PDF Editor development environment...\e[0m"
    
    # Copy .env.example to .env if it doesn't exist
    unless File.exist?('.env')
      FileUtils.cp('.env.example', '.env')
      puts "Created .env from .env.example"
    end
    
    # Build Docker images
    Rake::Task['services:build'].invoke
    
    # Setup database
    Rake::Task['services:db:setup'].invoke
    
    puts "\e[32mSetup complete! Run 'rake services:up' to start the application.\e[0m"
  end
  
  desc "Build Docker images"
  task :build do
    puts "\e[32mBuilding Docker images...\e[0m"
    system("docker-compose build") || abort("\e[31mFailed to build Docker images\e[0m")
  end
  
  desc "Start all services"
  task :up do
    puts "\e[32mStarting PDF Editor...\e[0m"
    system("docker-compose up -d") || abort("\e[31mFailed to start services\e[0m")
    
    puts "\e[32mServices started!\e[0m"
    puts "  Rails app: http://localhost:3000"
    puts "  MinIO Console: http://localhost:9001"
    puts "  MailHog: http://localhost:8025"
    puts "  PgAdmin: http://localhost:5050 (run 'rake services:up_with_tools' to enable)"
  end
  
  desc "Start with optional tools (PgAdmin)"
  task :up_with_tools do
    system("docker-compose --profile tools up -d")
  end
  
  desc "Stop all services"
  task :down do
    puts "\e[33mStopping services...\e[0m"
    system("docker-compose down")
  end
  
  desc "Restart all services"
  task restart: [:down, :up]
  
  desc "Show running containers"
  task :ps do
    system("docker-compose ps")
  end
  
  desc "Show logs from all services"
  task :logs do
    system("docker-compose logs -f")
  end
  
  desc "Show logs from web service"
  task :logs_web do
    system("docker-compose logs -f web")
  end
  
  desc "Open Rails console in Docker"
  task :console do
    puts "\e[32mOpening Rails console...\e[0m"
    exec("docker-compose exec web rails console")
  end
  
  desc "Open bash shell in web container"
  task :bash do
    exec("docker-compose exec web bash")
  end
  
  desc "Install Ruby dependencies"
  task :bundle do
    puts "\e[32mInstalling Ruby gems...\e[0m"
    system("docker-compose run --rm web bundle install")
  end
  
  desc "Install JavaScript dependencies"
  task :yarn do
    puts "\e[32mInstalling JavaScript packages...\e[0m"
    system("docker-compose run --rm web yarn install")
  end
  
  desc "Run tests in Docker"
  task :test do
    puts "\e[32mRunning tests...\e[0m"
    system("docker-compose run --rm -e RAILS_ENV=test web rspec")
  end
  
  desc "Run Rubocop in Docker"
  task :rubocop do
    system("docker-compose run --rm web rubocop")
  end
  
  desc "Run Rubocop with auto-fix in Docker"
  task :rubocop_fix do
    system("docker-compose run --rm web rubocop -a")
  end
  
  desc "Open MinIO console in browser"
  task :minio_console do
    puts "\e[32mOpening MinIO console...\e[0m"
    system("open http://localhost:9001 2>/dev/null || xdg-open http://localhost:9001 2>/dev/null || echo 'Please open http://localhost:9001 in your browser'")
  end
  
  desc "Clean up containers (preserves data)"
  task :clean do
    puts "\e[33mCleaning up containers...\e[0m"
    system("docker-compose down")
    system("docker system prune -f")
  end
  
  desc "Clean up everything including volumes (WARNING: deletes all data)"
  task :clean_all do
    puts "\e[31mWARNING: This will delete all data including database!\e[0m"
    print "Are you sure? [y/N] "
    
    if STDIN.gets.chomp.downcase == 'y'
      system("docker-compose down -v")
      system("docker system prune -af")
      puts "\e[32mCleanup complete.\e[0m"
    else
      puts "\e[33mCleanup cancelled.\e[0m"
    end
  end
  
  desc "Show container resource usage"
  task :stats do
    container_ids = `docker-compose ps -q`.strip.split("\n").join(" ")
    system("docker stats --no-stream #{container_ids}")
  end
  
  namespace :db do
    desc "Create database in Docker"
    task :create do
      puts "\e[32mCreating database...\e[0m"
      system("docker-compose run --rm web rails db:create")
    end
    
    desc "Run database migrations in Docker"
    task :migrate do
      puts "\e[32mRunning migrations...\e[0m"
      system("docker-compose run --rm web rails db:migrate")
    end
    
    desc "Seed database in Docker"
    task :seed do
      puts "\e[32mSeeding database...\e[0m"
      system("docker-compose run --rm web rails db:seed")
    end
    
    desc "Setup database in Docker (create, migrate, seed)"
    task :setup do
      puts "\e[32mSetting up database...\e[0m"
      system("docker-compose run --rm web rails db:setup")
    end
    
    desc "Reset database in Docker"
    task :reset do
      puts "\e[33mResetting database...\e[0m"
      system("docker-compose run --rm web rails db:reset")
    end
    
    desc "Open database console"
    task :console do
      exec("docker-compose exec db psql -U pdf_editor pdf_editor_development")
    end
  end
  
  namespace :prod do
    desc "Start production environment"
    task :up do
      puts "\e[32mStarting production environment...\e[0m"
      system("docker-compose -f docker-compose.yml -f docker-compose.production.yml up -d")
    end
    
    desc "Stop production environment"
    task :down do
      system("docker-compose -f docker-compose.yml -f docker-compose.production.yml down")
    end
    
    desc "Show production logs"
    task :logs do
      system("docker-compose -f docker-compose.yml -f docker-compose.production.yml logs -f")
    end
    
    desc "Build production images"
    task :build do
      puts "\e[32mBuilding production Docker images...\e[0m"
      system("docker-compose -f docker-compose.yml -f docker-compose.production.yml build")
    end
  end
end

# Convenience tasks at root level
desc "Start development services"
task services: 'services:up'

desc "Setup development services"
task setup: 'services:setup'