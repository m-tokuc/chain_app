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

// --- GÖREV 2: ÖĞLEN YARGICI (12:00) - BİLDİRİM EKLENDİ VE ASYNC DÜZELTİLDİ ---
exports.breakChainsFinally = functions.pubsub
  .schedule("0 12 * * *")
  .timeZone("Europe/Istanbul")
  .onRun(async (context) => {
    const batch = db.batch();
    const today = moment().tz("Europe/Istanbul").format("YYYY-MM-DD");
    let count = 0;

    const snapshot = await db.collection("chains").where("status", "==", "warning").get();

    // Düzeltme: Async işlemler için forEach yerine for...of döngüsü kullanılıyor
    for (const doc of snapshot.docs) { 
      const data = doc.data();
      if (data.lastCheckInDate !== today) {
        
        // 1. Veritabanı Güncellemesi (Zinciri Kır)
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
              title: `❌ ${data.name} Zinciri Kırıldı!`, // <--- YENİ BAŞLIK
              body: "Üzgünüm, 12:00'ye kadar check-in yapılmadı. Seriye baştan başlayın!", // <--- YENİ İÇERİK
              sound: 'default'
            }
          };
          try {
            await admin.messaging().sendToDevice(tokens, payload);
          } catch (e) {
            console.log("Kırılma bildirimi gönderme hatası:", e);
          }
        }
      }
    }

    if (count > 0) await batch.commit();
    console.log(count + " zincir kırıldı ve bildirimleri atıldı.");
    return null;
  });


// --- GÖREV 3: CHECK-IN BİLDİRİMİ (Anlık Çalışır) 🚀 ---
exports.sendCheckInNotification = functions.firestore
  .document('chains/{chainId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    const chainName = newData.name || "Zincir";

    // Kontrol 1: Streak (Seri) sayısı arttı mı? (Yani biri check-in yaptı mı?)
    if (newData.streakCount <= oldData.streakCount) return null;
    
    // Kontrol 2: Check-in yapan kişiyi bulalım (membersCompletedToday listesinden son eklenen)
    // Bu, flutter tarafında performCheckIn metodu ile güncellenmişti.
    const newMembersCompleted = newData.membersCompletedToday || [];
    const oldMembersCompleted = oldData.membersCompletedToday || [];
    
    // Yalnızca yeni eklenen (yani check-in yapan) kullanıcıyı bulmaya çalışıyoruz.
    const completedUserId = newMembersCompleted.find(id => !oldMembersCompleted.includes(id));
    if (!completedUserId) return null; // Kimin yaptığını bulamazsak dur

    // Check-in yapan kişinin kullanıcı adını bulmak için
    const userDoc = await db.collection('users').doc(completedUserId).get();
    const completedUsername = userDoc.exists ? userDoc.data().username : "Bir kullanıcı"; 

    const members = newData.members || [];
    const tokens = [];

    // Zincirdeki her üyeyi gez
    for (const memberId of members) {
      // Check-in yapan kişiye bildirim GÖNDERME
      if (memberId === completedUserId) continue; 
      
      const memberDoc = await db.collection('users').doc(memberId).get();
      if (memberDoc.exists) {
        const memberData = memberDoc.data();
        if (memberData.fcmToken) {
          tokens.push(memberData.fcmToken);
        }
      }
    }

    if (tokens.length === 0) return null;

    // Mesajı Hazırla
    const payload = {
      notification: {
        title: `🔥 ${chainName} Devam Ediyor!`, // <--- YENİ BAŞLIK
        body: `${completedUsername} zinciri bir gün daha uzattı. Sıra sende!`, // <--- YENİ İÇERİK
        sound: 'default'
      }
    };

    // Hepsine gönder
    await admin.messaging().sendToDevice(tokens, payload);
    console.log(`Check-in bildirimi gönderildi. Zincir: ${chainName}, Yapan: ${completedUsername}`);
    
    return null;
  });