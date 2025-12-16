
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendWhisperNotification = functions.firestore
  .document("whispers/{whisperId}")
  .onCreate(async (snapshot, context) => {
    const whisper = snapshot.data();

    const pairRef = admin.firestore().collection("pairs").doc(whisper.pairId);
    const pairDoc = await pairRef.get();
    const pair = pairDoc.data();

    let recipientToken;
    let senderNickname;

    if (whisper.senderId === pair.maleUserId) {
      recipientToken = pair.femaleFcmToken;
      senderNickname = pair.maleNickname;
    } else {
      recipientToken = pair.maleFcmToken;
      senderNickname = pair.femaleNickname;
    }

    if (recipientToken) {
      const payload = {
        notification: {
          title: `New message from ${senderNickname}`,
          body: whisper.text,
        },
        data: {
          pairId: whisper.pairId,
          type: "whisper",
        },
      };

      try {
        await admin.messaging().sendToDevice(recipientToken, payload);
        console.log("Notification sent successfully");
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    }
  });
