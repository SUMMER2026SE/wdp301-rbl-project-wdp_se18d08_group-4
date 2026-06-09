require('dotenv').config();
const os = require('os');
const app = require('./app');
const env = require('./config/env');

function lanAddresses() {
  const nets = os.networkInterfaces();
  const ips = [];
  for (const name of Object.keys(nets)) {
    for (const net of nets[name] || []) {
      if (net.family === 'IPv4' && !net.internal) ips.push(net.address);
    }
  }
  return ips;
}

app.listen(env.PORT, '0.0.0.0', () => {
  console.log(`UniMove API: http://localhost:${env.PORT}`);
  console.log(`Health: http://localhost:${env.PORT}/api/health`);
  const ips = lanAddresses();
  if (ips.length) {
    console.log('Điện thoại thật → api_config.dart useLanHost + IP:');
    ips.forEach((ip) => console.log(`  http://${ip}:${env.PORT}/api`));
  }
  console.log('Android emulator → http://10.0.2.2:' + env.PORT + '/api');
});
