# RFID Scanner Integration Guide

## Sistem Alur Kerja

### 1. Dari Aplikasi Mobile (Flutter)

```dart
// User meminta scan RFID
final requestId = await RfidScanService.createScanRequest(
  userId: currentUser.id,
  userName: currentUser.nama,
);

// Monitor hasil scan
RfidScanService.watchScanRequest(requestId).listen((config) {
  if (config.status == RfidScanStatus.success) {
    // RFID berhasil di-scan
    print('RFID Card ID: ${config.rfidCardId}');
  }
});
```

### 2. Di Firestore (Collection: `rfid_scan_config`)

Dokumen yang dibuat:

```json
{
  "id": "abc123",
  "userId": "user_123",
  "userName": "Ahmad Santri",
  "status": "waiting",
  "requestedAt": "2025-11-29T10:00:00Z",
  "isActive": true,
  "rfidCardId": null,
  "scannedAt": null,
  "scannedBy": null,
  "errorMessage": null
}
```

### 3. Alat Scanner RFID (Arduino/ESP32)

Scanner akan:

1. Monitor collection `rfid_scan_config` untuk dokumen dengan `status: "waiting"`
2. Ketika ada request, tampilkan info user di LCD/LED
3. Tunggu kartu RFID ditempelkan
4. Baca UID kartu RFID
5. Update dokumen dengan RFID Card ID dan status "success"

## Implementasi Scanner (Node.js Backend)

### Install Dependencies

```bash
npm install firebase-admin serialport
```

### Scanner Service (`iot/backend/services/rfid_scanner_service.js`)

```javascript
const admin = require("firebase-admin");
const { SerialPort } = require("serialport");
const { ReadlineParser } = require("@serialport/parser-readline");

class RfidScannerService {
  constructor() {
    this.db = admin.firestore();
    this.port = null;
    this.parser = null;
    this.deviceId = process.env.SCANNER_DEVICE_ID || "scanner_01";
    this.isScanning = false;
    this.currentRequest = null;
  }

  // Initialize serial port untuk komunikasi dengan Arduino
  async initializeSerialPort(portPath = "/dev/ttyUSB0") {
    try {
      this.port = new SerialPort({
        path: portPath,
        baudRate: 9600,
      });

      this.parser = this.port.pipe(new ReadlineParser({ delimiter: "\n" }));

      // Listen data dari Arduino (UID kartu RFID)
      this.parser.on("data", async (data) => {
        await this.handleRfidScan(data.trim());
      });

      console.log(`✅ Serial port initialized: ${portPath}`);
    } catch (error) {
      console.error("❌ Failed to initialize serial port:", error);
      throw error;
    }
  }

  // Monitor request scan dari Firestore
  async startMonitoring() {
    console.log("🔍 Monitoring RFID scan requests...");

    this.db
      .collection("rfid_scan_config")
      .where("isActive", "==", true)
      .where("status", "==", "waiting")
      .orderBy("requestedAt", "asc")
      .limit(1)
      .onSnapshot(async (snapshot) => {
        if (snapshot.empty) {
          this.currentRequest = null;
          this.isScanning = false;
          this.sendToArduino("IDLE");
          return;
        }

        const doc = snapshot.docs[0];
        const request = { id: doc.id, ...doc.data() };

        // Skip jika sudah di-handle
        if (this.currentRequest?.id === request.id) return;

        this.currentRequest = request;
        this.isScanning = true;

        console.log(
          `📋 New scan request: ${request.userName} (${request.userId})`
        );

        // Update status ke "scanning"
        await this.updateRequestStatus(request.id, "scanning");

        // Kirim info ke Arduino untuk display
        this.sendToArduino(`SCAN:${request.userName}`);
      });
  }

  // Handle data RFID dari Arduino
  async handleRfidScan(rfidUid) {
    if (!this.isScanning || !this.currentRequest) {
      console.log("⚠️ Received RFID but no active request");
      return;
    }

    try {
      console.log(`🎫 RFID Scanned: ${rfidUid}`);

      // Cek apakah RFID sudah terdaftar
      const existingUser = await this.db
        .collection("users")
        .where("rfidCardId", "==", rfidUid)
        .limit(1)
        .get();

      if (!existingUser.empty) {
        // RFID sudah dipakai user lain
        await this.updateRequestStatus(
          this.currentRequest.id,
          "failed",
          null,
          "RFID card sudah terdaftar untuk user lain"
        );
        this.sendToArduino("ERROR:RFID_USED");
        return;
      }

      // Update request dengan RFID Card ID
      await this.updateRequestStatus(
        this.currentRequest.id,
        "success",
        rfidUid
      );

      // Update user dengan RFID
      await this.db.collection("users").doc(this.currentRequest.userId).update({
        rfidCardId: rfidUid,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `✅ RFID registered: ${this.currentRequest.userName} -> ${rfidUid}`
      );
      this.sendToArduino("SUCCESS");

      // Reset state
      this.currentRequest = null;
      this.isScanning = false;
    } catch (error) {
      console.error("❌ Error handling RFID scan:", error);
      await this.updateRequestStatus(
        this.currentRequest.id,
        "failed",
        null,
        error.message
      );
      this.sendToArduino("ERROR:SYSTEM");
    }
  }

  // Update status request di Firestore
  async updateRequestStatus(
    requestId,
    status,
    rfidCardId = null,
    errorMessage = null
  ) {
    const updateData = {
      status: status,
      scannedAt: admin.firestore.FieldValue.serverTimestamp(),
      scannedBy: this.deviceId,
    };

    if (rfidCardId) {
      updateData.rfidCardId = rfidCardId;
    }

    if (errorMessage) {
      updateData.errorMessage = errorMessage;
    }

    if (["success", "failed", "cancelled"].includes(status)) {
      updateData.isActive = false;
    }

    await this.db
      .collection("rfid_scan_config")
      .doc(requestId)
      .update(updateData);
  }

  // Kirim command ke Arduino
  sendToArduino(command) {
    if (this.port && this.port.isOpen) {
      this.port.write(`${command}\n`);
      console.log(`📤 Sent to Arduino: ${command}`);
    }
  }

  // Cleanup old requests (jalankan periodik)
  async cleanupOldRequests(olderThanMinutes = 30) {
    const cutoffTime = new Date(Date.now() - olderThanMinutes * 60 * 1000);

    const oldRequests = await this.db
      .collection("rfid_scan_config")
      .where("isActive", "==", true)
      .where("requestedAt", "<", cutoffTime)
      .get();

    const batch = this.db.batch();

    oldRequests.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: "failed",
        isActive: false,
        errorMessage: "Request timeout",
      });
    });

    await batch.commit();
    console.log(`🧹 Cleaned up ${oldRequests.size} old requests`);
  }
}

module.exports = RfidScannerService;
```

### Main Scanner App (`iot/backend/rfid_scanner_app.js`)

```javascript
const admin = require("firebase-admin");
const RfidScannerService = require("./services/rfid_scanner_service");

// Initialize Firebase Admin
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Start scanner service
const scanner = new RfidScannerService();

async function main() {
  try {
    // Initialize serial port (sesuaikan dengan port Arduino)
    await scanner.initializeSerialPort(
      process.env.SERIAL_PORT || "/dev/ttyUSB0"
    );

    // Start monitoring requests
    await scanner.startMonitoring();

    // Cleanup old requests setiap 5 menit
    setInterval(() => {
      scanner.cleanupOldRequests(30);
    }, 5 * 60 * 1000);

    console.log("🚀 RFID Scanner Service is running...");
  } catch (error) {
    console.error("❌ Failed to start scanner:", error);
    process.exit(1);
  }
}

main();
```

### Package.json

```json
{
  "name": "rfid-scanner-service",
  "version": "1.0.0",
  "scripts": {
    "start": "node rfid_scanner_app.js"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "serialport": "^12.0.0",
    "@serialport/parser-readline": "^12.0.0",
    "dotenv": "^16.0.0"
  }
}
```

### .env

```
SERIAL_PORT=/dev/ttyUSB0
SCANNER_DEVICE_ID=scanner_01
```

## Arduino Code (ESP32/Arduino)

```cpp
#include <SPI.h>
#include <MFRC522.h>
#include <LiquidCrystal_I2C.h>

#define RST_PIN 9
#define SS_PIN 10

MFRC522 mfrc522(SS_PIN, RST_PIN);
LiquidCrystal_I2C lcd(0x27, 16, 2);

String currentStatus = "IDLE";
String userName = "";

void setup() {
  Serial.begin(9600);
  SPI.begin();
  mfrc522.PCD_Init();

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("RFID Scanner");
  lcd.setCursor(0, 1);
  lcd.print("Ready");

  Serial.println("READY");
}

void loop() {
  // Baca command dari Node.js
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    handleCommand(command);
  }

  // Jika ada request scan, cek kartu RFID
  if (currentStatus == "SCANNING") {
    if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
      String uid = getCardUID();

      // Kirim UID ke Node.js
      Serial.println(uid);

      // Feedback visual
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Card Detected!");
      lcd.setCursor(0, 1);
      lcd.print("Processing...");

      delay(2000);
      mfrc522.PICC_HaltA();
    }
  }

  delay(100);
}

void handleCommand(String command) {
  if (command == "IDLE") {
    currentStatus = "IDLE";
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("RFID Scanner");
    lcd.setCursor(0, 1);
    lcd.print("Waiting...");
  }
  else if (command.startsWith("SCAN:")) {
    currentStatus = "SCANNING";
    userName = command.substring(5);

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Tap Card:");
    lcd.setCursor(0, 1);
    lcd.print(userName.substring(0, 16));
  }
  else if (command == "SUCCESS") {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Success!");
    lcd.setCursor(0, 1);
    lcd.print("RFID Registered");

    delay(3000);
    currentStatus = "IDLE";
  }
  else if (command.startsWith("ERROR:")) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Error!");
    lcd.setCursor(0, 1);

    if (command == "ERROR:RFID_USED") {
      lcd.print("Card In Use");
    } else {
      lcd.print("Try Again");
    }

    delay(3000);
    currentStatus = "IDLE";
  }
}

String getCardUID() {
  String uid = "";
  for (byte i = 0; i < mfrc522.uid.size; i++) {
    uid += String(mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
    uid += String(mfrc522.uid.uidByte[i], HEX);
  }
  uid.toUpperCase();
  return uid;
}
```

## Cara Penggunaan

### Setup Scanner Device

```bash
# 1. Install dependencies
cd iot/backend
npm install

# 2. Setup Firebase service account
# Download service account key dari Firebase Console
# Simpan sebagai serviceAccountKey.json

# 3. Setup serial port (Linux)
sudo chmod 666 /dev/ttyUSB0

# 4. Run scanner service
npm start
```

### Dari Aplikasi Mobile

```dart
// Di rfid_management_dialog.dart atau tempat lain
await showRfidScanDialog(
  context: context,
  userId: currentUser.id,
  userName: currentUser.nama,
  onSuccess: (rfidCardId) {
    print('RFID berhasil didaftarkan: $rfidCardId');
    // Refresh user data
  },
);
```

## Keuntungan Sistem Ini

1. ✅ **Tidak perlu NFC di HP** - Semua proses di alat scanner eksternal
2. ✅ **Real-time** - Firestore realtime listener untuk status update
3. ✅ **Scalable** - Bisa multiple scanner dalam satu sistem
4. ✅ **Reliable** - Auto cleanup request yang timeout
5. ✅ **User-friendly** - Visual feedback di LCD scanner
6. ✅ **Secure** - Validasi RFID duplicate di backend

## Monitoring & Maintenance

### Check Active Requests

```javascript
// Di Firebase Console atau backend
db.collection("rfid_scan_config")
  .where("isActive", "==", true)
  .get()
  .then((snapshot) => {
    console.log(`Active requests: ${snapshot.size}`);
  });
```

### Manual Cleanup

```javascript
const scanner = new RfidScannerService();
await scanner.cleanupOldRequests(30); // cleanup > 30 minutes
```
