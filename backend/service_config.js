// service_config.js
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '.env') });
module.exports = {
  name: 'ConstructHub Backend',
  description: 'ConstructHub Backend Server',
  script: path.join(__dirname, 'server.js'),
  workingDirectory: __dirname,
  nodeOptions: ['--harmony', '--max_old_space_size=4096'],
  env: process.env,
  // restart: true // will be enabled based on user answer
};
