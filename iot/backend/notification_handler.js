const { initializeApp } = require("firebase/app");
const { getFirestore, collection, onSnapshot } = require("firebase/firestore");
const admin = require("firebase-admin");
const serviceAccount = require("./belajar-login-system-firebase-adminsdk-vbat2-5f415066e7.json");
const firebaseConfig = {
  apiKey: "AIzaSyBHBxkWlXsFClsvrlA33OEgidInCLhyJ-A",
  authDomain: "jeka-85742.firebaseapp.com",
  projectId: "belajar-login-system",
  messagingSenderId: "266005122727",
  appId: "1:266005122727:android:81bd4f15e287243c03d582",
};
initializeApp(firebaseConfig);
const db = getFirestore();

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
admin.firestore();
async function sendNotificationToDevices(tokens, title, body) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log("Notifikasi berhasil dikirim:", response.successCount);
  } catch (error) {
    console.error("Gagal mengirim notifikasi:", error);
  }
}
const colRefPengumuman = collection(db, "pengumuman");
const colRefJadwal = collection(db, "jadwal");
onSnapshot(colRefPengumuman, (snapshot) => {
  snapshot.docChanges().forEach(async (change) => {
    const docId = change.doc.id;
    const data = change.doc.data();
    const pengumuman = await admin
      .firestore()
      .collection("pengumuman")
      .doc(docId)
      .get();
    const pengumumanData = pengumuman.data();
    if (!pengumuman.exists) {
      console.log("Pengumuman tidak ditemukan:", docId);
      return;
    }

    if (change.type === "added") {
      if (pengumumanData.isSended) {
        return;
      }
      if (!pengumumanData.isPublished) {
        return;
      }
      if (pengumumanData.tanggalMulai) {
        const tanggalMulai = new Date(pengumumanData.tanggalMulai);
        const now = new Date();
        if (tanggalMulai.getTime() > now.getTime()) {
          console.log(
            `Pengumuman ${docId} belum waktunya. Tanggal mulai: ${tanggalMulai}, Sekarang: ${now}`
          );
          return;
        }
      }
      const tokens = [];
      var users;
      if (pengumumanData.targetAudience === "santri") {
        users = await admin
          .firestore()
          .collection("users")
          .where("role", "==", "santri")
          .get();
      } else if (pengumumanData.targetAudience === "dewan_guru") {
        users = await admin
          .firestore()
          .collection("users")
          .where("role", "==", "dewan_guru")
          .get();
      } else {
        users = await admin.firestore().collection("users").get();
      }
      for (const user of users.docs) {
        const userData = user.data();
        const userTokens = userData.deviceTokens;
        if (!userTokens || userTokens.length === 0) {
          continue;
        }
        for (const token of userTokens) {
          tokens.push(token);
        }
      }
      if (tokens.length > 0) {
        await sendNotificationToDevices(
          tokens,
          "Pengumuman Baru",
          `Ada pengumuman baru dari ${pengumumanData.createdByName}: ${
            pengumumanData.konten ? pengumumanData.konten?.slice(0, 40) : ""
          }...`
        );
      }
      await admin
        .firestore()
        .collection("pengumuman")
        .doc(docId)
        .update({ isSended: true });
    }
  });
});
onSnapshot(colRefJadwal, (snapshot) => {
  snapshot.docChanges().forEach(async (change) => {
    const docId = change.doc.id;
    const data = change.doc.data();
    const jadwal = await admin
      .firestore()
      .collection("jadwal")
      .doc(docId)
      .get();
    const jadwalData = jadwal.data();
    if (!jadwal.exists) {
      console.log("Jadwal tidak ditemukan:", docId);
      return;
    }
    if (change.type === "added") {
      if (jadwalData.isSended) {
        return;
      }
      const tokens = [];
      const users = await admin.firestore().collection("users").get();
      for (const user of users.docs) {
        const userData = user.data();
        const userTokens = userData.deviceTokens;
        if (!userTokens || userTokens.length === 0) {
          continue;
        }
        for (const token of userTokens) {
          tokens.push(token);
        }
      }
      if (tokens.length > 0) {
        await sendNotificationToDevices(
          tokens,
          "Jadwal Baru",
          `Ada jadwal baru : ${
            data.deskripsi ? data.deskripsi?.slice(0, 40) : ""
          }...`
        );
      }
      await admin
        .firestore()
        .collection("jadwal")
        .doc(docId)
        .update({ isSended: true });
    }
  });
});
