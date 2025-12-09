const functions = require("firebase-functions");
const admin = require("firebase-admin");
const moment = require("moment-timezone");

admin.initializeApp();
const db = admin.firestore();

// --- GÖREV 1: GECE BEKÇİSİ (00:00) ---
exports.markChainsAsRisky = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("Europe/Istanbul")
  .onRun(async (context) => {
    const batch = db.batch();
    const yesterday = moment().tz("Europe/Istanbul").subtract(1, "days").format("YYYY-MM-DD");
    let count = 0;

    const snapshot = await db.collection("chains").where("status", "==", "active").get();

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (data.lastCheckInDate !== yesterday) {
        batch.update(doc.ref, { 
          status: "warning",
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        count++;
      }
    });

    if (count > 0) await batch.commit();
    console.log(count + " zincir uyarıldı.");
    return null;
  });

// --- GÖREV 2: ÖĞLEN YARGICI (12:00) ---
exports.breakChainsFinally = functions.pubsub
  .schedule("0 12 * * *")
  .timeZone("Europe/Istanbul")
  .onRun(async (context) => {
    const batch = db.batch();
    const today = moment().tz("Europe/Istanbul").format("YYYY-MM-DD");
    let count = 0;

    const snapshot = await db.collection("chains").where("status", "==", "warning").get();

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      if (data.lastCheckInDate !== today) {
        batch.update(doc.ref, { 
          status: "broken",
          streakCount: 0,
          brokenAt: admin.firestore.FieldValue.serverTimestamp()
        });
        count++;
      }
    });

    if (count > 0) await batch.commit();
    console.log(count + " zincir kırıldı.");
    return null;
  });