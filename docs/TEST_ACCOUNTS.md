# Test Accounts

This document lists all test accounts created for the Translation Platform. All accounts use the password: `password123`

## Companies

The platform has 5 companies with employees:

| Company Name | Contact Email | Employees | Admin Email |
|--------------|---------------|-----------|-------------|
| TechCorp Global | contact@techcorp.com | 3 | admin@techcorp.com |
| MediHealth Services | admin@medihealth.com | 2 | admin@medihealth.com |
| Global Finance Inc | info@globalfinance.com | 4 | admin@globalfinance.com |
| EduLearn Platform | support@edulearn.com | 2 | admin@edulearn.com |
| RetailMax Corporation | hr@retailmax.com | 3 | admin@retailmax.com |

## Translators

8 professional translators are available:

| Name | Email | Languages | Hourly Rate | Available |
|------|-------|-----------|-------------|-----------|
| Maria Garcia | maria.garcia@translator.com | Spanish, French | $45/hour | ✓ |
| Jean Dupont | jean.dupont@translator.com | French | $50/hour | ✓ |
| Hans Mueller | hans.mueller@translator.com | German | $48/hour | ✓ |
| Carmen Rodriguez | carmen.rodriguez@translator.com | Spanish | $42/hour | ✓ |
| Klaus Schmidt | klaus.schmidt@translator.com | German, French | $55/hour | ✓ |
| Isabelle Martin | isabelle.martin@translator.com | French, Spanish | $47/hour | ✗ |
| Diego Sanchez | diego.sanchez@translator.com | Spanish | $40/hour | ✓ |
| Petra Wagner | petra.wagner@translator.com | German | $52/hour | ✓ |

## Company Employees

### TechCorp Global
- **Admin**: admin@techcorp.com
- **Employees**:
  - john.smith@techcorp.com (John Smith)
  - sarah.johnson@techcorp.com (Sarah Johnson)
  - mike.chen@techcorp.com (Mike Chen)

### MediHealth Services
- **Admin**: admin@medihealth.com
- **Employees**:
  - dr.emily.brown@medihealth.com (Dr. Emily Brown)
  - nurse.david.lee@medihealth.com (David Lee)

### Global Finance Inc
- **Admin**: admin@globalfinance.com
- **Employees**:
  - robert.wilson@globalfinance.com (Robert Wilson)
  - jennifer.davis@globalfinance.com (Jennifer Davis)
  - thomas.moore@globalfinance.com (Thomas Moore)
  - lisa.taylor@globalfinance.com (Lisa Taylor)

### EduLearn Platform
- **Admin**: admin@edulearn.com
- **Employees**:
  - prof.james.white@edulearn.com (Prof. James White)
  - amanda.harris@edulearn.com (Amanda Harris)

### RetailMax Corporation
- **Admin**: admin@retailmax.com
- **Employees**:
  - manager.kevin.clark@retailmax.com (Kevin Clark)
  - susan.lewis@retailmax.com (Susan Lewis)
  - daniel.walker@retailmax.com (Daniel Walker)

## Legacy Test Accounts

These accounts existed before the translation platform migration:

| Email | Role | Password |
|-------|------|----------|
| agent1@example.com | AGENT | password123 |
| supervisor@example.com | SUPERVISOR | password123 |
| admin@example.com | ADMIN | password123 |

## Quick Test Scenarios

### Scenario 1: Book a Spanish Translation
1. Login as: `john.smith@techcorp.com`
2. Go to Calendar page
3. Click "Book Translation"
4. Select translator: Maria Garcia or Carmen Rodriguez or Diego Sanchez
5. Choose date, duration (30 or 60 min), and add notes
6. Submit booking

### Scenario 2: Multilingual Translator
1. Login as: `robert.wilson@globalfinance.com`
2. Book with Klaus Schmidt (German & French) or Maria Garcia (Spanish & French)
3. Test calendar display and booking flow

### Scenario 3: Translator View
1. Login as: `maria.garcia@translator.com`
2. View calendar with your bookings
3. See upcoming translation sessions
4. Join meetings when they start

### Scenario 4: Company Admin Management
1. Login as: `admin@techcorp.com`
2. View all company bookings
3. Manage employee translation requests

## Database Seed Script

To recreate this data, run:

```bash
docker exec callcenter-backend python seed_data.py
```

Note: The seed script will skip if companies already exist in the database.

## Resetting Test Data

To completely reset the database and reseed:

```bash
# Stop the stack
./stack.sh stop

# Clean everything (removes volumes)
./stack.sh clean

# Start fresh
./stack.sh start

# Seed the database
docker exec callcenter-backend python seed_data.py
```
