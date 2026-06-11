# ConstructHub Backend

This is a simple Node.js/Express backend for the ConstructHub application, currently supporting login functionality.

## Setup Instructions

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start the server:
   ```bash
   npm start
   ```

   For development with auto-reload:
   ```bash
   npm run dev
   ```

The server will run on `http://localhost:3000`

## API Endpoints

### POST /api/login
Login endpoint for user authentication.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "jwt-token-here",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

### GET /api/health
Health check endpoint.

**Response:**
```json
{
  "status": "OK",
  "message": "Server is running"
}
```

## Notes

- This is a demo backend with in-memory user storage
- In production, use a real database (MongoDB, PostgreSQL, etc.)
- JWT secret should be changed in production
- Password hashing is implemented using bcryptjs
