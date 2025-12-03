# K6 Load Testing untuk SiSantri IoT Backend

## 📋 Daftar Isi

- [Instalasi](#instalasi)
- [File Testing](#file-testing)
- [Cara Menjalankan](#cara-menjalankan)
- [Konfigurasi](#konfigurasi)
- [Interpretasi Hasil](#interpretasi-hasil)

## 🚀 Instalasi

### Install K6

**macOS:**

```bash
brew install k6
```

**Linux:**

```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

**Windows:**

```powershell
choco install k6
```

Atau download dari: https://k6.io/docs/getting-started/installation/

## 📁 File Testing

### 1. `smoke-test.js`

**Tujuan:** Validasi cepat untuk memastikan sistem berjalan dengan baik

- **Virtual Users (VUs):** 1
- **Duration:** 30 detik
- **Use Case:** Quick sanity check sebelum deployment

### 2. `load-test.js`

**Tujuan:** Menguji performa sistem dengan beban normal hingga tinggi

- **VUs:** 10 → 50 → 100
- **Duration:** ~5 menit
- **Use Case:** Simulasi traffic harian dengan peak hours

### 3. `stress-test.js`

**Tujuan:** Menemukan breaking point sistem

- **VUs:** 100 → 200 → 300 → 400
- **Duration:** ~28 menit
- **Use Case:** Mencari batas maksimal sistem

### 4. `spike-test.js`

**Tujuan:** Menguji ketahanan sistem terhadap lonjakan traffic mendadak

- **VUs:** 10 → 500 (sudden spike)
- **Duration:** ~3 menit
- **Use Case:** Black Friday, viral events, dll

## 🎯 Cara Menjalankan

### Menggunakan Script Runner (Recommended)

```bash
# Berikan permission executable
chmod +x k6-test.sh

# Jalankan semua test
./k6-test.sh all

# Jalankan test spesifik
./k6-test.sh smoke
./k6-test.sh load
./k6-test.sh stress
./k6-test.sh spike
```

### Menjalankan Manual

```bash
# Smoke test
k6 run smoke-test.js

# Load test
k6 run load-test.js

# Stress test
k6 run stress-test.js

# Spike test
k6 run spike-test.js
```

### Dengan Environment Variables

```bash
BASE_URL=https://your-api.com \
API_KEY=your-api-key \
DEVICE_ID=device-001 \
DEVICE_SECRET=your-secret \
k6 run load-test.js
```

## ⚙️ Konfigurasi

### Environment Variables

Buat file `.env.k6` untuk menyimpan konfigurasi:

```bash
BASE_URL=http://localhost:3000
API_KEY=your-api-key-here
DEVICE_ID=test-device-001
DEVICE_SECRET=your-device-secret-here
```

Load dengan:

```bash
export $(cat .env.k6 | xargs) && ./k6-test.sh smoke
```

### Modify Test Parameters

Edit file test untuk menyesuaikan:

**Load Test - `load-test.js`:**

```javascript
export const options = {
  stages: [
    { duration: "30s", target: 10 }, // Sesuaikan target VUs
    { duration: "1m", target: 50 }, // Sesuaikan durasi
    // ...
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // Sesuaikan threshold
  },
};
```

## 📊 Interpretasi Hasil

### Metrics Penting

#### 1. **http_req_duration**

- Waktu yang dibutuhkan untuk menyelesaikan request
- **Target:** p95 < 500ms (95% request di bawah 500ms)
- **Baik:** < 200ms
- **Acceptable:** 200-500ms
- **Perlu Optimasi:** > 500ms

#### 2. **http_req_failed**

- Persentase request yang gagal
- **Target:** < 1% untuk normal operation
- **Stress test:** < 30% acceptable
- **Masalah:** > 10% pada load normal

#### 3. **http_reqs**

- Jumlah total requests
- Digunakan untuk menghitung throughput (requests/second)

#### 4. **vus (Virtual Users)**

- Jumlah concurrent users
- Peak VUs menunjukkan beban maksimal

### Contoh Output

```
✓ health check status is 200
✓ rfid scan response is valid

checks.........................: 95.23% ✓ 1238  ✗ 62
data_received..................: 2.1 MB 42 kB/s
data_sent......................: 890 kB 18 kB/s
http_req_blocked...............: avg=1.2ms   min=2µs   med=8µs    max=156ms
http_req_duration..............: avg=125ms   min=12ms  med=98ms   max=1.2s    p(95)=456ms
http_req_failed................: 4.76%  ✓ 62    ✗ 1238
http_reqs......................: 1300   26/s
```

### Interpretasi:

- ✅ **Checks 95.23%** - Sangat baik (> 95%)
- ✅ **http_req_duration p95 456ms** - Memenuhi target < 500ms
- ⚠️ **http_req_failed 4.76%** - Sedikit tinggi, perlu investigasi
- ✅ **Throughput 26 req/s** - Sesuai dengan VUs

## 🎨 Visualisasi Hasil

### K6 Cloud (Recommended)

```bash
k6 login cloud --token YOUR_TOKEN
k6 cloud load-test.js
```

### Grafana + InfluxDB

```bash
# Output ke InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 load-test.js
```

### JSON Export

```bash
k6 run --out json=results.json load-test.js
```

## 🔧 Troubleshooting

### Error: "Connection refused"

```bash
# Pastikan server berjalan
npm start

# Test endpoint
curl http://localhost:3000/health
```

### Error: "Authentication failed"

```bash
# Periksa API key dan device credentials
echo $API_KEY
echo $DEVICE_ID
echo $DEVICE_SECRET
```

### High Error Rate

- Periksa database connection
- Monitor server resources (CPU, Memory)
- Check logs: `tail -f logs/app.log`
- Reduce VUs atau duration

## 📈 Best Practices

1. **Mulai dengan Smoke Test** - Validasi dasar sebelum test berat
2. **Jalankan di Environment Terpisah** - Jangan di production
3. **Monitor Server** - Perhatikan CPU, memory, database
4. **Gradual Load** - Naikkan beban secara bertahap
5. **Analisa Bottlenecks** - Identifikasi slow endpoints
6. **Dokumentasi** - Catat hasil dan improvement

## 📝 Catatan

- Test ini menggunakan data dummy RFID UIDs
- Sesuaikan RFID_UIDS dengan data real untuk test lebih akurat
- Hasil test berbeda-beda tergantung hardware dan network
- Jalankan multiple runs untuk hasil konsisten

## 🆘 Support

Jika ada pertanyaan atau issues:

1. Check documentation: https://k6.io/docs/
2. K6 Community: https://community.k6.io/
3. GitHub Issues: [Your Repo]

---

**Happy Load Testing! 🚀**
