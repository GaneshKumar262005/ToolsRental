const Service = require('node-windows').Service;
const config = require('./service_config');
const svc = new Service({
  name: config.name,
  script: config.script,
});
svc.on('uninstall', () => console.log('Service uninstalled'));
svc.uninstall();
