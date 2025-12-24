# Changelog

All notable changes to the Translation Platform project.

## [2.1.0] - 2025-12-24

### Added

#### AWS Deployment Infrastructure
- **Complete Terraform Configuration** ([terraform/](../terraform/))
  - Production-ready AWS infrastructure as code
  - VPC with public/private subnets across multiple AZs
  - ECS Fargate for serverless container orchestration
  - RDS PostgreSQL with automated backups
  - Application Load Balancer with SSL/TLS termination
  - ECR repositories for Docker images
  - CloudWatch logging and monitoring
  - Security groups and IAM roles
  - Auto-scaling capabilities

- **Terraform Modules**
  - [terraform/modules/networking](../terraform/modules/networking/) - VPC infrastructure
  - [terraform/modules/ecr](../terraform/modules/ecr/) - Container registry
  - [terraform/modules/rds](../terraform/modules/rds/) - PostgreSQL database
  - [terraform/modules/alb](../terraform/modules/alb/) - Load balancer
  - [terraform/modules/ecs](../terraform/modules/ecs/) - ECS services

- **Deployment Tools**
  - [terraform/scripts/deploy.sh](../terraform/scripts/deploy.sh) - Automated deployment script
  - Environment configurations for dev/staging/prod
  - Cost estimation and optimization guide

- **Documentation**
  - [docs/AWS_DEPLOYMENT.md](AWS_DEPLOYMENT.md) - Complete AWS deployment guide
  - [terraform/README.md](../terraform/README.md) - Infrastructure documentation
  - Architecture diagrams and best practices
  - Monitoring and troubleshooting guides
  - Security hardening recommendations

## [2.0.2] - 2025-12-24

### Added

#### Profile Page
- **New Profile Page** ([frontend/src/app/profile/page.tsx](../frontend/src/app/profile/page.tsx))
  - Translators can update their name, languages, hourly rate
  - Availability toggle to control booking visibility
  - Profile tips and guidance
  - Success/error message feedback

### Fixed

#### Authentication
- **Fixed Authentication Persistence** - All protected pages now properly check authentication on load
  - Calendar page redirects to login if not authenticated
  - Dashboard page redirects to login if not authenticated
  - Profile page redirects to login if not authenticated
  - Home page properly checks auth before routing
- **Fixed useEffect Dependencies** - Removed dependency arrays that caused infinite loops
  - Used async function pattern for better error handling
  - Authentication only runs once on mount

## [2.0.1] - 2025-12-24

### Changed

#### Database
- **Updated init.sql** ([database/init.sql](../database/init.sql))
  - Complete schema with all tables: companies, bookings, users, calls, queue
  - All enums: userrole, callstatus, bookingstatus, language
  - Proper indexes for query optimization
  - Foreign key constraints
  - Sample admin and agent users
  - Instructions for seeding complete test data

## [2.0.0] - 2025-12-23

### Added

#### Navigation & UI Improvements
- **New Navigation Component** ([frontend/src/components/Navigation.tsx](../frontend/src/components/Navigation.tsx))
  - Role-based navigation menu
  - User profile display in header
  - Logout functionality
  - Responsive design

#### Home Page Routing
- **Smart Role-Based Redirect** ([frontend/src/app/page.tsx](../frontend/src/app/page.tsx))
  - Translators → Calendar view
  - Employees → Calendar view
  - Company Admins → Calendar view
  - System Admins/Agents/Supervisors → Dashboard view

#### Test Data
- **Database Seeding** ([backend/seed_data.py](../backend/seed_data.py))
  - 5 companies with realistic data
  - 8 translators across Spanish, French, German
  - 19 employees (14 regular + 5 company admins)
  - All accounts use password: `password123`

- **Test Accounts Documentation** ([docs/TEST_ACCOUNTS.md](TEST_ACCOUNTS.md))
  - Complete list of all test users
  - Company-employee relationships
  - Translator languages and rates
  - Quick test scenarios

#### Database Schema Updates
- **Migration SQL Script** ([backend/migrate_db.sql](../backend/migrate_db.sql))
  - Added columns: `languages`, `is_available`, `hourly_rate`, `company_id` to users table
  - Created `companies` table
  - Created `bookings` table with indexes
  - Updated UserRole enum with new values: TRANSLATOR, EMPLOYEE, COMPANY_ADMIN

### Changed

#### Updated Pages
- **Calendar Page** - Now includes navigation component
- **Dashboard Page** - Added navigation, removed WebSocket connection issues
- **Layout** - Updated metadata and structure

#### Documentation
- **Main README** - Updated with new service URLs and navigation info
- **Docs README** - Added TEST_ACCOUNTS.md reference
- **API Endpoints** - Updated to reflect translation platform instead of call center

### Fixed

#### Backend
- **Model Imports** - Added Booking and Company to [backend/app/models/__init__.py](../backend/app/models/__init__.py)
- **Database Schema** - Migrated existing database to support new columns and tables
- **PostgreSQL Enum** - Added new UserRole values to existing enum

#### Frontend
- **TypeScript Types** - Fixed UserRole enum values in [frontend/src/types/index.ts](../frontend/src/types/index.ts)
- **Navigation Type Errors** - Fixed role comparison to handle both enum and string values
- **Build Errors** - Resolved all compilation errors

### Technical Details

#### Files Created
```
frontend/src/components/Navigation.tsx
backend/seed_data.py
backend/migrate_db.sql
docs/TEST_ACCOUNTS.md
docs/CHANGELOG.md
```

#### Files Modified
```
frontend/src/app/page.tsx
frontend/src/app/calendar/page.tsx
frontend/src/app/dashboard/page.tsx
frontend/src/types/index.ts
backend/app/models/__init__.py
backend/app/main.py
docs/README.md
README.md
```

#### Database Changes
- Added columns to `users` table for translator/employee features
- Created `companies` table with foreign key relationship
- Created `bookings` table with foreign keys to users and companies
- Added indexes for query optimization
- Extended UserRole enum with new values

### Migration Guide

If you have an existing database, run the migration:

```bash
docker exec -i callcenter-postgres psql -U callcenter -d callcenter < backend/migrate_db.sql
```

To seed test data:

```bash
docker exec callcenter-backend python seed_data.py
```

To rebuild and restart the stack:

```bash
./stack.sh stop
docker-compose build
./stack.sh start
```

### Breaking Changes

- User roles changed from AGENT/SUPERVISOR to TRANSLATOR/EMPLOYEE/COMPANY_ADMIN
- Home page now redirects based on role instead of always going to dashboard
- Navigation menu is now required on all authenticated pages

### Known Issues

- WebSocket connection shows 403 errors in logs (not critical, legacy feature)
- Legacy AGENT/SUPERVISOR roles still exist in database for backward compatibility

## [1.0.0] - 2025-12-22

### Initial Release
- Basic call center platform with Jitsi integration
- User authentication with JWT
- Database setup with Docker
- Frontend with Next.js
- Backend with FastAPI
