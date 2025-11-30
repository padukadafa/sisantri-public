# 🔧 Firebase Setup Guide

## Status: Setup Required Before Deployment

---

## 📋 Prerequisites

Sebelum deployment, Anda perlu:

1. **Firebase Project** yang sudah dibuat di [Firebase Console](https://console.firebase.google.com)
2. **Firebase CLI** terinstall (✅ Already installed - version 14.1.0)
3. **Logged in** ke Firebase account

---

## 🚀 Quick Setup (5 menit)

### **Step 1: Login ke Firebase**

Jika belum login:

```bash
firebase login
```

Browser akan terbuka untuk authenticate. Login dengan Google account yang memiliki akses ke Firebase project.

---

### **Step 2: Initialize Firebase Project**

```bash
cd /Users/macbookairm2/Documents/sisantri
firebase use --add
```

Akan muncul pilihan project yang available:

- lakukan-beta
- lakukan-dev
- radio-40a5b
- transellia-1c934

**Atau jika project belum ada di list**, buat project baru dulu di [Firebase Console](https://console.firebase.google.com):

1. Click "Add project"
2. Masukkan nama: "sisantri" atau "belajar-login-system"
3. Follow wizard sampai selesai
4. Kembali ke terminal dan run `firebase use --add` lagi

**Pilih salah satu project**, kemudian beri alias (contoh: "default" atau "production")

Ini akan membuat file `.firebaserc`:

```json
{
  "projects": {
    "default": "your-project-id"
  }
}
```

---

### **Step 3: Verify Configuration**

Check project aktif:

```bash
firebase use
```

Output harus menunjukkan:

```
Active project: your-project-id (default)
```

---

### **Step 4: Deploy!**

Sekarang Anda bisa deploy Firestore:

```bash
# Deploy rules & indexes sekaligus
firebase deploy --only firestore

# Atau deploy terpisah:
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

---

## 🔍 Troubleshooting

### Problem: "No project is currently active"

**Solution:** Run `firebase use --add` dan pilih project

### Problem: "Project not found in list"

**Solution:**

1. Buat project baru di Firebase Console
2. Atau pastikan sudah login dengan account yang benar
3. Refresh list: `firebase projects:list`

### Problem: "Permission denied"

**Solution:**

1. Check account memiliki Owner/Editor role di Firebase project
2. Re-login: `firebase logout` then `firebase login`

### Problem: "Invalid credentials"

**Solution:**

1. Delete credentials: `rm ~/.config/firebase/*`
2. Re-login: `firebase login`

---

## 📝 What Project Should I Use?

**Recommendation:**

1. **If "belajar-login-system" exists** (mentioned in firebase_options.dart):

   - Use that project if available in Console
   - Or create new project with that name

2. **If using existing project from list**:

   - Use "lakukan-dev" for development/testing
   - Use "lakukan-beta" for production
   - Need to update `lib/firebase_options.dart` to match

3. **If creating new project**:
   - Name: "sisantri" (recommended)
   - Update `lib/firebase_options.dart` with new config

---

## 🔄 After Setup Complete

Once `firebase use --add` is done, you can proceed with deployment:

1. ✅ **Deploy Indexes & Rules:**

   ```bash
   firebase deploy --only firestore
   ```

2. ✅ **Run Migration:**

   ```bash
   flutter run scripts/migrate_aggregates.dart
   ```

3. ✅ **Test the App:**
   - Open app
   - Test Statistics page
   - Test Leaderboard

---

## 📚 Next Steps

After Firebase setup complete:

- 📖 Follow `DEPLOYMENT_CHECKLIST.md` for complete deployment
- 📖 Read `QUICK_START_AGGREGATES.md` for quick reference

---

## ⚡ Quick Commands

```bash
# Check current project
firebase use

# List all projects
firebase projects:list

# Switch project
firebase use <project-id>

# Deploy everything
firebase deploy --only firestore

# Deploy only rules
firebase deploy --only firestore:rules

# Deploy only indexes
firebase deploy --only firestore:indexes
```

---

**Need Help?**

- Firebase Console: https://console.firebase.google.com
- Firebase CLI Docs: https://firebase.google.com/docs/cli
