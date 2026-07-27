const User = require('./User');
const Tool = require('./Tool');
const Booking = require('./Booking');
const Notification = require('./Notification');

// Define relationships
User.hasMany(Tool, { foreignKey: 'shopOwnerId' });
Tool.belongsTo(User, { foreignKey: 'shopOwnerId' });

User.hasMany(Booking, { foreignKey: 'userId' });
Booking.belongsTo(User, { foreignKey: 'userId' });

Tool.hasMany(Booking, { foreignKey: 'toolId' });
Booking.belongsTo(Tool, { foreignKey: 'toolId' });

User.hasMany(Notification, { foreignKey: 'userId' });
Notification.belongsTo(User, { foreignKey: 'userId' });

module.exports = {
  User,
  Tool,
  Booking,
  Notification,
};
