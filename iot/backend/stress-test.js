import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Stress test - push the system beyond normal capacity
export const options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up to 100 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 200 },  // Ramp up to 200 users
    { duration: '5m', target: 200 },  // Stay at 200 users
    { duration: '2m', target: 300 },  // Spike to 300 users
    { duration: '5m', target: 300 },  // Stay at 300 users
    { duration: '2m', target: 400 },  // Push to 400 users
    { duration: '5m', target: 400 },  // Stay at 400 users
    { duration: '5m', target: 0 },    // Ramp down to 0
  ],
  thresholds: {
    'http_req_duration': ['p(95)<2000'], // 95% of requests should be below 2s
    'http_req_failed': ['rate<0.3'],     // Up to 30% failure acceptable in stress test
    'errors': ['rate<0.3'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const API_KEY = __ENV.API_KEY || 'secret-api-key-here-f';
const DEVICE_ID = __ENV.DEVICE_ID || 'rfid-reader-001';
const DEVICE_SECRET = __ENV.DEVICE_SECRET || 'rfabid-012312345-secret';

// Generate more RFID UIDs for stress testing
const RFID_UIDS = Array.from({ length: 100 }, (_, i) => `RFID${String(i).padStart(3, '0')}`);

function getHeaders() {
  return {
    'Content-Type': 'application/json',
    'x-api-key': API_KEY,
    'x-device-id': DEVICE_ID,
    'x-device-secret': DEVICE_SECRET,
  };
}

export default function () {
  const rfidUid = RFID_UIDS[Math.floor(Math.random() * RFID_UIDS.length)];
  
  const payload = JSON.stringify({
    rfidUid: rfidUid,
  });

  const response = http.post(
    `${BASE_URL}/api/attendance/scan`,
    payload,
    { headers: getHeaders() }
  );

  const checkResult = check(response, {
    'response received': (r) => r.status !== 0,
    'response time acceptable': (r) => r.timings.duration < 5000,
  });

  errorRate.add(!checkResult);

  // Shorter sleep for higher load
  sleep(0.5);
}

export function setup() {
  console.log('💪 Starting Stress Test...');
  console.log(`Base URL: ${BASE_URL}`);
  console.log('Target: Up to 400 concurrent users');
  console.log('=================================');
}

export function teardown() {
  console.log('=================================');
  console.log('✓ Stress Test Completed');
}
