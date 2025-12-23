# PBI Splitting Guide

## Best Practices

**Extract high-value portions:**
- From "email client" → "receive emails" (high user value)
- From "TODO list" → "display dummy items" (draws whole picture)

**Handle large PBIs:**
- Extract immediate portion as small `ready` story
- Leave remainder as `refining` (re-split in future)

## Splitting Strategies

**NEVER split by technical layer or phase** (UI/DB/API or Design/Dev/Test) - this creates mandatory dependencies and blocks feedback.

### 1. Workflow Steps
Split along the user journey.
```
Before: User can book a hotel
After:
  - User can select room and dates to submit booking
  - User identity is verified during booking
  - Confirmation email is sent after booking
```

### 2. Business Rules
Separate core logic from rule variations.
```
Before: User can book a hotel
After:
  - User can select room and dates to submit booking
  - Booking is blocked if guest count exceeds capacity
  - Child guests receive discounted rates
```

### 3. Happy Path vs Edge Cases
Deliver the main flow first, handle exceptions later.
```
Before: Registered user can log in
After:
  - Registered user can log in to view reservations
  - User can reset password if forgotten
  - Account locks after 3 failed attempts
```

### 4. Input Parameters
Split by search/filter criteria.
```
Before: User can search hotel availability
After:
  - User can search by date range
  - User can filter by room size
  - User can filter by price range
```

### 5. User Roles
Split by actor/persona.
```
Before: User can view room details
After:
  - Guest can view room details
  - Staff can create/update room details
  - Admin can delete room details
```

### 6. Optimization Degree
Start simple, optimize incrementally.
```
Before: User can search availability
After:
  - User clicks search to see matching results
  - Results update in real-time as user types
```

### 7. Spike + Implementation
Split technical investigation from feature implementation.
```
Before: User can book using external payment API
After:
  - [Spike] Investigate payment API integration options (2 pts)
  - User can book using payment API (5 pts)
```

## Anti-Patterns (Merge These)

These should be **merged** with adjacent PBIs:

| Anti-Pattern | Merge With |
|--------------|------------|
| Dependency library only | Feature using it |
| Interface/type definition only | Implementation |
| Tests only | Implementation (TDD: same subtask) |
| Refactoring preparation only | The refactoring itself |

**Judgment Criterion**: Can this PBI deliver `benefit` on its own?
- ❌ "HTTP communication is possible" (just preparation)
- ✅ "Can fetch and display weather from API" (value delivered)
