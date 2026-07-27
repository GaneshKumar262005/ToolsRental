# PostgreSQL Setup Guide for ConstructHub Backend

## Step 1: Install PostgreSQL

### Windows:
1. Download PostgreSQL installer from https://www.postgresql.org/download/windows/
2. Run the installer and follow the setup wizard
3. Remember the password you set for the `postgres` user
4. Default port is 5432

### Verify Installation:
```powershell
psql --version
```

---

## Step 2: Create Database and User

Open PowerShell or Command Prompt and connect to PostgreSQL:

```powershell
psql -U postgres
```

Then run these commands:

```sql
-- Create database
CREATE DATABASE constructhub;

-- Create a user (optional, or use 'postgres')
CREATE USER constructhub_user WITH PASSWORD 'your_secure_password';

-- Grant privileges
ALTER ROLE constructhub_user SET client_encoding TO 'utf8';
ALTER ROLE constructhub_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE constructhub_user SET default_transaction_deferrable TO on;
GRANT ALL PRIVILEGES ON DATABASE constructhub TO constructhub_user;

-- Exit
\q
```

---

## Step 3: Update .env File

Edit `.env` in the backend folder:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=constructhub
DB_USER=constructhub_user
DB_PASSWORD=your_secure_password
NODE_ENV=development
```

---

## Step 4: Install Dependencies

Navigate to the backend folder and run:

```powershell
cd backend
npm install
```

---

## Step 5: Sync Database Models

Add this to your `server.js` to auto-create tables:

```javascript
const sequelize = require('./config/database');
const { User, Tool, Booking, Notification } = require('./models');

// Sync database (creates tables if they don't exist)
sequelize.sync({ alter: true })
  .then(() => console.log('✅ Database synced'))
  .catch(err => console.error('❌ Database sync failed:', err));
```

---

## Step 6: Start the Server

```powershell
npm start
```

You should see:
```
✅ PostgreSQL connection established successfully.
✅ Database synced
Server running on port 3000
```

---

## Useful PostgreSQL Commands

```powershell
# Connect to PostgreSQL
psql -U postgres

# List databases
\l

# Connect to a database
\c constructhub

# List tables
\dt

# Describe a table
\d users

# Exit
\q
```

---

## Troubleshooting

**Error: "connect ECONNREFUSED 127.0.0.1:5432"**
- PostgreSQL is not running. Start it from Windows Services or use `pg_ctl start`

**Error: "FATAL: Ident authentication failed"**
- Update `.env` with correct DB_USER and DB_PASSWORD

**Error: "database does not exist"**
- Run the SQL commands above to create the database

---

For more help, check: https://www.postgresql.org/docs/
