namespace :services do
  desc "Setup development environment with Docker"
  task :setup do
    puts "\e[32mSetting up PDF Editor development environment...\e[0m"

    # Copy .env.example to .env if it doesn't exist
    unless File.exist?(".env")
      FileUtils.cp(".env.example", ".env")
      puts "Created .env from .env.example"
    end

    # Build Docker images
    puts "\e[32mBuilding Docker images...\e[0m"
    system("docker-compose build") || abort("\e[31mFailed to build Docker images\e[0m")

    # Setup database
    puts "\e[32mSetting up database...\e[0m"
    system("docker-compose run --rm web rails db:setup") || abort("\e[31mFailed to setup database\e[0m")

    puts "\e[32mSetup complete! Run 'rake services:up' to start the application.\e[0m"
  end

  desc "Start all services"
  task :up do
    puts "\e[32mStarting PDF Editor...\e[0m"
    system("docker-compose up -d") || abort("\e[31mFailed to start services\e[0m")

    puts "\e[32mServices started!\e[0m"
    puts "  Rails app: http://localhost:3000"
    puts "  MailHog: http://localhost:8025"
  end
end