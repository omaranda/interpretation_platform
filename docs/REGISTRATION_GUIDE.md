# Registration Guide

Complete guide for registering new users on the Translation Platform.

## Translator Registration (Self-Service)

Translators can register themselves without administrator approval.

### Web Interface Registration

1. **Navigate to Registration Page**
   - Go to: http://localhost:3000/register/translator
   - Or click "Register as Translator" from the login page

2. **Fill Out Registration Form**
   - **Full Name**: Your professional name
   - **Email**: Your email address (will be used for login)
   - **Password**: Create a secure password
   - **Confirm Password**: Re-enter your password
   - **Languages**: Select all languages you can translate
     - Spanish
     - French
     - German
     - (Can select multiple)
   - **Hourly Rate** (Optional): Your translation rate (e.g., "$50/hour")

3. **Submit Registration**
   - Click "Register as Translator"
   - Wait for confirmation
   - You'll be redirected to the login page

4. **Login**
   - Use your email and password to login
   - You'll be taken to the Calendar view
   - You can update your profile and availability

### API Registration

For programmatic registration:

```bash
curl -X POST http://localhost:8000/translators/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "translator@example.com",
    "name": "Translator Name",
    "password": "secure_password",
    "languages": ["SPANISH", "FRENCH"],
    "hourly_rate": "$50/hour"
  }'
```

### After Registration

Once registered, translators can:

1. **Login**: http://localhost:3000
2. **View Bookings**: See all translation sessions on the calendar
3. **Update Profile**: Modify languages, hourly rate
4. **Set Availability**: Mark yourself as available/unavailable
5. **Join Meetings**: Connect to Jitsi video calls for sessions

### Translator Profile Management

**Update Availability:**
```bash
# Get your user ID from /auth/me
# Then update availability

curl -X PUT http://localhost:8000/translators/{translator_id}/availability \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "translator_id": "your-uuid-here",
    "is_available": true
  }'
```

**Update Profile:**
```bash
curl -X PUT http://localhost:8000/translators/{translator_id} \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "languages": ["SPANISH", "FRENCH", "GERMAN"],
    "hourly_rate": "$60/hour"
  }'
```

## Employee Registration (Admin Required)

Employees cannot self-register. They must be registered by a company administrator.

### Prerequisites
- Company must already exist in the system
- You need the company ID

### Registration Process

**Via API:**
```bash
curl -X POST http://localhost:8000/companies/employees/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee@company.com",
    "name": "Employee Name",
    "password": "initial_password",
    "company_id": "company-uuid-here"
  }'
```

**From Python Script:**
```python
import requests

response = requests.post(
    'http://localhost:8000/companies/employees/register',
    json={
        'email': 'employee@company.com',
        'name': 'Employee Name',
        'password': 'initial_password',
        'company_id': 'company-uuid-here'
    }
)

print(response.json())
```

### Employee Capabilities

After registration, employees can:
- Login to the platform
- View company calendar
- Book translation sessions
- Join video meetings
- View booking history

## Company Registration (Admin Only)

Companies must be registered by a system administrator.

### Registration Process

**Via API:**
```bash
curl -X POST http://localhost:8000/companies/ \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Company Name Inc.",
    "contact_email": "contact@company.com",
    "contact_phone": "+1-555-0100",
    "address": "123 Business St, City, State 12345"
  }'
```

**Via Database:**
```sql
INSERT INTO companies (id, name, contact_email, contact_phone, address)
VALUES (
    uuid_generate_v4(),
    'Company Name Inc.',
    'contact@company.com',
    '+1-555-0100',
    '123 Business St, City, State 12345'
);
```

### After Company Registration

1. Create a company admin user:
```bash
curl -X POST http://localhost:8000/companies/employees/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@company.com",
    "name": "Company Admin",
    "password": "secure_password",
    "company_id": "company-uuid-here"
  }'
```

2. Manually set the user role to COMPANY_ADMIN:
```sql
UPDATE users
SET role = 'COMPANY_ADMIN'
WHERE email = 'admin@company.com';
```

3. The company admin can now:
   - Register new employees
   - View all company bookings
   - Manage company settings

## Registration Validation

### Email Validation
- Must be a valid email format
- Must be unique in the system
- Case-insensitive duplicate check

### Password Requirements
- Minimum length: 8 characters (recommended)
- Hashed using bcrypt before storage
- Never stored in plain text

### Language Validation
- Must be one of: SPANISH, FRENCH, GERMAN
- Can select multiple languages
- At least one language required for translators

### Hourly Rate
- Optional field
- Free-form text (e.g., "$50/hour", "€45/hour", "Negotiable")
- For display purposes only, not used in calculations

## Troubleshooting

### "Email already exists"
**Problem**: Email is already registered in the system.

**Solution**:
- Use a different email address
- Contact admin to reset the existing account
- Check if you already have an account

### "Failed to register translator"
**Problem**: Server error during registration.

**Solution**:
- Check backend logs: `docker logs callcenter-backend --tail 50`
- Verify database is running: `docker ps | grep postgres`
- Ensure all required fields are filled
- Check password meets requirements

### "Password does not match"
**Problem**: Password and confirm password don't match.

**Solution**:
- Re-enter both password fields
- Check for typos
- Ensure caps lock is off

### Cannot access registration page
**Problem**: 404 error on /register/translator

**Solution**:
- Verify frontend is running: `docker ps | grep frontend`
- Check URL is correct: http://localhost:3000/register/translator
- Restart frontend: `docker-compose restart frontend`

## Security Considerations

### Password Security
- All passwords are hashed using bcrypt with salt rounds
- Never transmitted or stored in plain text
- No password recovery (must be reset by admin)

### Email Privacy
- Emails are used for login only
- Not shared with other users
- Visible only to system administrators

### Registration Rate Limiting
- Consider implementing rate limiting for registration endpoints
- Prevent automated bot registrations
- Monitor for suspicious registration patterns

## Best Practices

### For Translators
1. Use a professional email address
2. Set a strong, unique password
3. Accurately list all languages you can translate
4. Set realistic hourly rates
5. Keep your availability status updated
6. Check your calendar regularly for new bookings

### For Company Admins
1. Create unique accounts for each employee
2. Use strong passwords for all accounts
3. Document employee access levels
4. Regularly review company bookings
5. Remove access for departed employees

### For System Admins
1. Regularly backup user database
2. Monitor registration activity
3. Validate company information before approval
4. Keep audit logs of user registrations
5. Implement email verification (future enhancement)

## Future Enhancements

Planned improvements for the registration system:

- [ ] Email verification for new registrations
- [ ] Password reset functionality
- [ ] Social login (Google, LinkedIn)
- [ ] Profile photo upload
- [ ] Certifications and credentials upload
- [ ] Multi-factor authentication
- [ ] Automated onboarding emails
- [ ] Admin approval workflow for translators
- [ ] Background check integration
- [ ] Language proficiency verification

## Support

For registration issues:
- Check the troubleshooting section above
- Review [TESTING_GUIDE.md](TESTING_GUIDE.md) for common issues
- Check backend logs: `docker logs callcenter-backend`
- Verify database status: `./stack.sh status`
