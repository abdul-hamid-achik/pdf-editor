# PDF Editor - Rails Application

A modern Rails 8 application for creating and editing PDFs using HexaPDF, featuring template-based PDF generation, real-time preview with Hotwire, and S3-compatible storage.

## 🚀 Features

- **PDF Generation**: Pure Ruby PDF creation using HexaPDF (no external dependencies)
- **Template System**: Reusable PDF templates with variable interpolation
- **Interactive Editor**: Real-time editing with Turbo Streams and Stimulus
- **Snippet Management**: Reusable PDF components (headers, footers, watermarks)
- **Version Control**: Track document changes and versions
- **Storage**: Local file system storage for development, Railway blob storage for production
- **Modern UI**: TailwindCSS with responsive design

## 🛠 Technology Stack

- **Ruby**: 3.3.0+
- **Rails**: 8.0+
- **PDF Engine**: HexaPDF (pure Ruby)
- **Database**: PostgreSQL (Neon-compatible)
- **Storage**: Local file system / Railway blob
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Styling**: TailwindCSS
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache

## 🐳 Docker Development Setup

The easiest way to get started is using Docker Compose, which sets up all necessary services:

### Prerequisites

- Docker and Docker Compose installed
- Git

### Quick Start

1. **Clone the repository**
```bash
git clone <repository-url>
cd pdf-editor
```

2. **Setup environment**
```bash
# Copy environment variables
cp .env.example .env

# Edit .env with your preferred settings (optional - defaults work for development)
# The defaults are configured for Docker development
```

3. **Setup and start the application**
```bash
# One command setup (builds, installs dependencies, sets up database)
rake services:setup

# Start all services
rake services:up
```

4. **Access the application**
- **Rails App**: http://localhost:3000
- **MailHog**: http://localhost:8025 (email testing)
- **PgAdmin**: http://localhost:5050 (admin@example.com/admin123) - run `rake services:up_with_tools`

### Available Rake Tasks

#### Development Tasks
```bash
rake services:setup         # Initial setup (build, bundle, database)
rake services:up            # Start all services
rake services:down          # Stop all services
rake services:restart       # Restart services
rake services:logs          # View all logs
rake services:logs_web      # View Rails app logs
rake services:ps            # Show running containers
```

#### Rails Tasks in Docker
```bash
rake services:console       # Open Rails console
rake services:bash          # Open bash shell in web container
rake services:bundle        # Install gems
rake services:yarn          # Install JavaScript packages
rake services:test          # Run tests
rake services:rubocop       # Run code linting
rake services:rubocop_fix   # Fix code style issues
```

#### Database Tasks
```bash
rake services:db:setup      # Setup database (create, migrate, seed)
rake services:db:create     # Create database
rake services:db:migrate    # Run migrations
rake services:db:seed       # Seed database
rake services:db:reset      # Reset database
rake services:db:console    # Open database console
```

#### Utility Tasks
```bash
rake services:stats         # Show container resource usage
rake services:clean         # Clean containers (keeps data)
rake services:clean_all     # Clean everything including data (WARNING!)
```

## 🗃 Services Overview

### Core Services

- **web**: Rails application server
- **db**: PostgreSQL database  
- **Built-in Rails 8**: Solid Cache, Solid Queue, and Solid Cable for all background services

### Development Tools (Optional)

- **mailhog**: Email testing (catches all outbound emails)
- **pgadmin**: Database administration GUI

## 📁 Project Structure

```
pdf-editor/
├── app/
│   ├── services/pdf/           # PDF generation services
│   │   ├── generator_service.rb
│   │   ├── editor_service.rb
│   │   ├── template_processor.rb
│   │   └── preview_generator.rb
│   ├── models/                 # ActiveRecord models
│   │   ├── pdf_document.rb
│   │   ├── pdf_template.rb
│   │   ├── pdf_snippet.rb
│   │   └── pdf_element.rb
│   ├── controllers/            # Rails controllers
│   └── components/             # ViewComponents (to be added)
├── config/
│   ├── database.yml           # Database configuration
│   └── storage.yml            # Active Storage configuration
├── db/
│   └── migrate/               # Database migrations
├── lib/tasks/
│   └── services.rake          # Service management tasks
├── docker-compose.yml         # Development Docker setup
├── Dockerfile                 # Production image
├── Dockerfile.dev             # Development image
└── .env.example               # Environment variables template
```

## 🔧 Configuration

### Environment Variables

Key configuration options in `.env`:

```bash
# Database
DATABASE_URL=postgresql://pdf_editor:password123@localhost:5432/pdf_editor_development

# Rails
RAILS_ENV=development
RAILS_MASTER_KEY=your_master_key_here
```

### Storage Configuration

The application uses Active Storage with different backends per environment:

- **Development**: Local file system storage
- **Production**: Railway blob storage (volume-based)

## 🧪 Testing

Run the test suite in Docker:

```bash
# Run all tests
rake services:test

# Run with coverage
rake services:test COVERAGE=true

# Run specific test file
docker-compose run --rm -e RAILS_ENV=test web rspec spec/models/pdf_document_spec.rb
```

## 📊 Monitoring and Health Checks

The application includes health check endpoints:

- **Basic**: `/up` - Rails default health check
- **Comprehensive**: `/health` - Checks database and storage connectivity

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`rake services:test`)
5. Run linting (`rake services:rubocop_fix`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

1. **Port conflicts**: If ports are in use, update `.env` with different port numbers
2. **Database connection issues**: Run `rake services:db:setup` to initialize the database
3. **Storage issues**: Check that local storage directory has proper permissions
4. **Memory issues**: Increase Docker memory allocation in Docker Desktop settings

### Getting Help

- Check the logs: `rake services:logs`
- Inspect containers: `rake services:ps`
- Reset everything: `rake services:clean_all` (⚠️ deletes all data)

### Development Workflow

```bash
# Daily development cycle
rake services:up         # Start services
rake services:logs_web   # Watch Rails logs in another terminal

# Make changes to code (hot reload enabled)

rake services:test       # Run tests
rake services:rubocop    # Check code style

# When done
rake services:down       # Stop services
```

## 🎯 Next Steps

- [ ] Implement authentication system
- [ ] Add user interface components
- [ ] Create PDF templates library
- [ ] Add real-time collaboration
- [ ] Implement PDF form filling
- [ ] Add advanced image editing