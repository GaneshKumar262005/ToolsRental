const Service = require('node-windows').Service;

// Create a new service object
const svc = new Service({
  name: 'ConstructHub Backend',
  description: 'ConstructHub Backend Server',
  script: 'C:\\Users\\ganes\\OneDrive\\Desktop\\pro\\win\\backend\\server.js',
  nodeOptions: [
    '--harmony',
    '--max_old_space_size=4096'
  ]
});

// Listen for the "install" event
svc.on('install', function(){
  svc.start();
  console.log('Service installed and started successfully');
});

// Listen for the "uninstall" event
svc.on('uninstall', function(){
  console.log('Service uninstalled successfully');
});

// Listen for the "start" event
svc.on('start', function(){
  console.log('Service started successfully');
});

// Install the service
svc.install();
