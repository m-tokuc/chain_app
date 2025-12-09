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
// --- GÖREV 2: ÖĞLEN YARGICI (GÜNCELLENMİŞ VERSİYON) ---
exports.breakChainsFinally = functions.pubsub
  .schedule("0 12 * * *")
  .timeZone("Europe/Istanbul")
  .onRun(async (context) => {
    const batch = db.batch();
    const today = moment().tz("Europe/Istanbul").format("YYYY-MM-DD");
    let count = 0;

    const snapshot = await db.collection("chains").where("status", "==", "warning").get();

    // Döngü içinde async işlem yapacağımız için 'for...of' kullanıyoruz
    for (const doc of snapshot.docs) {
      const data = doc.data();
      if (data.lastCheckInDate !== today) {
        
        // 1. Veritabanı Güncellemesi
        batch.update(doc.ref, { 
          status: "broken",
          streakCount: 0,
          brokenAt: admin.firestore.FieldValue.serverTimestamp()
        });
        count++;

        // 2. BİLDİRİM GÖNDERME (YENİ EKLEME) 🔔
        const members = data.members || [];
        const tokens = [];

        // Üyelerin tokenlarını bul
        for (const memberId of members) {
          const userDoc = await db.collection('users').doc(memberId).get();
          if (userDoc.exists && userDoc.data().fcmToken) {
            tokens.push(userDoc.data().fcmToken);
          }
        }

        if (tokens.length > 0) {
          const payload = {
            notification: {
              title: 'Zincir Kırıldı 😔',
              body: `Üzgünüm, ${data.name} zinciri için süre doldu.`,
              sound: 'default'
            }
          };
          // Hata olsa bile zincir kırma işlemi durmasın diye try-catch
          try {
            await admin.messaging().sendToDevice(tokens, payload);
          } catch (e) {
            console.log("Bildirim hatası:", e);
          }
        }
      }
    }

    if (count > 0) await batch.commit();
    console.log(count + " zincir kırıldı ve bildirimleri atıldı.");
    return null;
  });
  // --- GÖREV 3: CHECK-IN BİLDİRİMİ (Anlık Çalışır) ---
exports.sendCheckInNotification = functions.firestore
  .document('chains/{chainId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();

    // Sadece streak arttıysa (yani check-in yapıldıysa) çalış
    if (newData.streakCount > oldData.streakCount) {
      const members = newData.members || [];
      const chainName = newData.name || "Zincir";

      // Bildirimi alacak kişilerin Tokenlarını bulmamız lazım
      const tokens = [];
      
      // Üyelerin profillerini gez
      for (const memberId of members) {
        // (İsterseniz check-in yapan kişiye atmamak için buraya 'if' koyabilirsiniz)
        const userDoc = await db.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          if (userData.fcmToken) {
            tokens.push(userData.fcmToken);
          }
        }
      }

      // Eğer atacak kimse yoksa dur
      if (tokens.length === 0) return null;

      // Mesajı Hazırla
      const payload = {
        notification: {
          title: 'Zincir Devam Ediyor! 🔥',
          body: `${chainName} grubunda biri check-in yaptı. Sıra sende!`,
          sound: 'default'
        }
      };

      // Hepsine gönder
      await admin.messaging().sendToDevice(tokens, payload);
      console.log("Bildirim gönderildi:", tokens.length, "kişi");
    }
    return null;
  });