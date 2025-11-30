const { db, Timestamp, FieldValue } = require("../config/firebase");
const { getWIBDate } = require("../helper/helper");

async function checkRegisterStatus() {
    try { 
        const modeRef = db.collection("rfid_scan_config").orderBy('requestedAt','desc').limit(1);
        const doc = await modeRef.get();

        if (doc.empty) {
            console.log("No such document!");
            return null;
        } else {
            console.log("Current mode:", doc.docs[0].data());
            return doc.docs[0].data();
        }
    } catch (error) {
        console.error("Error getting current mode:", error);
        return null;
    }
}
async function updateRFID(configId, rfidUid, userId) {
    try {
        const configRef = db.collection("rfid_scan_config").doc(configId);
        const checkRegisteredRFID = await db.collection("users").where("rfidCardId", "==", rfidUid).get();
        if (!checkRegisteredRFID.empty) {
            console.log(`RFID ${rfidUid} is already registered to another user.`);
            return "RFID sudah terdaftar.";
        }
        await configRef.update({
            rfidCardId: rfidUid,
            userId: userId,
            updatedAt: Timestamp.fromDate(getWIBDate()),
            isActive: false,
            status: "success",
        });
        await db.collection("users").doc(userId).update({
            rfidCardId: rfidUid,
            updatedAt: Timestamp.fromDate(getWIBDate()),
        });
        console.log(`RFID ${rfidUid} registered to user ${userId} in config ${configId}`);
    } catch (error) {
        console.error("Error updating RFID scan config:", error);
    }
}
module.exports = { checkRegisterStatus, updateRFID };