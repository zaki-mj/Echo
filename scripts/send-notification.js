const admin = require('firebase-admin');

// This script is executed by the GitHub Action

// Get environment variables passed from the workflow
const serverKey = process.env.FCM_SERVER_KEY;
const message = process.env.MESSAGE;
const token = process.env.TOKEN;
const senderName = process.env.SENDER_NAME;

if (!serverKey || !message || !token || !senderName) {
  console.error('Missing required environment variables.');
  process.exit(1);
}

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(JSON.parse(serverKey)),
});

// Construct the notification payload
const payload = {
  notification: {
    title: `A new message from ${senderName}`,
    body: message,
  },
  token: token,
};

// Send the notification
admin
  .messaging()
  .send(payload)
  .then((response) => {
    console.log('Successfully sent message:', response);
  })
  .catch((error) => {
    console.error('Error sending message:', error);
    process.exit(1);
  });
