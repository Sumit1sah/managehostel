# Parent Interface Login Guide

## How to Login as Parent

### Step 1: Warden Creates Student + Parent Account
1. Warden logs in to the app
2. Go to **Student ID Management**
3. Click **+ (Add Student)**
4. Fill in the form with TWO sections:
   
   **Student Details:**
   - Student Name
   - Student ID (e.g., `S001`)
   - Password
   - Phone Number
   - Floor & Room
   
   **Parent Account:**
   - Parent ID (e.g., `P001`)
   - Parent Password (e.g., `parent123`)

5. Click **"Create"**
6. Both student and parent accounts are created together!

### Step 2: Parent Login
1. Go to the main login screen
2. Click **"Parent Login"** button (below regular login)
3. Enter:
   - **Parent ID**: `P001` (created by warden)
   - **Student ID**: `S001` (the student's ID)
   - **Password**: `parent123` (set by warden)
4. Click **"Login"**

## Parent Dashboard Features

Once logged in, parents can:

### 1. View Student Information
- Name, Student ID
- Phone number
- Floor and Room number

### 2. Track Complaints
- See all complaints filed by their child
- Check complaint status (Pending/Resolved)

### 3. Message Warden
- Click the message icon in the top-right
- Type and send messages to the warden
- View conversation history

## Warden: View Parent Messages

1. Login as warden
2. Navigate to `WardenParentMessagesView`
3. View all messages from parents
4. Reply to parent inquiries

## Example Credentials

### Test Parent Login
- Parent ID: `P001`
- Student ID: `S001`
- Password: `parent123`

### Test Warden Login
- User ID: `warden`
- Password: `warden123`

## Connection Flow

```
Warden creates:
  ├─ Student Account (S001)
  └─ Parent Account (P001) → linked to S001

Parent logs in with:
  ├─ Parent ID (P001)
  ├─ Student ID (S001)
  └─ Password

Parent can:
  ├─ View Student Info
  ├─ Track Complaints
  └─ Message Warden
```

## Data Storage

All parent data is automatically saved to Hive storage:
- `parents` - List of parent accounts
- `parent_messages_{parentId}` - Messages for each parent

## Security

- Parents can only view their own child's information
- Messages are linked to specific students
- All data is encrypted in Hive storage
