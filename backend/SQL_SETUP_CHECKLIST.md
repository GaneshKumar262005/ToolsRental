# PostgreSQL Connection Checklist

## ✅ Backend Setup Complete

You now have:
- ✅ `pg` - PostgreSQL driver for Node.js
- ✅ `sequelize` - ORM for database management  
- ✅ `dotenv` - Environment variable management
- ✅ Database models (User, Tool, Booking, Notification)
- ✅ Database configuration file

## 📋 Next Steps (Complete in Order)

### 1. Install & Start PostgreSQL
   - [ ] Download from https://www.postgresql.org/download/windows/
   - [ ] Run installer (remember your postgres password)
   - [ ] Verify: Open PowerShell and run `psql --version`

### 2. Create Database
   - [ ] Open PowerShell
   - [ ] Run: `psql -U postgres`
   - [ ] Copy-paste the SQL commands from `POSTGRES_SETUP.md`

### 3. Update .env File
   - [ ] Edit `backend/.env`
   - [ ] Set `DB_PASSWORD` to your PostgreSQL password
   - [ ] Other fields should already be correct

### 4. Update server.js
   - [ ] Add this at the top of server.js:
   ```javascript
   require('dotenv').config();
   const sequelize = require('./config/database');
   const { User, Tool, Booking, Notification } = require('./models');
   ```

   - [ ] Add this after middleware setup:
   ```javascript
   // Sync database models with PostgreSQL
   sequelize.sync({ alter: true })
     .then(() => console.log('✅ Database synced'))
     .catch(err => console.error('❌ Database sync failed:', err));
   ```

### 5. Test Connection
   - [ ] Run: `npm start`
   - [ ] You should see:
     ```
     ✅ PostgreSQL connection established successfully.
     ✅ Database synced
     Server running on port 3000
     ```

### 6. Update API Routes
   Replace your JSON file operations with database queries:
   ```javascript
   // Old: loadUsers() from JSON file
   // New:
   const users = await User.findAll();
   ```

---

## 📚 File Structure

```
backend/
├── config/
│   └── database.js          ← PostgreSQL connection
├── models/
│   ├── User.js              ← User model
│   ├── Tool.js              ← Tool/Equipment model
│   ├── Booking.js           ← Booking model
│   ├── Notification.js      ← Notification model
│   └── index.js             ← Model relationships
├── .env                     ← Database credentials
├── server.js                ← Main app (UPDATE THIS)
└── POSTGRES_SETUP.md        ← Detailed setup guide
```

---

## 🆘 Common Issues

**"connect ECONNREFUSED"** → PostgreSQL not running
**"password authentication failed"** → Check .env DB_PASSWORD
**"database does not exist"** → Run SQL commands from POSTGRES_SETUP.md

See POSTGRES_SETUP.md for full troubleshooting.

---

Ready to continue? Let me know when you have PostgreSQL installed! 🚀
