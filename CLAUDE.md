# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

HandloaderPro is an ammunition reloading management application built on Jumpstart Pro Rails (commercial SaaS starter). It tracks bullets, powders, primers, cartridges, and complete reloading sessions with detailed recipe data. Built with Rails 8.0 and modern Rails patterns for multi-tenant SaaS applications.

## Development Commands

```bash
# Initial setup
bin/setup                    # Install dependencies and setup database

# Development server
bin/dev                      # Start with Overmind (Rails server + asset watching + job worker)
bin/rails server            # Standard Rails server only

# Database
bin/rails db:prepare         # Setup database (creates, migrates, seeds)
bin/rails db:migrate         # Run migrations
bin/rails db:seed           # Seed database with reloading data
bin/rails db:reset          # Drop, create, migrate, and seed

# Testing  
bin/rails test              # Run Minitest suite
bin/rails test:system       # Run system tests (Capybara + Selenium)
bin/rails test test/models/bullet_test.rb  # Run single test file

# Code quality
bin/rubocop                 # Run RuboCop linter (configured in .rubocop.yml)
bin/rubocop -a              # Auto-fix RuboCop issues
bin/brakeman                # Security analysis
bin/bundler-audit           # Audit gems for vulnerabilities

# Background jobs
bin/jobs                    # Start SolidQueue worker

# Rails console
bin/rails console           # Interactive Rails console
bin/rails c                 # Short version

# Routes
bin/rails routes            # List all routes
bin/rails routes -g user   # Grep routes for 'user'

# Assets (if needed)
bin/rails assets:precompile  # Precompile assets for production
```

## Architecture

### Multi-tenancy System
- **Account-based tenancy**: Users belong to Accounts (personal or team)
- **AccountUser model**: Join table managing user-account relationships with roles
- **Current account**: Available via `current_account` helper in controllers/views
- **Account switching**: Users can switch between accounts via `switch_account(account)` in tests
- **Authorization**: Pundit policies scope ALL data by current account

### Domain Models (Reloading-specific)
Core entities for ammunition reloading:
- `ReloadingSession` - Central model capturing complete reloading recipe data
- `Bullet` - Projectiles with ballistic coefficient, sectional density, weight, length
- `Powder` - Propellants with burn rate data
- `Primer` & `PrimerType` - Ignition components
- `Cartridge` & `CartridgeType` - Ammunition cases
- `Caliber` - Bullet diameters
- `Manufacturer` & `ManufacturerType` - Component manufacturers

All models are scoped to `Account` for multi-tenancy.

### Modular Models Pattern
Models use Ruby modules for clean organization:
```ruby
class User < ApplicationRecord
  include Accounts, Agreements, Authenticatable, Mentions, Notifiable, Searchable, Theme
end

class Account < ApplicationRecord  
  include Billing, Domains, Transfer, Types
end
```

### Jumpstart Configuration System
- **Configuration file**: `config/jumpstart.yml` controls enabled features
- **Runtime gem loading**: `Gemfile.jumpstart` loads gems based on configuration
- **Feature toggles**: Payment processors, integrations, background jobs
- Access via `Jumpstart.config.payment_processors`, `Jumpstart.config.stripe?`

### Payment Architecture
- **Pay gem (~11.0)**: Unified interface for Stripe, Paddle, Braintree, PayPal, Lemon Squeezy
- **Per-seat billing**: Team accounts with usage-based pricing
- **Subscription management**: In `app/models/account/billing.rb`
- **Billing features**: Conditionally loaded based on `Jumpstart.config.payments_enabled?`

### Service Objects Pattern
Use Service Objects for complex business logic:
```ruby
# app/services/create_user_service.rb
class CreateUserService
  def initialize(params)
    @params = params
  end
  
  def run
    # Complex business logic here
  end
end
```

## Technology Stack

- **Rails 8.0** with modern conventions (positional enum arguments, etc.)
- **Ruby 3.2+** (see `.ruby-version` for exact version)
- **PostgreSQL** (primary), **SolidQueue** (jobs), **SolidCache** (cache), **SolidCable** (websockets)
- **Hotwire** (Turbo + Stimulus) for frontend interactivity
- **Import Maps** for JavaScript (no Node.js/npm dependency)
- **Email delivery**: Mailgun, Mailpace, and Postmark use API gems instead of SMTP
- **API client errors**: Raise `UnprocessableContent` for 422 responses (rfc9110)

## Technology Stack

- **Rails 8** with Hotwire (Turbo + Stimulus) and Hotwire Native
- **PostgreSQL** (primary), **SolidQueue** (jobs), **SolidCache** (cache), **SolidCable** (websockets)
- **Import Maps** for JavaScript (no Node.js dependency)
- **TailwindCSS v4** via tailwindcss-rails gem
- **Devise** for authentication with custom extensions
- **Pundit** for authorization policies
- **Minitest** for testing with parallel execution
- **Madmin** (~2.0) for admin interface

## Code Conventions

### Rails 8.0 Patterns
- Use `Rails.application.credentials` for secrets (not `.secrets`)
- Pass models to jobs, not IDs (automatic serialization)
- Use positional arguments in enums: `enum status: [:draft, :published, :archived]`
- Use `has_prefix_id` for models with UUIDs
- Use class namespacing: `class Api::V1::UsersController`

### Ruby Style
- 2 spaces for indentation
- snake_case for variables/methods
- YARD documentation for methods and classes
- Use concerns for shared functionality
- Follow Rubocop rules in `.rubocop.yml`

### Frontend Patterns
- All UI components must support responsive design and dark mode
- Use Stimulus controllers for JavaScript behavior
- Use View Components for reusable UI elements
- Follow TailwindCSS conventions

## Testing

- **Framework**: Minitest with fixtures in `test/fixtures/`
- **System tests**: Capybara with Selenium WebDriver
- **Parallel execution**: Enabled via `parallelize(workers: :number_of_processors)`
- **WebMock**: Configured to disable external HTTP requests
- **Test helpers**: Custom helpers for multi-tenancy (account switching)

## Routes Organization

Routes are modularized in `config/routes/`:
- `accounts.rb` - Account management, switching, invitations
- `billing.rb` - Subscription, payment, receipt routes
- `users.rb` - User profile, settings, authentication
- `api.rb` - API v1 endpoints with JWT authentication

## Key Directories

- `app/controllers/accounts/` - Account-scoped controllers
- `app/controllers/admin/` - Admin interface controllers
- `app/models/concerns/` - Shared model modules
- `app/policies/` - Pundit authorization policies
- `app/services/` - Service objects for complex business logic
- `app/components/` - View components for reusable UI
- `lib/jumpstart/` - Core Jumpstart engine and configuration
- `lib/tasks/` - Custom rake tasks including data imports
- `config/routes/` - Modular route definitions
- `.cursor/rules/` - Cursor IDE rules for Rails conventions

## Data Import System

Custom rake tasks for importing reloading data:
```bash
bin/rails data:import_bullets    # Import bullet data from external sources
```

## Development Notes

- **Multi-database setup**: Separate databases for cache, jobs, and cable
- **Background jobs**: Configurable between SolidQueue and Sidekiq
- **Process management**: Overmind manages development processes via `Procfile.dev`
- **Docker support**: Multi-stage builds for deployment
- **Health checks**: Available at `/up` endpoint
- **API tokens**: For programmatic access with JWT authentication
- **Two-factor auth**: TOTP support with recovery codes
- **Sudo mode**: For sensitive operations