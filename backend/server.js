const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;
const JWT_SECRET = 'your-secret-key-change-in-production';
const ADMIN_SECRET = 'admin123'; // Secret for admin login
const SHOP_OWNER_SECRET = 'shopowner123'; // Secret for shop owner login
const USERS_FILE = path.join(__dirname, 'users.json');
const BOOKINGS_FILE = path.join(__dirname, 'bookings.json');
const NOTIFICATIONS_FILE = path.join(__dirname, 'notifications.json');

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Load users from file
function loadUsers() {
  try {
    if (fs.existsSync(USERS_FILE)) {
      const data = fs.readFileSync(USERS_FILE, 'utf8');
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Error loading users:', error);
    return [];
  }
}

// Save users to file
function saveUsers(users) {
  try {
    fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
  } catch (error) {
    console.error('Error saving users:', error);
  }
}

// Load bookings from file
function loadBookings() {
  try {
    if (fs.existsSync(BOOKINGS_FILE)) {
      const data = fs.readFileSync(BOOKINGS_FILE, 'utf8');
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Error loading bookings:', error);
    return [];
  }
}

// Save bookings to file
function saveBookings(bookings) {
  try {
    fs.writeFileSync(BOOKINGS_FILE, JSON.stringify(bookings, null, 2));
  } catch (error) {
    console.error('Error saving bookings:', error);
  }
}

// Load notifications from file
function loadNotifications() {
  try {
    if (fs.existsSync(NOTIFICATIONS_FILE)) {
      const data = fs.readFileSync(NOTIFICATIONS_FILE, 'utf8');
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Error loading notifications:', error);
    return [];
  }
}

// Save notifications to file
function saveNotifications(notifications) {
  try {
    fs.writeFileSync(NOTIFICATIONS_FILE, JSON.stringify(notifications, null, 2));
  } catch (error) {
    console.error('Error saving notifications:', error);
  }
}

// Initialize users from file
let users = loadUsers();
let bookings = loadBookings();
let notifications = loadNotifications();

// Login endpoint
app.post('/api/login', async (req, res) => {
  try {
    const { name, email, password, phone, location } = req.body;

    // Validate input
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, and password'
      });
    }

    // Check if admin login
    if (email.toLowerCase() === 'admin@constructhub.com' && password === ADMIN_SECRET) {
      // Admin login
      const adminUser = {
        id: 0,
        name: 'Admin',
        email: 'admin@constructhub.com',
        role: 'admin'
      };

      const token = jwt.sign(
        { userId: 0, email: 'admin@constructhub.com', role: 'admin' },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      return res.status(200).json({
        success: true,
        message: 'Admin login successful',
        token: token,
        user: adminUser,
        isAdmin: true
      });
    }

    // Check if shop owner login
    if (email.toLowerCase() === 'shopowner@constructhub.com' && password === SHOP_OWNER_SECRET) {
      // Shop owner login
      const shopOwnerUser = {
        id: -1,
        name: 'Shop Owner',
        email: 'shopowner@constructhub.com',
        role: 'shopowner'
      };

      const token = jwt.sign(
        { userId: -1, email: 'shopowner@constructhub.com', role: 'shopowner' },
        JWT_SECRET,
        { expiresIn: '24h' }
      );

      return res.status(200).json({
        success: true,
        message: 'Shop owner login successful',
        token: token,
        user: shopOwnerUser,
        isShopOwner: true
      });
    }

    // Check if user exists by email (primary key)
    let user = users.find(u => u.email.toLowerCase() === email.toLowerCase());

    if (user) {
      // User exists - verify password
      const passwordMatch = await bcrypt.compare(password, user.password);
      if (!passwordMatch) {
        return res.status(401).json({
          success: false,
          message: 'Invalid password'
        });
      }
      console.log(`User logged in: ${user.name} (${user.email})`);
    } else {
      // Create new user (sign up)
      const hashedPassword = await bcrypt.hash(password, 10);
      user = {
        id: users.length + 1,
        name: name,
        email: email,
        password: hashedPassword,
        role: 'user',
        phone: phone || '',
        location: location || ''
      };
      users.push(user);
      // Save new user to file
      saveUsers(users);
      console.log(`New user signed up: ${name} (${email})`);
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role || 'user' },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(200).json({
      success: true,
      message: 'Login successful',
      token: token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        location: user.location || '',
        role: user.role || 'user'
      },
      isAdmin: false
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  }
});

// Get all users endpoint
app.get('/api/users', (req, res) => {
  try {
    const { email } = req.query;

    let filteredUsers = users.map(user => ({
      id: user.id,
      name: user.name,
      email: user.email
    }));

    // Filter by email if provided
    if (email) {
      filteredUsers = filteredUsers.filter(user =>
        user.email.toLowerCase() === email.toLowerCase()
      );
    }

    res.json({
      success: true,
      users: filteredUsers
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching users'
    });
  }
});

// Create booking endpoint
app.post('/api/bookings', (req, res) => {
  try {
    const { userId, tool, totalPrice, startDate, endDate, rentalDays, userName, userAddress, userPhone, paymentMethod, paymentDetails } = req.body;

    // Validate input
    if (!userId || !tool || !totalPrice || !startDate || !endDate || !rentalDays) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required booking details'
      });
    }

    // Create new booking
    const booking = {
      id: bookings.length + 1,
      userId: userId,
      tool: tool,
      totalPrice: totalPrice,
      startDate: startDate,
      endDate: endDate,
      rentalDays: rentalDays,
      userName: userName || '',
      userAddress: userAddress || '',
      userPhone: userPhone || '',
      paymentMethod: paymentMethod || 'cash', // card, upi, bank, cash
      paymentDetails: paymentDetails || '',
      status: 'pending', // pending, accepted, rejected
      createdAt: new Date().toISOString()
    };

    bookings.push(booking);
    saveBookings(bookings);

    console.log(`New booking created: ${booking.id} for user ${userId}`);

    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      booking: booking
    });

  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while creating booking'
    });
  }
});

// Get bookings for a user endpoint
app.get('/api/bookings/:userId', (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    const userBookings = bookings.filter(b => b.userId === userId);

    res.json({
      success: true,
      bookings: userBookings
    });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching bookings'
    });
  }
});

// Get all bookings (admin only)
app.get('/api/admin/bookings', (req, res) => {
  try {
    res.json({
      success: true,
      bookings: bookings
    });
  } catch (error) {
    console.error('Get all bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching all bookings'
    });
  }
});

// Get all users (admin only)
app.get('/api/admin/users', (req, res) => {
  try {
    const usersWithoutPasswords = users.map(user => ({
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone || '',
      location: user.location || '',
      role: user.role || 'user'
    }));
    res.json({
      success: true,
      users: usersWithoutPasswords
    });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching all users'
    });
  }
});

// Update user profile endpoint
app.put('/api/users/:userId', (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    const { phone, location } = req.body;

    const userIndex = users.findIndex(u => u.id === userId);
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Update user details
    users[userIndex].phone = phone || users[userIndex].phone || '';
    users[userIndex].location = location || users[userIndex].location || '';

    saveUsers(users);

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: users[userIndex].id,
        name: users[userIndex].name,
        email: users[userIndex].email,
        phone: users[userIndex].phone,
        location: users[userIndex].location
      }
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while updating user'
    });
  }
});

// Update booking status endpoint (for shop owner)
app.put('/api/bookings/:bookingId/status', (req, res) => {
  try {
    const bookingId = parseInt(req.params.bookingId);
    const { status } = req.body;

    if (!status || !['pending', 'accepted', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be pending, accepted, or rejected'
      });
    }

    const bookingIndex = bookings.findIndex(b => b.id === bookingId);
    if (bookingIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }

    // Update booking status
    bookings[bookingIndex].status = status;
    bookings[bookingIndex].statusUpdatedAt = new Date().toISOString();
    saveBookings(bookings);

    // Create notification for the user
    const notification = {
      id: notifications.length + 1,
      userId: bookings[bookingIndex].userId,
      type: status === 'accepted' ? 'booking_accepted' : 'booking_rejected',
      message: status === 'accepted'
        ? `Your booking #${bookingId} has been accepted!`
        : `Your booking #${bookingId} has been rejected.`,
      bookingId: bookingId,
      read: false,
      createdAt: new Date().toISOString()
    };
    notifications.push(notification);
    saveNotifications(notifications);

    console.log(`Booking ${bookingId} status updated to: ${status}`);
    console.log(`Notification created for user ${bookings[bookingIndex].userId}`);

    res.json({
      success: true,
      message: 'Booking status updated successfully',
      booking: bookings[bookingIndex],
      notification: notification
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while updating booking status'
    });
  }
});

// Get notifications for a user endpoint
app.get('/api/notifications/:userId', (req, res) => {
  try {
    const userId = parseInt(req.params.userId);
    const userNotifications = notifications.filter(n => n.userId === userId);

    res.json({
      success: true,
      notifications: userNotifications
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching notifications'
    });
  }
});

// Mark notification as read endpoint
app.put('/api/notifications/:notificationId/read', (req, res) => {
  try {
    const notificationId = parseInt(req.params.notificationId);
    const notificationIndex = notifications.findIndex(n => n.id === notificationId);

    if (notificationIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    notifications[notificationIndex].read = true;
    saveNotifications(notifications);

    res.json({
      success: true,
      message: 'Notification marked as read',
      notification: notifications[notificationIndex]
    });
  } catch (error) {
    console.error('Mark notification as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while marking notification as read'
    });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${PORT}`);
  console.log(`Access from device: http://YOUR_COMPUTER_IP:${PORT}`);
});
