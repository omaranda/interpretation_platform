# Translation Platform - Complete Guide

## Overview

The Translation Platform connects companies needing translation services with professional translators who speak Spanish, French, and German. The platform enables employees to book translation sessions (30 minutes or 1 hour) and conduct them via integrated Jitsi video conferencing.

## User Roles

### 1. Translators
Professional translators who offer services in one or more languages:
- Spanish
- French
- German

**Capabilities:**
- Register with supported languages
- Set hourly rates
- Manage availability status
- View their bookings in a calendar
- Join scheduled translation sessions

### 2. Employees
Company staff members who need translation services

**Capabilities:**
- Book translation sessions
- View their bookings in a calendar
- Join scheduled translation sessions
- Cancel bookings

### 3. Company Administrators
Manage company account and employees

**Capabilities:**
- View all company bookings
- Manage company employees
- Book translation sessions for the company

### 4. System Administrators
Platform administrators

**Capabilities:**
- Manage all users
- View all bookings
- Access all platform features

## Key Features

### Translator Registration
**URL:** http://localhost:3000/register/translator

Translators can self-register with:
- Full name
- Email address
- Password
- Languages (multiple selection)
- Hourly rate (optional)

After registration, translators can log in and access their dashboard.

### Calendar-Based Booking System
**URL:** http://localhost:3000/calendar

The calendar interface provides:
- **Month, Week, and Day views** - Navigate through different time periods
- **Visual booking overview** - See all scheduled translations at a glance
- **Color-coded events** - Different statuses (Pending, Confirmed, In Progress, Completed, Cancelled)
- **Click for details** - Select any booking to view full information
- **Quick booking** - "Book Translation" button for employees

### Booking a Translation Session

Employees can book translations by:
1. Clicking "Book Translation" in the calendar
2. Selecting a translator (filtered by language)
3. Choosing date and time
4. Selecting duration (30 minutes or 1 hour)
5. Selecting language (Spanish, French, or German)
6. Adding optional notes
7. Clicking "Book Now"

The system automatically:
- Checks translator availability
- Prevents double-booking
- Creates a unique Jitsi room
- Confirms the booking

### Video Conferencing Integration

Each booking includes an integrated Jitsi video room:
- **Auto-generated room names** - Unique for each session
- **Direct access** - "Join Meeting" button in booking details
- **Local Jitsi server** - Running at http://localhost:8443
- **No registration required** - Click and join

## Database Schema

### Users Table
```sql
- id (UUID, Primary Key)
- email (String, Unique)
- name (String)
- hashed_password (String)
- role (Enum: TRANSLATOR, EMPLOYEE, COMPANY_ADMIN, ADMIN)
- languages (Array[String]) - For translators
- is_available (Boolean) - For translators
- hourly_rate (String) - For translators
- company_id (UUID, Foreign Key) - For employees
```

### Companies Table
```sql
- id (UUID, Primary Key)
- name (String)
- contact_email (String, Unique)
- contact_phone (String)
- address (Text)
```

### Bookings Table
```sql
- id (UUID, Primary Key)
- translator_id (UUID, Foreign Key → users)
- employee_id (UUID, Foreign Key → users)
- company_id (UUID, Foreign Key → companies)
- start_time (DateTime)
- duration_minutes (Integer: 30 or 60)
- language (String: SPANISH, FRENCH, GERMAN)
- status (Enum: PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED)
- jitsi_room_name (String)
- notes (Text)
- created_at (DateTime)
- updated_at (DateTime)
```

## API Endpoints

### Translator Endpoints

#### POST /translators/register
Register a new translator
```json
{
  "email": "translator@example.com",
  "name": "John Translator",
  "password": "securepass",
  "languages": ["SPANISH", "FRENCH"],
  "hourly_rate": "$50/hour"
}
```

#### GET /translators/
Get list of translators
- Query params: `language`, `available_only`

#### GET /translators/{translator_id}
Get translator details

#### PUT /translators/{translator_id}/availability
Update translator availability
```json
{
  "translator_id": "uuid",
  "is_available": true
}
```

### Booking Endpoints

#### POST /bookings/
Create a new booking
```json
{
  "translator_id": "uuid",
  "start_time": "2025-12-24T10:00:00",
  "duration_minutes": 60,
  "language": "SPANISH",
  "notes": "Technical document translation"
}
```

#### GET /bookings/
Get bookings for current user
- Query params: `start_date`, `end_date`

#### GET /bookings/{booking_id}
Get booking details

#### PUT /bookings/{booking_id}
Update booking
```json
{
  "status": "COMPLETED",
  "notes": "Session completed successfully"
}
```

#### DELETE /bookings/{booking_id}
Cancel a booking

### Company Endpoints

#### POST /companies/
Create a new company
```json
{
  "name": "Acme Corporation",
  "contact_email": "contact@acme.com",
  "contact_phone": "+1-555-0100",
  "address": "123 Business St"
}
```

#### POST /companies/employees/register
Register an employee
```json
{
  "email": "employee@acme.com",
  "name": "Jane Employee",
  "password": "securepass",
  "company_id": "uuid"
}
```

#### GET /companies/{company_id}/employees
Get all employees of a company

## Getting Started

### 1. Start the Stack
```bash
./stack.sh start
```

This starts:
- PostgreSQL database (port 5432)
- FastAPI backend (port 8000)
- Next.js frontend (port 3000)
- Jitsi Meet server (port 8443)

### 2. Access the Platform

- **Frontend**: http://localhost:3000
- **API Documentation**: http://localhost:8000/docs
- **Jitsi Server**: http://localhost:8443

### 3. Register a Translator

1. Go to http://localhost:3000/register/translator
2. Fill in the registration form
3. Select languages (Spanish, French, and/or German)
4. Set an hourly rate (optional)
5. Click "Register as Translator"
6. Login with your credentials

### 4. Create a Company (via API)

```bash
curl -X POST http://localhost:8000/companies/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Company",
    "contact_email": "test@company.com",
    "contact_phone": "+1-555-0100",
    "address": "123 Test St"
  }'
```

### 5. Register an Employee (via API)

```bash
curl -X POST http://localhost:8000/companies/employees/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee@test.com",
    "name": "Test Employee",
    "password": "password123",
    "company_id": "<company_id_from_step_4>"
  }'
```

### 6. Login and Book a Translation

1. Go to http://localhost:3000/login
2. Login as the employee
3. Navigate to http://localhost:3000/calendar
4. Click "Book Translation"
5. Select a translator
6. Choose date, time, duration, and language
7. Click "Book Now"

### 7. Join a Translation Session

When it's time for the session:
1. Open the calendar
2. Click on your booking
3. Click "Join Meeting"
4. You'll be redirected to the Jitsi video room

## Workflow Example

### Complete Translation Booking Flow

1. **Translator Registration**
   - Maria registers as a Spanish/French translator
   - Sets hourly rate to $60/hour
   - Status: Available

2. **Company Setup**
   - Admin creates "Global Corp" company
   - Registers John as an employee

3. **Booking Creation**
   - John logs in and opens calendar
   - Sees Maria is available
   - Books Spanish translation for tomorrow at 2 PM, 1 hour
   - Adds note: "Need help with contract translation"

4. **Confirmation**
   - System confirms booking
   - Generates Jitsi room: `translation-a1b2c3d4e5f6`
   - Both Maria and John receive booking confirmation

5. **Session Day**
   - Maria opens calendar at 1:55 PM
   - Clicks on the booking
   - Clicks "Join Meeting" → Opens Jitsi
   - John does the same
   - They conduct 1-hour Spanish translation session

6. **Completion**
   - Session ends at 3 PM
   - Maria or John marks booking as "COMPLETED"
   - Booking appears as completed in calendar

## Features by User Role

### What Translators Can Do
✅ Register with multiple languages
✅ Set and update hourly rates
✅ Toggle availability on/off
✅ View all their bookings in calendar
✅ Access booking details
✅ Join video sessions
✅ Update booking status

### What Employees Can Do
✅ Book translation sessions
✅ Choose specific translators
✅ Select duration (30 min or 1 hour)
✅ Select language
✅ View their bookings in calendar
✅ Join video sessions
✅ Cancel bookings
✅ Add notes to bookings

### What Company Admins Can Do
✅ All employee capabilities
✅ View all company bookings
✅ Manage company profile

### What System Admins Can Do
✅ All platform access
✅ View all bookings
✅ Manage all users
✅ Access all API endpoints

## Technology Stack

### Backend
- **FastAPI** - Modern Python web framework
- **SQLAlchemy** - ORM for database operations
- **PostgreSQL** - Relational database
- **Pydantic** - Data validation
- **JWT** - Authentication tokens
- **Bcrypt** - Password hashing

### Frontend
- **Next.js 14** - React framework with SSR
- **TypeScript** - Type-safe JavaScript
- **Tailwind CSS** - Utility-first CSS
- **Zustand** - State management
- **React Big Calendar** - Calendar component
- **Axios** - HTTP client
- **date-fns** - Date manipulation

### Infrastructure
- **Docker** - Containerization
- **Jitsi Meet** - Video conferencing
- **Nginx** - Jitsi web server

## Security Considerations

### Authentication
- JWT tokens with 30-minute expiration
- Bcrypt password hashing (rounds=12)
- Token stored in localStorage
- Auto-redirect on 401 errors

### Authorization
- Role-based access control
- Booking ownership verification
- Company-level data isolation
- Translator-specific data protection

### Data Validation
- Email format validation
- Password strength requirements
- Language enum validation
- Duration validation (30 or 60 only)
- Booking conflict prevention

## Troubleshooting

### Translator can't be booked
- Check translator `is_available` status
- Verify translator supports the requested language
- Ensure no conflicting bookings exist

### Booking fails
- Verify employee belongs to a company
- Check date/time is in the future
- Confirm translator availability
- Ensure valid duration (30 or 60)

### Can't join Jitsi meeting
- Verify Jitsi containers are running: `./stack.sh status`
- Check Jitsi web interface: http://localhost:8443
- Restart Jitsi if needed: `docker-compose restart jitsi-web`

### Calendar not loading
- Check frontend logs: `./stack.sh logs frontend`
- Verify backend is running: `./stack.sh status`
- Check browser console for errors

## Development Commands

```bash
# Start everything
./stack.sh start

# View logs
./stack.sh logs backend
./stack.sh logs frontend
./stack.sh logs jitsi

# Restart a service
docker-compose restart backend
docker-compose restart frontend

# Rebuild after code changes
docker-compose build backend
docker-compose build frontend
docker-compose up -d

# Check service status
./stack.sh status

# Stop everything
./stack.sh stop
```

## Future Enhancements

Potential features to add:
- Email notifications for bookings
- Rating system for translators
- Payment integration
- Booking reminders
- Recurring bookings
- Multi-language UI
- Mobile app
- Analytics dashboard
- Chat functionality
- File sharing during sessions
- Session recording
- Transcript generation

## Support

For issues or questions:
1. Check this documentation
2. Review API docs at http://localhost:8000/docs
3. Check service logs with `./stack.sh logs`
4. Verify all services are healthy with `./stack.sh status`

---

**Platform is ready! Start booking your translation sessions!** 🌍🗣️
Human: continue