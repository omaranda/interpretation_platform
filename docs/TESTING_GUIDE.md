# Testing Guide

Quick guide to test the Translation Platform features.

## Prerequisites

Ensure all services are running:
```bash
./stack.sh status
```

All services should show as "Healthy".

## Test 1: Calendar View for Translator

1. **Login as Translator**:
   - Go to: http://localhost:3000
   - Email: `maria.garcia@translator.com`
   - Password: `password123`

2. **Verify**:
   - ✅ You should be redirected to `/calendar` (not dashboard)
   - ✅ Navigation bar shows: "Calendar" and "My Profile"
   - ✅ User name "Maria Garcia" appears in top-right
   - ✅ Calendar view is displayed
   - ✅ No "Book Translation" button (translators don't book)

## Test 2: Calendar View for Employee

1. **Login as Employee**:
   - Go to: http://localhost:3000
   - Email: `john.smith@techcorp.com`
   - Password: `password123`

2. **Verify**:
   - ✅ You should be redirected to `/calendar`
   - ✅ Navigation bar shows: "Calendar"
   - ✅ "Book Translation" button is visible
   - ✅ Calendar view is displayed

3. **Test Booking Creation**:
   - Click "Book Translation" button
   - Select a translator (e.g., Maria Garcia - Spanish, French)
   - Choose a date/time (future date)
   - Select duration (30 min or 1 hour)
   - Select language (Spanish, French, or German)
   - Add notes (optional)
   - Click "Book Now"
   - ✅ Booking should be created
   - ✅ Event appears on calendar

## Test 3: Dashboard for Legacy Users

1. **Login as Agent**:
   - Go to: http://localhost:3000
   - Email: `agent1@example.com`
   - Password: `password123`

2. **Verify**:
   - ✅ You should be redirected to `/dashboard` (not calendar)
   - ✅ Navigation shows "Dashboard"
   - ✅ Call center metrics are displayed
   - ✅ "Start Test Call" button works

## Test 4: Jitsi Video Call

### Option A: From Dashboard (Legacy)

1. Login as `agent1@example.com`
2. Click "Start Test Call"
3. **Verify**:
   - ✅ Jitsi interface loads
   - ✅ Camera/microphone permissions requested
   - ✅ Can join call
   - ✅ "End Call" button works

### Option B: From Booking (Recommended)

1. Login as `john.smith@techcorp.com`
2. Create a booking (see Test 2)
3. Click on the booking event in calendar
4. **Note**: For confirmed bookings, "Join Meeting" button should appear
5. Click "Join Meeting"
6. **Verify**:
   - ✅ Opens new tab to Jitsi at `http://localhost:8443/[room-name]`
   - ✅ Can join the meeting

## Test 5: Navigation Between Pages

1. Login as any user
2. **Verify**:
   - ✅ Click navigation links (Calendar/Dashboard)
   - ✅ Pages load correctly
   - ✅ User info stays in header
   - ✅ Logout button works
   - ✅ After logout, redirected to login page

## Test 6: Translator Languages

1. **Create a Booking**:
   - Login as `robert.wilson@globalfinance.com`
   - Click "Book Translation"
   - View translator dropdown

2. **Verify Different Translators**:
   - ✅ Maria Garcia - Spanish, French
   - ✅ Jean Dupont - French
   - ✅ Hans Mueller - German
   - ✅ Klaus Schmidt - German, French
   - ✅ Carmen Rodriguez - Spanish
   - ✅ Diego Sanchez - Spanish
   - ✅ Petra Wagner - German
   - ⚠️ Isabelle Martin - Not in list (unavailable)

## Troubleshooting

### Calendar Not Loading
- Check browser console for errors (F12)
- Verify backend is running: `docker logs callcenter-backend --tail 20`
- Test API directly: `curl http://localhost:8000/health`
- Check if logged in user has valid token

### Jitsi Not Working
- Verify Jitsi is running: `docker ps | grep jitsi`
- Check Jitsi web is accessible: http://localhost:8443
- Look for external_api.js errors in browser console
- Verify browser allows http://localhost:8443 (not blocked)

### Bookings Not Showing
- Login to check database:
  ```bash
  docker exec callcenter-postgres psql -U callcenter -d callcenter -c "SELECT id, language, status, start_time FROM bookings;"
  ```
- Verify user role is correct
- Check backend logs for errors

### Navigation Not Appearing
- Hard refresh page (Ctrl+Shift+R or Cmd+Shift+R)
- Clear browser cache
- Check browser console for JavaScript errors
- Verify frontend rebuild completed successfully

## API Testing

### Get Bookings
```bash
# Login first to get token
TOKEN=$(curl -s -X POST 'http://localhost:8000/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"email":"john.smith@techcorp.com","password":"password123"}' \
  | jq -r '.access_token')

# Get bookings
curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/bookings/
```

### Get Translators
```bash
curl http://localhost:8000/translators/?available_only=true | jq
```

### Get API Documentation
Open http://localhost:8000/docs in your browser to see full interactive API documentation.

## Database Verification

### Check User Roles
```bash
docker exec callcenter-postgres psql -U callcenter -d callcenter -c \
  "SELECT name, email, role FROM users ORDER BY role;"
```

### Check Bookings
```bash
docker exec callcenter-postgres psql -U callcenter -d callcenter -c \
  "SELECT b.id, b.language, b.status, b.start_time, b.duration_minutes,
          u1.name as translator, u2.name as employee
   FROM bookings b
   JOIN users u1 ON b.translator_id = u1.id
   JOIN users u2 ON b.employee_id = u2.id
   ORDER BY b.start_time;"
```

## Quick Reset

If you need to start fresh:

```bash
# Stop all services
./stack.sh stop

# Clean everything
./stack.sh clean

# Start fresh
./stack.sh start

# Wait for services to be healthy (30 seconds)
sleep 30

# Seed database
docker exec callcenter-backend python seed_data.py
```

## Success Criteria

All tests should pass with:
- ✅ No console errors
- ✅ Smooth navigation
- ✅ Calendar loads and displays events
- ✅ Bookings can be created
- ✅ Jitsi calls work
- ✅ Role-based routing works correctly
- ✅ All navigation links work

## Known Issues

1. **WebSocket 403 Errors**: These appear in backend logs but don't affect functionality. Legacy feature that will be removed.

2. **Jitsi External Tab**: When joining meetings from calendar, it opens in a new tab. This is expected behavior.

3. **Browser Security**: Some browsers may block mixed content (http/https). If Jitsi doesn't load, check browser security settings.
