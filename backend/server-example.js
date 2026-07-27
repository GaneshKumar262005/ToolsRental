// server.js - Updated to use PostgreSQL

// ✅ ADD THESE AT THE TOP
require('dotenv').config();
const sequelize = require('./config/database');
const { User, Tool, Booking, Notification } = require('./models');

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

// Middleware
app.use(cors());
app.use(bodyParser.json());

// ✅ SYNC DATABASE WITH MODELS
sequelize.sync({ alter: true })
  .then(() => {
    console.log('✅ Database synced successfully');
  })
  .catch(err => {
    console.error('❌ Database sync failed:', err);
  });

// ✅ EXAMPLE: User Registration (using database instead of JSON)
app.post('/api/register', async (req, res) => {
  try {
    const { name, email, password, phone, userType } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user in database
    const user = await User.create({
      name,
      email,
      password: hashedPassword,
      phone,
      userType: userType || 'customer'
    });

    res.status(201).json({
      message: 'User created successfully',
      user: { id: user.id, email: user.email, name: user.name }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// ✅ EXAMPLE: User Login (using database instead of JSON)
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user in database
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: { id: user.id, email: user.email, name: user.name, userType: user.userType }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// ✅ EXAMPLE: Get All Tools
app.get('/api/tools', async (req, res) => {
  try {
    const { category } = req.query;
    
    const where = { isAvailable: true };
    if (category) where.category = category;
    
    const tools = await Tool.findAll({ where });
    res.json(tools);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ EXAMPLE: Create Booking
app.post('/api/bookings', async (req, res) => {
  try {
    const { userId, toolId, shopOwnerId, startDate, endDate, quantity } = req.body;
    
    // Calculate total price
    const tool = await Tool.findByPk(toolId);
    const days = Math.ceil((new Date(endDate) - new Date(startDate)) / (1000 * 60 * 60 * 24));
    const totalPrice = tool.pricePerDay * days * quantity;
    
    // Create booking
    const booking = await Booking.create({
      userId,
      toolId,
      shopOwnerId,
      startDate,
      endDate,
      quantity,
      totalPrice
    });
    
    // Create notification for shop owner
    await Notification.create({
      userId: shopOwnerId,
      title: 'New Booking',
      message: `${user.name} booked ${tool.name}`,
      type: 'booking',
      relatedBookingId: booking.id
    });
    
    res.status(201).json(booking);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ EXAMPLE: Get User Bookings
app.get('/api/users/:userId/bookings', async (req, res) => {
  try {
    const bookings = await Booking.findAll({
      where: { userId: req.params.userId },
      include: [{ model: Tool }]
    });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ✅ EXAMPLE: Get Notifications
app.get('/api/users/:userId/notifications', async (req, res) => {
  try {
    const notifications = await Notification.findAll({
      where: { userId: req.params.userId },
      order: [['createdAt', 'DESC']]
    });
    res.json(notifications);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});

/*
=======================================================================
MIGRATION GUIDE: JSON → PostgreSQL
=======================================================================

OLD (JSON files):
  const users = loadUsers();
  const user = users.find(u => u.email === email);

NEW (PostgreSQL):
  const user = await User.findOne({ where: { email } });

OLD:
  users.push(newUser);
  saveUsers(users);

NEW:
  await User.create(newUser);

OLD:
  user.name = 'New Name';
  saveUsers(users);

NEW:
  await user.update({ name: 'New Name' });

OLD:
  const index = users.indexOf(user);
  users.splice(index, 1);
  saveUsers(users);

NEW:
  await user.destroy();

=======================================================================
*/
