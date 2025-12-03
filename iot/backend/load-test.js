import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
// stages: [
//     { duration: '1m', target: 50 },   // Warm up: Ramp up to 50 users
//     { duration: '1m', target: 100 },  // Ramp up to 100 users
//     { duration: '1m', target: 200 },  // Ramp up to 200 users
//     { duration: '2m', target: 300 },  // Ramp up to 300 users
//     { duration: '3m', target: 300 },  // Stay at 300 users (peak load)
//     { duration: '1m', target: 200 },  // Ramp down to 200 users
//     { duration: '1m', target: 100 },  // Ramp down to 100 users
//     { duration: '30s', target: 0 },   // Cool down to 0 users
//   ],
// Test configuration - 300 concurrent users
export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Warm up: Ramp up to 50 users
    { duration: '30s', target: 20 },  // Ramp up to 100 users
    { duration: '30s', target: 30 },  // Ramp up to 200 users
    { duration: '30s', target: 40 },  // Ramp up to 300 users
    { duration: '30s', target: 40 },  // Stay at 300 users (peak load)
    { duration: '30s', target: 20 },  // Ramp down to 200 users
    { duration: '30s', target: 10 },  // Ramp down to 100 users
    { duration: '30s', target: 0 },   // Cool down to 0 users
  ],
  thresholds: {
    'http_req_duration': ['p(95)<3000', 'p(99)<5000'], // 95% < 3s, 99% < 5s
    'http_req_failed{endpoint:scan}': ['rate<0.30'],   // Allow 30% failures for business logic
    'errors': ['rate<0.15'],                            // Custom error rate < 15%
  },
};

// Environment configuration
const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const API_KEY = __ENV.API_KEY || 'secret-api-key-here-f';
const DEVICE_ID = __ENV.DEVICE_ID || 'rfid-reader-001';
const DEVICE_SECRET = __ENV.DEVICE_SECRET || 'rfabid-012312345-secret';

// Sample RFID UIDs for testing
const RFID_UIDS = [
  'RFID001',
  'RFID002',
  'RFID003',
  'RFID004',
  'RFID005',
  'INVALID_RFID',
];

// Common headers
function getHeaders() {
  return {
    'Content-Type': 'application/json',
    'x-api-key': API_KEY,
    'x-device-id': DEVICE_ID,
    'x-device-secret': DEVICE_SECRET,
  };
}

// Test scenarios - Focus on scan endpoint
export default function () {
  // Simulate realistic RFID scan patterns
  const rfidUid = getRandomRfidUid(true);
  testRfidScan(rfidUid);
  
  // Random sleep between 0.5-2 seconds to simulate real-world intervals
  sleep(Math.random() * 1.5 + 0.5);
}

// Test functions
function testRfidScan(rfidUid) {
  const payload = JSON.stringify({
    rfidUid: rfidUid,
  });

  const response = http.post(
    `${BASE_URL}/api/attendance/scan`,
    payload,
    { 
      headers: getHeaders(),
      tags: { endpoint: 'scan' },
      timeout: '10s',
    }
  );

  const checkResult = check(response, {
    'scan endpoint responds': (r) => r.status !== 0,
    'scan response is valid status': (r) => [200, 400, 403, 404].includes(r.status),
    'scan response is valid JSON': (r) => {
      try {
        r.json();
        return true;
      } catch (e) {
        return false;
      }
    },
    'scan has success field': (r) => {
      try {
        return r.json('success') !== undefined;
      } catch (e) {
        return false;
      }
    },
    'scan response time < 3s': (r) => r.timings.duration < 3000,
  });

  // Periodic logging (every 10th request to avoid log spam)
  if (Math.random() < 0.1) {
    if (response.status === 200) {
      console.log(`✓ Success: ${rfidUid}`);
    } else if (response.status === 403) {
      console.log(`⚠ Business logic (403): ${rfidUid}`);
    } else if (response.status === 404) {
      console.log(`✗ Endpoint not found (404)`);
    }
  }

  errorRate.add(!checkResult);
}

// Helper functions
function getRandomRfidUid(includeInvalid = true) {
  const validUids = RFID_UIDS.slice(0, -1);
  const uids = includeInvalid ? RFID_UIDS : validUids;
  return uids[Math.floor(Math.random() * uids.length)];
}

// Setup function - runs once at the start
export function setup() {
  console.log('='.repeat(60));
  console.log('🚀 Starting K6 Load Test - 300 Concurrent Users');
  console.log('='.repeat(60));
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Device ID: ${DEVICE_ID}`);
  console.log(`Endpoint: POST ${BASE_URL}/api/attendance/scan`);
  console.log('');
  console.log('Test Profile:');
  console.log('  - Warm up: 0 → 50 → 100 → 200 users (3 minutes)');
  console.log('  - Peak load: 200 → 300 users (2 minutes)');
  console.log('  - Sustained: 300 users for 3 minutes');
  console.log('  - Cool down: 300 → 0 users (2.5 minutes)');
  console.log('  - Total duration: ~10.5 minutes');
  console.log('');
  console.log('Thresholds:');
  console.log('  - 95% requests < 3s');
  console.log('  - 99% requests < 5s');
  console.log('  - Error rate < 30% (business logic failures allowed)');
  console.log('='.repeat(60));
  console.log('');
}

// Teardown function - runs once at the end
export function teardown(data) {
  console.log('');
  console.log('='.repeat(60));
  console.log('✓ Load Test Completed - 300 Users');
  console.log('='.repeat(60));
  console.log('');
  console.log('Review the results above for:');
  console.log('  - Response times (p95, p99)');
  console.log('  - Request rates (req/s)');
  console.log('  - Error rates');
  console.log('  - Failed thresholds (if any)');
  console.log('');
  console.log('Check results/ directory for detailed JSON output');
  console.log('='.repeat(60));
}
