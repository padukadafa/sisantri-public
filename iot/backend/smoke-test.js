import http from 'k6/http';
import { check, sleep } from 'k6';

// Smoke test - minimal load to verify scan endpoint functionality
export const options = {
  vus: 1, // 1 virtual user
  duration: '30s', // 30 seconds
  thresholds: {
    'http_req_duration': ['p(95)<5000'], // 95% of requests should be below 5s
    'http_req_failed{endpoint:scan}': ['rate<0.30'], // Allow failures for business logic responses
    // Note: scan endpoint may return 403 due to business logic (no schedule, unregistered RFID, etc.)
    // We only check that endpoint responds properly, not the business logic result
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
  // Test: RFID scan endpoint
  const scanPayload = JSON.stringify({
    rfidUid: 'TEST_RFID_001',
  });

  const scanResponse = http.post(
    `${BASE_URL}/api/attendance/scan`,
    scanPayload,
    { 
      headers: getHeaders(),
      tags: { endpoint: 'scan' },
      timeout: '10s',
    }
  );

  const scanChecks = check(scanResponse, {
    'scan endpoint responds': (r) => r.status !== 0,
    'scan status is valid (200, 400, 403, or 404)': (r) => 
      [200, 400, 403, 404].includes(r.status),
    'scan response is valid JSON': (r) => {
      try {
        r.json();
        return true;
      } catch (e) {
        console.log('Failed to parse JSON:', r.body);
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
    'scan has message field': (r) => {
      try {
        return r.json('message') !== undefined;
      } catch (e) {
        return false;
      }
    },
  });

  // Log response details
  if (scanResponse.status === 200) {
    console.log('✓ Scan successful:', scanResponse.json('message'));
  } else if (scanResponse.status === 403) {
    console.log('⚠ Expected business logic (403):', scanResponse.json('message'));
  } else if (scanResponse.status === 400) {
    console.log('⚠ Validation error (400):', scanResponse.json('message'));
  } else if (scanResponse.status === 404) {
    console.log('✗ Endpoint not found (404) - API may not be deployed');
  } else {
    console.log(`✗ Unexpected status ${scanResponse.status}:`, scanResponse.body);
  }

  sleep(2);
}

export function setup() {
  console.log('🔍 Running Smoke Test - Scan Endpoint Only');
  console.log('='.repeat(50));
  console.log(`Base URL: ${BASE_URL}`);
  console.log(`Device ID: ${DEVICE_ID}`);
  console.log(`Testing: POST ${BASE_URL}/api/attendance/scan`);
  console.log('');
  console.log('Expected responses:');
  console.log('  - 200: Scan successful');
  console.log('  - 403: No schedule / RFID not registered (expected)');
  console.log('  - 400: Validation error');
  console.log('  - 404: Endpoint not found (backend not deployed)');
  console.log('');
}

export function teardown(data) {
  console.log('');
  console.log('='.repeat(50));
  console.log('✓ Smoke Test Completed');
  console.log('');
  console.log('Notes:');
  console.log('- 403 responses are expected if no schedule exists or RFID not registered');
  console.log('- This validates the API is responding, not the business logic');
  console.log('- Check server logs for detailed error messages');
  console.log('='.repeat(50));
}
