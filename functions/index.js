const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp(); // só uma vez

exports.deleteUserByUid = functions
    .region("southamerica-east1") // ⬅️ mesma região do Firestore
    .https.onCall(async (data, ctx) => {
      const uid = data.uid;

      if (!uid) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "uid é obrigatório",
        );
      }

      await admin.auth().deleteUser(uid);
      return {ok: true};
    });
