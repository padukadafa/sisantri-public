import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');

// Spike test - sudden surge in traffic
export const options = {
  stages: [
    { duration: '10s', target: 10 },   // Normal load
    { duration: '30s', target: 10 },   // Stay at normal
    { duration: '10s', target: 500 },  // Sudden spike!
    { duration: '1m', target: 500 },   // Maintain spike
    { duration: '10s', target: 10 },   // Quick drop
    { duration: '1m', target: 10 },    // Recovery period
    { duration: '10s', target: 0 },    // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<3000'],
    'http_req_failed': ['rate<0.4'], // Higher tolerance for spike test
  },
};
const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const API_KEY = __ENV.API_KEY || 'secret-api-key-here-f';
const DEVICE_ID = __ENV.DEVICE_ID || 'rfid-reader-001';
const DEVICE_SECRET = __ENV.DEVICE_SECRET || 'rfabid-012312345-secret';

function getHeaders() {
  return {
    'Content-Type': 'application/json',
    'x-api-key': API_KEY,
    'x-device-id': DEVICE_ID,
    'x-device-secret': DEVICE_SECRET,
  };
}

export default function () {
  const rfidUid = `RFID${Math.floor(Math.random() * 1000)}`;
  
  const payload = JSON.stringify({
    rfidUid: rfidUid,
  });

  const response = http.post(
    `${BASE_URL}/api/attendance/scan`,
    payload,
    { headers: getHeaders() }
  );

  const checkResult = check(response, {
    'system is responsive': (r) => r.status !== 0,
    'response within 5s': (r) => r.timings.duration < 5000,
  });

  errorRate.add(!checkResult);
  sleep(0.3);
}

export function setup() {
  console.log('⚡ Starting Spike Test...');
  console.log(`Base URL: ${BASE_URL}`);
  console.log('Simulating sudden traffic spike to 500 users');
  console.log('=================================');
}

export function teardown() {
  console.log('=================================');
  console.log('✓ Spike Test Completed');
}
