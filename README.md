# PDF Editor - Rails Application

A modern Rails 8 application for creating and editing PDFs using HexaPDF, featuring template-based PDF generation, real-time preview with Hotwire, and S3-compatible storage.

## 🚀 Features

- **PDF Generation**: Pure Ruby PDF creation using HexaPDF (no external dependencies)
- **Template System**: Reusable PDF templates with variable interpolation
- **Interactive Editor**: Real-time editing with Turbo Streams and Stimulus
- **Snippet Management**: Reusable PDF components (headers, footers, watermarks)
- **Version Control**: Track document changes and versions
- **Storage**: S3-compatible storage with MinIO for local development
- **Modern UI**: TailwindCSS with responsive design

## 🛠 Technology Stack

- **Ruby**: 3.3.0+
- **Rails**: 8.0+
- **PDF Engine**: HexaPDF (pure Ruby)
- **Database**: PostgreSQL (Neon-compatible)
- **Storage**: S3/MinIO
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
rake docker:setup

# Start all services
rake docker:up
```

4. **Access the application**
- **Rails App**: http://localhost:3000
- **MinIO Console**: http://localhost:9001 (minioadmin/minioadmin123)
- **MailHog**: http://localhost:8025 (email testing)
- **PgAdmin**: http://localhost:5050 (admin@example.com/admin123) - run `rake docker:up_with_tools`

### Available Rake Tasks

#### Development Tasks
```bash
rake docker:setup          # Initial setup (build, bundle, database)
rake docker:up              # Start all services
rake docker:down            # Stop all services
rake docker:restart         # Restart services
rake docker:logs            # View all logs
rake docker:logs_web        # View Rails app logs
rake docker:ps              # Show running containers
```

#### Rails Tasks in Docker
```bash
rake docker:console         # Open Rails console
rake docker:bash            # Open bash shell in web container
rake docker:bundle          # Install gems
rake docker:yarn            # Install JavaScript packages
rake docker:test            # Run tests
rake docker:rubocop         # Run code linting
rake docker:rubocop_fix     # Fix code style issues
```

#### Database Tasks
```bash
rake docker:db:setup        # Setup database (create, migrate, seed)
rake docker:db:create       # Create database
rake docker:db:migrate      # Run migrations
rake docker:db:seed         # Seed database
rake docker:db:reset        # Reset database
rake docker:db:console      # Open database console
```

#### Utility Tasks
```bash
rake docker:minio_console   # Open MinIO web console
rake docker:stats           # Show container resource usage
rake docker:clean           # Clean containers (keeps data)
rake docker:clean_all       # Clean everything including data (WARNING!)
```

#### Production Tasks
```bash
rake docker:prod:build      # Build production images
rake docker:prod:up         # Start production environment
rake docker:prod:down       # Stop production environment
rake docker:prod:logs       # View production logs
```

## 🗃 Services Overview

### Core Services

- **web**: Rails application server
- **db**: PostgreSQL database
- **redis**: Caching and session storage
- **minio**: S3-compatible object storage
- **sidekiq**: Background job processing

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
│   └── docker.rake            # Docker management tasks
├── docker-compose.yml         # Development Docker setup
├── docker-compose.production.yml  # Production overrides
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

# Storage (MinIO for local development)
AWS_ACCESS_KEY_ID=minioadmin
AWS_SECRET_ACCESS_KEY=minioadmin123
AWS_ENDPOINT=http://localhost:9000
AWS_BUCKET=pdf-documents

# Rails
RAILS_ENV=development
RAILS_MASTER_KEY=your_master_key_here
```

### Storage Configuration

The application uses Active Storage with S3-compatible backends:

- **Development**: MinIO (local S3-compatible storage)
- **Production**: AWS S3, Cloudflare R2, or any S3-compatible service

## 🧪 Testing

Run the test suite in Docker:

```bash
# Run all tests
rake docker:test

# Run with coverage
rake docker:test COVERAGE=true

# Run specific test file
docker-compose run --rm -e RAILS_ENV=test web rspec spec/models/pdf_document_spec.rb
```

## 🚀 Production Deployment

### Docker Production

1. **Build production image**
```bash
rake docker:prod:build
```

2. **Deploy with production compose**
```bash
rake docker:prod:up
```

### Environment Setup for Production

Update `.env` for production:

```bash
# Use real database (Neon recommended)
DATABASE_URL=postgresql://user:pass@neon-db-url/database

# Use real S3/R2 storage
AWS_ACCESS_KEY_ID=your_real_key
AWS_SECRET_ACCESS_KEY=your_real_secret
AWS_BUCKET=your_production_bucket
# Remove AWS_ENDPOINT for real S3

# Production secrets
SECRET_KEY_BASE=your_generated_secret
RAILS_MASTER_KEY=your_master_key
```

## 📊 Monitoring and Health Checks

The application includes health check endpoints:

- **Basic**: `/up` - Rails default health check
- **Comprehensive**: `/health` - Checks database, Redis, and storage connectivity

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`rake docker:test`)
5. Run linting (`rake docker:rubocop_fix`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

1. **Port conflicts**: If ports are in use, update `.env` with different port numbers
2. **Database connection issues**: Run `rake docker:db:setup` to initialize the database
3. **Storage issues**: Ensure MinIO is running with `docker-compose ps minio`
4. **Memory issues**: Increase Docker memory allocation in Docker Desktop settings

### Getting Help

- Check the logs: `rake docker:logs`
- Inspect containers: `rake docker:ps`
- Reset everything: `rake docker:clean_all` (⚠️ deletes all data)

### Development Workflow

```bash
# Daily development cycle
rake docker:up           # Start services
rake docker:logs_web     # Watch Rails logs in another terminal

# Make changes to code (hot reload enabled)

rake docker:test         # Run tests
rake docker:rubocop      # Check code style

# When done
rake docker:down         # Stop services
```

## 🎯 Next Steps

- [ ] Implement authentication system
- [ ] Add user interface components
- [ ] Create PDF templates library
- [ ] Add real-time collaboration
- [ ] Implement PDF form filling
- [ ] Add advanced image editing