const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const path = require('path');
const nodemailer = require('nodemailer');
require('dotenv').config();

// Initialize Firebase Admin SDK
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./tools-bd286-firebase-adminsdk-fbsvc-51d9d72200.json');

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

// Seed Admin and Shop Owner into Firestore if they don't exist
async function seedDefaultUsers() {
  try {
    const usersRef = db.collection('users');
    
    // Seed Admin
    const adminSnap = await usersRef.where('email', '==', 'admin@constructhub.com').get();
    if (adminSnap.empty) {
      const adminHash = await bcrypt.hash(ADMIN_SECRET, 10);
      const docRef = usersRef.doc();
      await docRef.set({
        id: docRef.id,
        name: 'Admin',
        email: 'admin@constructhub.com',
        password: adminHash,
        role: 'admin',
        phone: '+91 98765 43210',
        location: 'Chennai, Tamil Nadu',
        emailVerified: true
      });
      console.log('✅ Default Admin user seeded into Firestore');
    }

    // Seed Shop Owner
    const shopOwnerSnap = await usersRef.where('email', '==', 'shopowner@constructhub.com').get();
    if (shopOwnerSnap.empty) {
      const shopOwnerHash = await bcrypt.hash(SHOP_OWNER_SECRET, 10);
      const docRef = usersRef.doc();
      await docRef.set({
        id: docRef.id,
        name: 'Shop Owner',
        email: 'shopowner@constructhub.com',
        password: shopOwnerHash,
        role: 'shopowner',
        phone: '+91 98765 43210',
        location: 'Chennai, Tamil Nadu',
        emailVerified: true
      });
      console.log('✅ Default Shop Owner user seeded into Firestore');
    }
  } catch (err) {
    console.error('❌ User seeding failed:', err);
  }
}

seedDefaultUsers();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const ADMIN_SECRET = process.env.ADMIN_SECRET || 'admin123';
const SHOP_OWNER_SECRET = process.env.SHOPOWNER_SECRET || 'shopowner123';

// In-memory OTP store: { email -> { otp, expiresAt, name } }
const otpStore = {};

// Helper: generate 6-digit OTP
function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Helper: send OTP via SMTP (Nodemailer with EmailJS Cloud Fallback)
async function sendOtpEmail(email, name, otp) {
  try {
    const host = process.env.SMTP_HOST || 'smtp.gmail.com';
    const port = parseInt(process.env.SMTP_PORT || '465');
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    console.log(`📡 Attempting to send email via ${host}:${port} using ${user}...`);

    const transporter = nodemailer.createTransport({
      host: host,
      port: port,
      secure: port === 465,
      auth: { user, pass },
      tls: { rejectUnauthorized: false }
    });

    const mailOptions = {
      from: `"BuildRent Support" <${user}>`,
      to: email,
      subject: `[OTP: ${otp}] Your BuildRent Verification Code`,
      text: `Your verification OTP is: ${otp}`,
      html: `
        <div style="font-family: sans-serif; padding: 20px; max-width: 600px; margin: auto; border: 1px solid #ddd; border-radius: 8px; background-color: #ffffff;">
          <h2 style="color: #F4B400;">BuildRent Verification</h2>
          <p style="color: #333; font-size: 16px;">Hi ${name || 'User'},</p>
          <p style="color: #555;">Your email verification code for ConstructHub is:</p>
          <div style="background: #f8f8f8; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 8px; border-radius: 8px; margin: 25px 0; color: #121212; border: 1px solid #F4B400;">
            ${otp}
          </div>
          <p style="color: #777; font-size: 14px;">This code is valid for 15 minutes. If you did not request this code, please ignore this email.</p>
          <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
          <p style="color: #999; font-size: 12px; text-align: center;">© 2026 ConstructHub Tool Rentals</p>
        </div>
      `,
    };

    const info = await transporter.sendMail(mailOptions);
    console.log(`✅ SMTP Success: Message ${info.messageId} sent to ${email}`);
    return true;
  } catch (err) {
    console.error('⚠️ Nodemailer SMTP failed:', err.message, '- Falling back to Cloud EmailJS...');
    
    // Cloud Fallback via EmailJS HTTPS API
    try {
      const https = require('https');
      const data = JSON.stringify({
        service_id: process.env.EMAILJS_SERVICE_ID || 'service_9qdeezg',
        template_id: process.env.EMAILJS_TEMPLATE_ID || 'template_rinruwg',
        user_id: process.env.EMAILJS_PUBLIC_KEY || 'GuD_9Grp3-Q0b4eAB',
        accessToken: process.env.EMAILJS_PRIVATE_KEY || 'ci5RMe_6tYZd0jre4B4K3',
        template_params: {
          to_email: email,
          user_email: email,
          email: email,
          to_name: name || 'User',
          user_name: name || 'User',
          name: name || 'User',
          otp: otp,
          OTP: otp,
          code: otp,
          CODE: otp,
          otp_code: otp,
          otpCode: otp,
          passcode: otp,
          PASSCODE: otp,
          pass_code: otp,
          passCode: otp,
          one_time_password: otp,
          oneTimePassword: otp,
          verification_code: otp,
          verificationCode: otp,
          auth_code: otp,
          authCode: otp,
          password: otp,
          PIN: otp,
          pin: otp,
          pin_code: otp,
          number: otp,
          num: otp,
          otp_num: otp,
          otpNum: otp,
          otp_number: otp,
          otpNumber: otp,
          token: otp,
          token_code: otp,
          val: otp,
          value: otp,
          otp_val: otp,
          vcode: otp,
          v_code: otp,
          pass: otp,
          time: '15 minutes',
          valid_time: '15 minutes',
          valid_till: '15 minutes',
          valid_until: '15 minutes',
          time_till: '15 minutes',
          until: '15 minutes',
          expiry: '15 minutes',
          expiry_time: '15 minutes',
          expired_time: '15 minutes',
          expiration: '15 minutes',
          expires_at: '15 minutes',
          duration: '15 minutes',
          validity: '15 minutes',
          date: '15 minutes',
          message: `Your One Time Password (OTP) is: ${otp} (Valid for 15 minutes)`,
          content: `Your One Time Password (OTP) is: ${otp} (Valid for 15 minutes)`,
          subject: `[OTP: ${otp}] ConstructHub Verification Code`
        }
      });

      return await new Promise((resolve) => {
        const req = https.request('https://api.emailjs.com/api/v1.0/email/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'origin': 'http://localhost',
            'Content-Length': Buffer.byteLength(data)
          }
        }, (res) => {
          if (res.statusCode === 200) {
            console.log(`✅ Cloud SMTP (EmailJS) Success: OTP sent to ${email}`);
            resolve(true);
          } else {
            console.error(`❌ Cloud EmailJS API returned status ${res.statusCode}`);
            resolve(false);
          }
        });
        req.on('error', (e) => {
          console.error('❌ Cloud EmailJS Error:', e.message);
          resolve(false);
        });
        req.write(data);
        req.end();
      });
    } catch (fallbackErr) {
      console.error('❌ Cloud Fallback Error:', fallbackErr.message);
      return false;
    }
  }
}


// Middleware
app.use(cors());
app.use(bodyParser.json());

// Login endpoint
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    // Check if user exists by email in Firestore
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', email.toLowerCase()).get();

    if (snapshot.empty) {
      return res.status(404).json({
        success: false,
        message: 'User not found. Please register first.'
      });
    }

    const doc = snapshot.docs[0];
    const user = { id: doc.id, ...doc.data() };
    
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ success: false, message: 'Invalid password' });
    }
    
    console.log(`User logged in: ${user.name} (${user.email}) as ${user.role}`);

    const token = jwt.sign({ userId: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '365d' });

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
        role: user.role
      },
      isAdmin: user.role === 'admin',
      isShopOwner: user.role === 'shopowner'
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Server error during login' });
  }
});

// Signup / Registration endpoint
app.post('/api/signup', async (req, res) => {
  try {
    const { name, email, password, phone, location } = req.body;

    // Validate input
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide name, email, and password'
      });
    }

    // Check if user already exists
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', email.toLowerCase()).get();

    if (!snapshot.empty) {
      return res.status(400).json({
        success: false,
        message: 'Email is already registered. Please log in instead.'
      });
    }

    // Determine role: use provided role if valid, otherwise fallback to guessing from email
    let role = req.body.role || 'user';
    if (!['user', 'shopowner', 'admin'].includes(role)) {
      if (email.toLowerCase().includes('shopowner')) {
        role = 'shopowner';
      } else if (email.toLowerCase().includes('admin')) {
        role = 'admin';
      } else {
        role = 'user';
      }
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const newUserRef = usersRef.doc();
    const user = {
      id: newUserRef.id,
      name: name,
      email: email.toLowerCase(),
      password: hashedPassword,
      role: role,
      phone: phone || '',
      location: location || '',
      emailVerified: true // Verified via OTP on the frontend
    };

    await newUserRef.set(user);
    console.log(`New user registered: ${name} (${email}) with role: ${role}`);

    const token = jwt.sign({ userId: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '365d' });

    res.status(200).json({
      success: true,
      message: 'Registration successful',
      token: token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        location: user.location || '',
        role: user.role
      },
      isAdmin: role === 'admin',
      isShopOwner: role === 'shopowner'
    });

  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ success: false, message: 'Server error during signup' });
  }
});

// Get all users endpoint
app.get('/api/users', async (req, res) => {
  try {
    const { email } = req.query;
    let usersRef = db.collection('users');
    let snapshot;
    
    if (email) {
      snapshot = await usersRef.where('email', '==', email.toLowerCase()).get();
    } else {
      snapshot = await usersRef.get();
    }

    const users = snapshot.docs.map(doc => {
      const data = doc.data();
      return { id: doc.id, name: data.name, email: data.email };
    });

    res.json({ success: true, users: users });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ success: false, message: 'Server error while fetching users' });
  }
});

// Create booking endpoint
app.post('/api/bookings', async (req, res) => {
  try {
    const { userId, tool, totalPrice, startDate, endDate, rentalDays, userName, userAddress, userPhone, paymentMethod, paymentDetails } = req.body;

    if (!userId || !tool || !totalPrice || !startDate || !endDate || !rentalDays) {
      return res.status(400).json({ success: false, message: 'Please provide all required booking details' });
    }

    const newBookingRef = db.collection('bookings').doc();
    const booking = {
      id: newBookingRef.id,
      userId: userId.toString(),
      tool: tool,
      totalPrice: totalPrice,
      startDate: startDate,
      endDate: endDate,
      rentalDays: rentalDays,
      userName: userName || '',
      userAddress: userAddress || '',
      userPhone: userPhone || '',
      paymentMethod: paymentMethod || 'cash',
      paymentDetails: paymentDetails || '',
      status: 'pending',
      createdAt: new Date().toISOString()
    };

    await newBookingRef.set(booking);
    console.log(`New booking created: ${booking.id} for user ${userId}`);

    res.status(201).json({ success: true, message: 'Booking created successfully', booking: booking });

  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({ success: false, message: 'Server error while creating booking' });
  }
});

// Get bookings for a user endpoint
app.get('/api/bookings/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const snapshot = await db.collection('bookings').where('userId', '==', userId.toString()).get();
    
    const bookings = snapshot.docs.map(doc => doc.data());
    res.json({ success: true, bookings: bookings });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({ success: false, message: 'Server error while fetching bookings' });
  }
});

// Get all bookings (admin only)
app.get('/api/admin/bookings', async (req, res) => {
  try {
    const snapshot = await db.collection('bookings').get();
    const bookings = snapshot.docs.map(doc => doc.data());
    res.json({ success: true, bookings: bookings });
  } catch (error) {
    console.error('Get all bookings error:', error);
    res.status(500).json({ success: false, message: 'Server error while fetching all bookings' });
  }
});

// Get all users (admin only)
app.get('/api/admin/users', async (req, res) => {
  try {
    const snapshot = await db.collection('users').get();
    const users = snapshot.docs.map(doc => {
      const data = doc.data();
      return { id: doc.id, name: data.name, email: data.email, phone: data.phone || '', location: data.location || '', role: data.role || 'user' };
    });
    res.json({ success: true, users: users });
  } catch (error) {
    console.error('Get all users error:', error);
    res.status(500).json({ success: false, message: 'Server error while fetching all users' });
  }
});

// Update user profile endpoint
app.put('/api/users/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const { phone, location } = req.body;

    const userRef = db.collection('users').doc(userId);
    const doc = await userRef.get();
    
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    await userRef.update({
      phone: phone || doc.data().phone || '',
      location: location || doc.data().location || ''
    });

    const updatedDoc = await userRef.get();
    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: { id: updatedDoc.id, ...updatedDoc.data() }
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ success: false, message: 'Server error while updating user' });
  }
});

// Update booking status endpoint
app.put('/api/bookings/:bookingId/status', async (req, res) => {
  try {
    const bookingId = req.params.bookingId;
    const { status } = req.body;

    if (!status || !['pending', 'accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status. Must be pending, accepted, or rejected' });
    }

    const bookingRef = db.collection('bookings').doc(bookingId);
    const doc = await bookingRef.get();

    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    const bookingData = doc.data();

    await bookingRef.update({
      status: status,
      statusUpdatedAt: new Date().toISOString()
    });

    // Create notification for the user
    const notificationRef = db.collection('notifications').doc();
    const notification = {
      id: notificationRef.id,
      userId: bookingData.userId,
      type: status === 'accepted' ? 'booking_accepted' : 'booking_rejected',
      message: status === 'accepted' ? `Your booking #${bookingId} has been accepted!` : `Your booking #${bookingId} has been rejected.`,
      bookingId: bookingId,
      read: false,
      createdAt: new Date().toISOString()
    };

    await notificationRef.set(notification);
    console.log(`Booking ${bookingId} status updated to: ${status}`);

    const updatedBooking = await bookingRef.get();

    res.json({
      success: true,
      message: 'Booking status updated successfully',
      booking: updatedBooking.data(),
      notification: notification
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({ success: false, message: 'Server error while updating booking status' });
  }
});

// Get notifications for a user endpoint
app.get('/api/notifications/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    const snapshot = await db.collection('notifications').where('userId', '==', userId.toString()).get();
    const notifications = snapshot.docs.map(doc => doc.data());
    
    res.json({ success: true, notifications: notifications });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ success: false, message: 'Server error while fetching notifications' });
  }
});

// Mark notification as read endpoint
app.put('/api/notifications/:notificationId/read', async (req, res) => {
  try {
    const notificationId = req.params.notificationId;
    const notificationRef = db.collection('notifications').doc(notificationId);
    
    const doc = await notificationRef.get();
    if (!doc.exists) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    await notificationRef.update({ read: true });
    const updatedDoc = await notificationRef.get();

    res.json({
      success: true,
      message: 'Notification marked as read',
      notification: updatedDoc.data()
    });
  } catch (error) {
    console.error('Mark notification as read error:', error);
    res.status(500).json({ success: false, message: 'Server error while marking notification as read' });
  }
});

// ─── Email Verification: Send OTP ──────────────────────────────────────────
app.post('/api/send-otp', async (req, res) => {
  try {
    const { email, name } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Email is required' });

    const otp = generateOtp();
    const expiresAt = Date.now() + 10 * 60 * 1000;
    otpStore[email.toLowerCase()] = { otp, expiresAt, name: name || 'User' };

    console.log(`📧 OTP for ${email}: ${otp}`);

    const sent = await sendOtpEmail(email, name, otp);

    if (sent) {
      return res.status(200).json({ success: true, message: `Verification code sent to ${email}` });
    } else {
      console.error(`❌ SMTP failed to send email to ${email}`);
      return res.status(500).json({ success: false, message: `Failed to send email. Please check your internet or SMTP configuration.` });
    }
  } catch (error) {
    console.error('Send OTP error:', error);
    return res.status(500).json({ success: false, message: 'Server error while sending OTP' });
  }
});

// ─── Email Verification: Verify OTP ────────────────────────────────────────
app.post('/api/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ success: false, message: 'Email and OTP are required' });

    const key = email.toLowerCase();
    const record = otpStore[key];

    if (!record) return res.status(400).json({ success: false, message: 'No OTP found for this email. Please request a new one.' });
    if (Date.now() > record.expiresAt) {
      delete otpStore[key];
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new one.' });
    }
    if (record.otp !== otp.toString()) return res.status(400).json({ success: false, message: 'Incorrect OTP. Please try again.' });

    // Valid
    delete otpStore[key];

    // Mark user as verified in Firestore (if they exist)
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', key).get();
    
    if (!snapshot.empty) {
      const docId = snapshot.docs[0].id;
      await usersRef.doc(docId).update({ emailVerified: true });
    }

    return res.status(200).json({ success: true, message: 'Email verified successfully!' });
  } catch (error) {
    console.error('Verify OTP error:', error);
    return res.status(500).json({ success: false, message: 'Server error while verifying OTP' });
  }
});

// ─── Shop Owner OTP Login ──────────────────────────────────────────────────
app.post('/api/shopowner-login-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ success: false, message: 'Email and OTP are required' });

    const key = email.toLowerCase();
    const record = otpStore[key];

    if (!record) return res.status(400).json({ success: false, message: 'No OTP found for this email. Please request a new one.' });
    if (Date.now() > record.expiresAt) {
      delete otpStore[key];
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new one.' });
    }
    if (record.otp !== otp.toString()) return res.status(400).json({ success: false, message: 'Incorrect OTP. Please try again.' });

    // Valid OTP
    delete otpStore[key];

    // Find the user in Firestore
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', key).get();
    
    if (snapshot.empty) {
      return res.status(404).json({ success: false, message: 'User not found. Please register as a shop owner first.' });
    }

    const doc = snapshot.docs[0];
    const user = { id: doc.id, ...doc.data() };

    if (user.role !== 'shopowner' && user.role !== 'admin') {
       return res.status(403).json({ success: false, message: 'This account is not registered as a shop owner.' });
    }

    console.log(`Shop owner logged in via OTP: ${user.name} (${user.email})`);

    const token = jwt.sign({ userId: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '365d' });

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
        role: user.role
      },
      isAdmin: user.role === 'admin',
      isShopOwner: user.role === 'shopowner'
    });

  } catch (error) {
    console.error('Shopowner OTP login error:', error);
    return res.status(500).json({ success: false, message: 'Server error while logging in with OTP' });
  }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Server is running' });
});

// Tool return endpoint
app.post('/api/return-tool', (req, res) => {
  try {
    const { orderId, toolName, userName, userPhone, returnNotes, photoBase64, timestamp } = req.body;
    if (!orderId) {
      return res.status(400).json({ success: false, message: 'Order ID is required' });
    }
    console.log(`📦 Tool Return Received for Order #${orderId} - Tool: ${toolName || 'Equipment'} by ${userName || 'Customer'}`);
    return res.status(200).json({
      success: true,
      message: `Tool return for Order #${orderId} submitted successfully`,
      data: { orderId, status: 'RETURNED', timestamp: timestamp || new Date().toISOString() }
    });
  } catch (error) {
    console.error('Tool return error:', error);
    return res.status(500).json({ success: false, message: 'Server error while submitting tool return' });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${PORT}`);
  console.log(`Access from device: http://YOUR_COMPUTER_IP:${PORT}`);
});

