const Service = require('node-windows').Service;
const config = require('./service_config');

const svc = new Service({
  name: config.name,
  description: config.description,
  script: config.script,
  workingDirectory: config.workingDirectory,
  nodeOptions: config.nodeOptions,
  env: Object.entries(config.env).map(([k, v]) => ({ name: k, value: v })),
  restart: true, // auto-restart enabled per user selection
});

svc.on('install', () => {
  svc.start();
  console.log('Service installed and started');
});
svc.on('alreadyinstalled', () => console.log('Service already installed'));
svc.on('start', () => console.log('Service started'));
svc.on('stop', () => console.log('Service stopped'));
svc.on('error', err => console.error('Service error:', err));

svc.install();
