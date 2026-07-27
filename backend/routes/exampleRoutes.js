// Example API Routes using PostgreSQL Models
// Replace your current JSON-based routes with these

const express = require('express');
const router = express.Router();
const { User, Booking, Tool, Notification } = require('../models');

// ===== USER ROUTES =====

// Get all users
router.get('/users', async (req, res) => {
  try {
    const users = await User.findAll();
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get single user by ID
router.get('/users/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create user
router.post('/users', async (req, res) => {
  try {
    const { name, email, password, phone, userType } = req.body;
    const user = await User.create({
      name,
      email,
      password, // Remember: hash this with bcryptjs in real app!
      phone,
      userType
    });
    res.status(201).json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user
router.put('/users/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    await user.update(req.body);
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete user
router.delete('/users/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    
    await user.destroy();
    res.json({ message: 'User deleted' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===== BOOKING ROUTES =====

// Get all bookings
router.get('/bookings', async (req, res) => {
  try {
    const bookings = await Booking.findAll({
      include: [
        { model: User, attributes: ['name', 'email'] },
        { model: Tool, attributes: ['name', 'pricePerDay'] }
      ]
    });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create booking
router.post('/bookings', async (req, res) => {
  try {
    const { userId, toolId, shopOwnerId, startDate, endDate, quantity } = req.body;
    
    // Calculate total price (simplified)
    const tool = await Tool.findByPk(toolId);
    const days = Math.ceil((new Date(endDate) - new Date(startDate)) / (1000 * 60 * 60 * 24));
    const totalPrice = tool.pricePerDay * days * quantity;
    
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
      message: `New booking for ${tool.name}`,
      type: 'booking',
      relatedBookingId: booking.id
    });
    
    res.status(201).json(booking);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user's bookings
router.get('/users/:userId/bookings', async (req, res) => {
  try {
    const bookings = await Booking.findAll({
      where: { userId: req.params.userId },
      include: [
        { model: Tool, attributes: ['name', 'image', 'pricePerDay'] }
      ]
    });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update booking status
router.put('/bookings/:id', async (req, res) => {
  try {
    const booking = await Booking.findByPk(req.params.id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    
    await booking.update(req.body);
    res.json(booking);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===== TOOL ROUTES =====

// Get all tools
router.get('/tools', async (req, res) => {
  try {
    const { category, shopOwnerId } = req.query;
    const where = { isAvailable: true };
    
    if (category) where.category = category;
    if (shopOwnerId) where.shopOwnerId = shopOwnerId;
    
    const tools = await Tool.findAll({ where });
    res.json(tools);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create tool (shop owner)
router.post('/tools', async (req, res) => {
  try {
    const { name, description, category, pricePerDay, shopOwnerId, quantity } = req.body;
    const tool = await Tool.create({
      name,
      description,
      category,
      pricePerDay,
      shopOwnerId,
      quantity
    });
    res.status(201).json(tool);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ===== NOTIFICATION ROUTES =====

// Get user notifications
router.get('/users/:userId/notifications', async (req, res) => {
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

// Mark notification as read
router.put('/notifications/:id', async (req, res) => {
  try {
    const notification = await Notification.findByPk(req.params.id);
    if (!notification) return res.status(404).json({ error: 'Notification not found' });
    
    await notification.update({ isRead: true });
    res.json(notification);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
