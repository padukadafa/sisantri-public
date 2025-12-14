const admin = require("firebase-admin");
const XLSX = require("xlsx");
const { v4: uuidv4 } = require("uuid");
const path = require("path");
const { Timestamp, db } = require("./config/firebase");

const auth = admin.auth();
const firestore = db;
async function generateUniqueEmail(name, auth) {
  function baseEmail() {
    const parts = name.toLowerCase().split(/\s+/);
    const first = parts[0];
    const lastInitial = parts.length > 1 ? parts[parts.length - 1][0] : "x";
    const random3 = Math.floor(100 + Math.random() * 900);
    return `${first}.${random3}@ppmaw.my.id`;
  }

  let email;

  while (true) {
    email = baseEmail();
    try {
      // Jika email ada → userRecord berisi profil user
      await auth.getUserByEmail(email);
      console.log(`Email duplikat ditemukan (${email}), generate ulang...`);
      // lanjut ulang loop
    } catch (err) {
      if (err.code === "auth/user-not-found") {
        // Email benar-benar unik
        return email;
      } else {
        throw err;
      }
    }
  }
}
function generatePassword() {
  return "Santri@" + uuidv4().substring(0, 3);
}

async function importSantri() {
  const filePath = path.join(__dirname, "data_santri.xlsx");
  const workbook = XLSX.readFile(filePath);

  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];

  let rows = XLSX.utils.sheet_to_json(sheet, { defval: "" });

  console.log("Total santri:", rows.length);

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];

    const nama = row.nama || row.Nama || row.nama_santri || row.NAMA;
    if (!nama) {
      console.log(`Baris ${i + 1} dilewati (kolom nama tidak ada).`);
      continue;
    }

    const email = await generateUniqueEmail(nama, auth);
    const password = generatePassword();

    try {
      // === Create User in Firebase Auth ===
      const userRecord = await auth.createUser({
        email,
        password,
        displayName: nama,
      });

      // === Save to Firestore ===
      await firestore.collection("users").doc(userRecord.uid).set({
        id: userRecord.uid,
        nama,
        email,
        deviceTokens: [],
        fotoProfil: null,
        poin: 0,
        role: "santri",
        rfidCardId: null,
        statusAktif: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // === Save password to Excel row ===
      rows[i].password = password;

      console.log(`SUKSES → ${nama} | ${email} | password: ${password}`);
    } catch (err) {
      console.log(`GAGAL → ${nama}:`, err.message);
      rows[i].password = "GAGAL";
    }
  }

  // === Write updated data to new Excel file ===
  const newSheet = XLSX.utils.json_to_sheet(rows);
  const newWorkbook = XLSX.utils.book_new();

  XLSX.utils.book_append_sheet(newWorkbook, newSheet, sheetName);

  const outputFile = path.join(__dirname, "data_santri_hasil.xlsx");
  XLSX.writeFile(newWorkbook, outputFile);

  console.log(`\nImport selesai! File hasil: ${outputFile}`);
}
async function fixUsers() {
  const filePath = path.join(__dirname, "data_santri_hasil.xlsx");
  const workbook = XLSX.readFile(filePath);

  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];

  let rows = XLSX.utils.sheet_to_json(sheet, { defval: "" });

  let allUsers = [];
  let nextPageToken = undefined;

  do {
    const list = await admin.auth().listUsers(1000, nextPageToken);

    list.users.forEach((user) => {
      allUsers.push({
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        phoneNumber: user.phoneNumber,
        disabled: user.disabled,
      });
    });

    nextPageToken = list.pageToken;
  } while (nextPageToken);

  allUsers.forEach(async (user) => {
    await firestore.collection("users").doc(user.uid).set(
      {
        id: user.uid,
        nama: null,
        email: user.email,
        deviceTokens: [],
        fotoProfil: null,
        poin: 0,
        role: "santri",
        rfidCardId: null,
        statusAktif: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        tempatKos: null,
        tanggalLahir: null,
        alamat: null,
        jurusan: null,
        kampus: null,
        jenis_kelamin: "perempuan",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}
async function fixJenisKelamin() {
  const filePath = path.join(__dirname, "data_santri_hasil.xlsx");
  const workbook = XLSX.readFile(filePath);

  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];

  let rows = XLSX.utils.sheet_to_json(sheet, { defval: "" });

  let allUsers = [];
  let nextPageToken = undefined;

  do {
    const list = await admin.auth().listUsers(1000, nextPageToken);

    list.users.forEach((user) => {
      allUsers.push({
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        phoneNumber: user.phoneNumber,
        disabled: user.disabled,
      });
    });

    nextPageToken = list.pageToken;
  } while (nextPageToken);
  for (let i = 0; i < rows.length; i++) {
    rows = rows.map((row) => {
      const matchedUser = allUsers.find(
        (user) => user.email.toLowerCase() === row.email.toLowerCase()
      );
      if (matchedUser) {
        console.log(`Updating ${matchedUser.email} name to ${row.nama}`);
        const nama = row.nama || row.Nama || row.nama_santri || row.NAMA;
        firestore
          .collection("users")
          .doc(matchedUser.uid)
          .update({
            nama,
            jenis_kelamin: row.jenis_kelamin || "perempuan",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
      } else {
        console.log(`No match for email: ${row.email}`);
      }
    });
  }
}
async function fixName() {
  const presensi = firestore.collection("presensi").get();
  await presensi.then(async (snapshot) => {
    snapshot.forEach((doc) => {
      const data = doc.data();
      const namaSantri = data.userName;
      if (data.userId && namaSantri) {
        firestore.collection("users").doc(data.userId).update({
          nama: namaSantri.trim(),
        });
        console.log(`Updated: ${doc.id} -> ${namaSantri.trim()}`);
      }
    });
  });
}
async function fixPoin() {
  const usersSnapshot = await firestore.collection("users").get();
  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;

    const presensiSnapshot = await firestore
      .collection("presensi")
      .where("userId", "==", userId)
      .where("status", "==", "hadir")
      .get();

    let totalPoin = 0;
    presensiSnapshot.forEach((presensiDoc) => {
      const presensiData = presensiDoc.data();
      if (presensiData.poin) {
        totalPoin += presensiData.poin;
      }
    });

    await firestore.collection("users").doc(userId).update({
      poin: totalPoin,
    });

    console.log(`Updated poin for user ${userId}: ${totalPoin}`);
  }
}
async function updateStatus() {
  const usersSnapshot = await firestore.collection("users").get();
  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    const userData = userDoc.data();

    if (userData.statusAktif === undefined) {
      await firestore.collection("users").doc(userId).update({
        statusAktif: true,
      });
      console.log(`Updated statusAktif for user ${userId} to true`);
    }
  }
}
async function fixPoint() {
  const usersSnapshot = await firestore.collection("users").get();
  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    if (userDoc.data().role !== "santri") {
      continue;
    }
    await firestore
      .collection("presensi_aggregates")
      .doc(`${userId}_monthly_2025-12`)
      .update({
        totalPoin: userDoc.data().poin || 0,
      });
    await firestore
      .collection("presensi_aggregates")
      .doc(`${userId}_yearly_2025`)
      .update({
        totalPoin: userDoc.data().poin || 0,
      });
    await firestore
      .collection("presensi_aggregates")
      .doc(`${userId}_semester_2025-S2`)
      .update({
        totalPoin: userDoc.data().poin || 0,
      });

    console.log(`Updated poin for user ${userId}: ${userDoc.data().poin}`);
  }
}
async function fixPresensi() {
  const usersSnapshot = await firestore.collection("users").get();
  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    if (userDoc.data().role !== "santri") {
      continue;
    }
    const presensiSnapshot = await firestore
      .collection("presensi")
      .where("userId", "==", userId)
      .get();

    for (const presensiDoc of presensiSnapshot.docs) {
      const presensiData = presensiDoc.data();
      await firestore
        .collection("presensi_aggregates")
        .where("userId", "==", userId)
        .where("periode", "==", "daily")
        .get()
        .then(async (aggregateSnapshot) => {
          for (const aggregateDoc of aggregateSnapshot.docs) {
            const aggregateData = aggregateDoc.data();
            const totalPoin = aggregateData.totalAlpha || 0;
            const totalAlpha = presensiData.status === "hadir";
            const totalSakit = aggregateData.totalSakit || 0;
            const totalIzin = aggregateData.totalIzin || 0;
            const totalHadir = aggregateData.totalHadir || 0;
            await firestore
              .collection("presensi_aggregates")
              .doc(aggregateDoc.id)
              .update({
                totalPoin,
                totalAlpha,
                totalSakit,
                totalIzin,
                totalHadir,
              });
            console.log(
              `Updated aggregate ${aggregateDoc.id} for user ${userId}`
            );
          }
        });
    }
    await firestore
      .collection("presensi_aggregates")
      .doc(`${userId}_monthly_2025-12`)
      .update({
        totalPoin: userDoc.data().poin || 0,
      });
    await firestore
      .collection("presensi_aggregates")
      .doc(`${userId}_yearly_2025`)
      .update({
        totalPoin: userDoc.data().poin || 0,
      });
    await firestore
      .collection("presensi_aggregates")
      .doc(`${userId}_semester_2025-S2`)
      .update({
        totalPoin: userDoc.data().poin || 0,
      });

    console.log(`Updated poin for user ${userId}: ${userDoc.data().poin}`);
  }
}
async function fixWeekly() {
  const aggregates = firestore.collection("presensi_aggregates");
  const snapshot = await aggregates
    .where("periode", "==", "yearly")
    .where("periodeKey", "==", "2025")
    .get();
  const jadwal = await firestore
    .collection("jadwal")
    .where("tanggal", ">=", Timestamp.fromDate(new Date("2025-11-30")))
    .where("tanggal", "<=", Timestamp.fromDate(new Date("2025-12-14")))
    .get();
  const presensi = [];

  for (const doc of jadwal.docs) {
    const data = doc.data();
    const presensiSnapshot = await firestore
      .collection("presensi")
      .where("jadwalId", "==", doc.id)
      .get();
    presensiSnapshot.forEach((presensiDoc) => {
      presensi.push(presensiDoc);
    });

    // jadwal.forEach((jadwalDoc) => {
    //   console.log(
    //     `Jadwal: ${jadwalDoc.id} - ${JSON.stringify(jadwalDoc.data())}`
    //   );
    // });

    // let totalHadir = 0;
    // let totalIzin = 0;
    // let totalSakit = 0;
    // let totalAlpha = 0;

    // presensi.forEach((presensiDoc) => {
    //   const presensiData = presensiDoc.data();
    //   if (presensiData.status === "hadir") {
    //     totalHadir += 1;
    //   } else if (presensiData.status === "izin") {
    //     totalIzin += 1;
    //   } else if (presensiData.status === "sakit") {
    //     totalSakit += 1;
    //   } else if (presensiData.status === "alpha") {
    //     totalAlpha += 1;
    //   }
    // });
    // print(totalHadir, totalIzin, totalSakit, totalAlpha);

    // if (
    //   data.totalAlpha + data.totalHadir + data.totalIzin + data.totalSakit >
    //   9
    // ) {
    //   await aggregates.doc(doc.id).update({
    //     totalAlpha: 9 - (data.totalHadir + data.totalIzin + data.totalSakit),
    //   });
    //   console.log(`Updated ${doc.id}`);
    // }
    // await aggregates.doc(doc.id).update({
    //   totalPoin: data.totalHadir,
    // });
  }
  for (const doc of snapshot.docs) {
    const data = doc.data();
    let totalHadir = 0;
    let totalIzin = 0;
    let totalSakit = 0;
    let totalAlpha = 0;

    presensi
      .filter((e) => e.data().userId === data.userId)
      .forEach((presensiDoc) => {
        const presensiData = presensiDoc.data();
        if (presensiData.userId === data.userId) {
          if (presensiData.status === "hadir") {
            totalHadir += 1;
          } else if (presensiData.status === "izin") {
            totalIzin += 1;
          } else if (presensiData.status === "sakit") {
            totalSakit += 1;
          } else if (presensiData.status === "alpha") {
            totalAlpha += 1;
          }
        }
      });

    await aggregates.doc(doc.id).update({
      totalHadir,
      totalIzin,
      totalSakit,
      totalAlpha,
      totalPoin: totalHadir,
    });
    console.log(
      `Updated ${doc.id} - H:${totalHadir} I:${totalIzin} S:${totalSakit} A:${totalAlpha}`
    );
  }
}
fixWeekly();
