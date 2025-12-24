// file: functions/index.js

// =====================================================================================================================
// IMPORTS GÉNÉRAUX ET INITIALISATION
// =====================================================================================================================
const { onDocumentDeleted, onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler"); // NOUVEAU: Import pour les fonctions planifiées
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { getFirestore } = require('firebase-admin/firestore');
const AWS = require("aws-sdk");
const mime = require("mime-types");
const axios = require("axios");
const { v4: uuidv4 } = require("uuid");
const { SecretManagerServiceClient } = require("@google-cloud/secret-manager");
const secretClient = new SecretManagerServiceClient();

admin.initializeApp();
const db = getFirestore();
const messaging = admin.messaging();


let r2SecretsCache = null;
let s3Client = null;
let lygosSecretsCache = null;

// =====================================================================================================================
// FONCTIONS DE GESTION DES SECRETS
// =====================================================================================================================
async function getR2Secrets() {
  if (r2SecretsCache) {
    console.log("[getR2Secrets] Secrets récupérés du cache.");
    return r2SecretsCache;
  }
  const projectId = process.env.GCLOUD_PROJECT;
  const secretNames = [
    "R2_ACCOUNT_ID", "R2_ACCESS_KEY_ID", "R2_SECRET_ACCESS_KEY", "R2_BUCKET", "R2_PUBLIC_DEV_URL",
  ];
  try {
    const requests = secretNames.map((name) => secretClient.accessSecretVersion({ name: `projects/${projectId}/secrets/${name}/versions/latest` }));
    const [r2AccountIdRes, r2AccessKeyIdRes, r2SecretAccessKeyRes, r2BucketRes, r2PublicDevUrlRes] = await Promise.all(requests);
    const secrets = {
      R2_ACCOUNT_ID: r2AccountIdRes[0].payload.data.toString("utf8"),
      R2_ACCESS_KEY_ID: r2AccessKeyIdRes[0].payload.data.toString("utf8"),
      R2_SECRET_ACCESS_KEY: r2SecretAccessKeyRes[0].payload.data.toString("utf8"),
      R2_BUCKET: r2BucketRes[0].payload.data.toString("utf8"),
      R2_PUBLIC_DEV_URL: r2PublicDevUrlRes[0].payload.data.toString("utf8"),
    };
    r2SecretsCache = secrets;
    return secrets;
  } catch (error) {
    console.error("[getR2Secrets] Erreur FATALE lors de la récupération des secrets R2:", error);
    throw new Error("Impossible de récupérer les secrets R2: " + error.message);
  }
}

async function getLygosSecrets() {
  if (lygosSecretsCache) {
    console.log("[getLygosSecrets] Secrets Lygos récupérés du cache.");
    return lygosSecretsCache;
  }
  const projectId = process.env.GCLOUD_PROJECT;
  const secretNames = [
    "LYGOS_API_KEY", "LYGOS_GATEWAY_URL",
  ];
  try {
    const requests = secretNames.map((name) => secretClient.accessSecretVersion({ name: `projects/${projectId}/secrets/${name}/versions/latest` }));
    const [lygosApiKeyRes, lygosGatewayUrlRes] = await Promise.all(requests);
    const secrets = {
      LYGOS_API_KEY: lygosApiKeyRes[0].payload.data.toString("utf8"),
      LYGOS_GATEWAY_URL: lygosGatewayUrlRes[0].payload.data.toString("utf8"),
    };
    lygosSecretsCache = secrets;
    return secrets;
  } catch (error) {
    console.error("[getLygosSecrets] Erreur FATALE lors de la récupération des secrets Lygos:", error);
    throw new Error("Impossible de récupérer les secrets Lygos: " + error.message);
  }
}

// =====================================================================================================================
// FONCTIONS DE GESTION CLOUDFLARE R2
// =====================================================================================================================
async function initializeS3Client() {
  if (s3Client) {
    console.log("[initializeS3Client] Client S3 récupéré du cache.");
    return s3Client;
  }
  try {
    const secrets = await getR2Secrets();
    s3Client = new AWS.S3({
      endpoint: `https://${secrets.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      accessKeyId: secrets.R2_ACCESS_KEY_ID,
      secretAccessKey: secrets.R2_SECRET_ACCESS_KEY,
      signatureVersion: "v4",
      region: "auto",
    });
    return s3Client;
  } catch (error) {
    console.error("[initializeS3Client] Erreur FATALE lors de l'initialisation du client S3:", error);
    throw new Error("Impossible d'initialiser le client S3 pour R2: " + error.message);
  }
}

exports.deleteR2ImagesOnProductDelete = onDocumentDeleted("profiles/{userId}/stores/{storeId}/products/{productId}", async (event) => {
    const deletedSnapshot = event.data;
    if (!deletedSnapshot || !deletedSnapshot.exists) return null;
    const S3 = await initializeS3Client();
    const secrets = r2SecretsCache;
    const productData = deletedSnapshot.data();
    if (!productData) return null;
    const imageUrls = productData.imageUrls;
    if (!imageUrls || !Array.isArray(imageUrls) || imageUrls.length === 0) return null;
    const deletePromises = imageUrls.map((url) => {
      const objectKey = url.replace(`${secrets.R2_PUBLIC_DEV_URL}/`, "");
      if (objectKey && objectKey !== url) {
        return S3.deleteObject({ Bucket: secrets.R2_BUCKET, Key: objectKey }).promise();
      }
      return null;
    }).filter((p) => p !== null);
    await Promise.allSettled(deletePromises);
    return null;
});

exports.uploadImageToR2 = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Seuls les utilisateurs authentifiés peuvent télécharger des images.");
  // Les données sont maintenant directement dans request.data (car déjà encapsulées par Flutter)
  const { imageData, fileName, prefix } = request.data; 

  if (!imageData || !fileName || !prefix) {
    throw new HttpsError("invalid-argument", "Les données de l'image (imageData), le nom du fichier (fileName) et le préfixe (prefix) sont requis.");
  }
  
  const S3 = await initializeS3Client();
  const secrets = r2SecretsCache;
  const imageBuffer = Buffer.from(imageData, "base64");
  const ts = Date.now();
  const ext = (fileName.includes(".")) ? fileName.split(".").pop() : "jpg";
  const mimeType = mime.lookup(fileName) || "image/jpeg";
  const objectKey = `${prefix}_${request.auth.uid}_${ts}_${Math.random().toString(36).substring(2, 8)}.${ext}`;

  try {
    await S3.putObject({
      Bucket: secrets.R2_BUCKET, Key: objectKey, Body: imageBuffer, ContentType: mimeType,
    }).promise();
    const publicUrl = `${secrets.R2_PUBLIC_DEV_URL}/${objectKey}`;
    return { imageUrl: publicUrl };
  } catch (error) {
    console.error(`[uploadImageToR2] Erreur lors de l'upload de l'image ${objectKey} vers R2:`, error);
    throw new HttpsError("internal", "Échec de l'upload de l'image vers Cloudflare R2.", error.message);
  }
});

exports.deleteR2ImagesByUrls = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Seuls les utilisateurs authentifiés peuvent demander la suppression d'images.");
  // Les données sont maintenant directement dans request.data (car déjà encapsulées par Flutter)
  const { imageUrls } = request.data; 

  if (!imageUrls || !Array.isArray(imageUrls) || imageUrls.length === 0) {
    throw new HttpsError("invalid-argument", "Une liste d'URLs d'images est requise pour la suppression.");
  }
  const S3 = await initializeS3Client();
  const secrets = r2SecretsCache;
  const deletePromises = imageUrls.map((url) => {
    const objectKey = url.replace(`${secrets.R2_PUBLIC_DEV_URL}/`, "");
    if (objectKey && objectKey !== url) {
      return S3.deleteObject({ Bucket: secrets.R2_BUCKET, Key: objectKey }).promise();
    }
    return null;
  }).filter((p) => p !== null);
  const results = await Promise.allSettled(deletePromises);
  const failedDeletions = results.filter((r) => r.status === "rejected");
  if (failedDeletions.length > 0) {
    return { success: false, failedCount: failedDeletions.length };
  } else {
    return { success: true };
  }
});

// =====================================================================================================================
// FONCTIONS DE GESTION DES PAIEMENTS LYGOS (VIA CLOUD FUNCTIONS)
// =====================================================================================================================

exports.lygos_initiatePayment = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Vous devez être authentifié pour initier un paiement.");
  }

  const userId = request.auth.uid;
  // Les données sont maintenant directement dans request.data (car déjà encapsulées par Flutter)
  const { amountFc, message, paymentType, planId, targetId, targetType, boostLevel, boostDurationMinutes, promoCode, storeId } = request.data;

  // Validation des types et de la présence des arguments
  if (typeof amountFc !== 'number' || isNaN(amountFc) || !message || !paymentType) {
    console.error(`[lygos_initiatePayment] Validation failed: amountFc (${amountFc}), message (${message}), paymentType (${paymentType}) sont requis et amountFc doit être un nombre.`);
    throw new HttpsError("invalid-argument", "Les informations de paiement (montant, message, type) sont requises et le montant doit être un nombre.");
  }
  if (paymentType === 'boost' && (typeof boostDurationMinutes !== 'number' || isNaN(boostDurationMinutes))) {
      console.error(`[lygos_initiatePayment] Validation failed: boostDurationMinutes (${boostDurationMinutes}) doit être un nombre valide pour un boost.`);
      throw new HttpsError("invalid-argument", "Pour un boost, la durée doit être un nombre valide.");
  }
  if (targetType === 'product' && !storeId) {
    console.error(`[lygos_initiatePayment] Validation failed: storeId (${storeId}) est requis pour un boost de produit.`);
    throw new HttpsError("invalid-argument", "Pour un boost de produit, le storeId est requis.");
  }

  const lygosSecrets = await getLygosSecrets();
  const orderId = uuidv4();

  const payload = {
    amount: amountFc, // amountFc est déjà un nombre JavaScript
    shop_name: "Tendance",
    message: message,
    order_id: orderId,
  };

  const headers = {
    "api-key": lygosSecrets.LYGOS_API_KEY,
    "Content-Type": "application/json",
  };

  try {
    const res = await axios.post(lygosSecrets.LYGOS_GATEWAY_URL, payload, { headers });

    if (res.status === 200 || res.status === 201) {
      const body = res.data;
      const link = body['link'];
      if (link) {
        await db.collection('profiles').doc(userId).collection('pendingLygosPayments').doc(orderId).set({
          orderId: orderId, paymentType: paymentType, amountFc: amountFc, message: message,
          createdAt: admin.firestore.FieldValue.serverTimestamp(), status: 'PENDING',
          planId: planId || null, promoCode: promoCode || null,
          targetId: targetId || null, targetType: targetType || null, boostLevel: boostLevel || null,
          boostDurationMinutes: boostDurationMinutes || null, storeId: storeId || null,
        });
        return { link: link, orderId: orderId };
      } else {
        throw new HttpsError("internal", "Lygos n'a pas retourné de lien de paiement.");
      }
    } else {
      console.error(`[lygos_initiatePayment] Erreur Lygos ${res.status}: ${JSON.stringify(res.data)}`);
      throw new HttpsError("internal", "Erreur lors de l'initiation du paiement Lygos.");
    }
  } catch (error) {
    console.error(`[lygos_initiatePayment] Erreur: ${error.message}`, error.response ? error.response.data : '');
    throw new HttpsError("internal", `Erreur lors de l'initiation du paiement: ${error.message}`);
  }
});

exports.lygos_checkPaymentStatus = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Vous devez être authentifié pour vérifier le statut d'un paiement.");
  const { orderId } = request.data;
  if (!orderId) throw new HttpsError("invalid-argument", "L'orderId est requis pour vérifier le statut du paiement.");
  const lygosSecrets = await getLygosSecrets();
  const url = `${lygosSecrets.LYGOS_GATEWAY_URL}/payin/${orderId}`;
  const headers = { "api-key": lygosSecrets.LYGOS_API_KEY };
  try {
    const res = await axios.get(url, { headers });
    if (res.status === 200) {
      const data = res.data;
      const status = (data['status'] || 'UNKNOWN').toUpperCase();
      return { status: status };
    } else {
      console.error(`[lygos_checkPaymentStatus] Échec de la vérification du statut Lygos ${res.status}: ${JSON.stringify(res.data)}`);
      throw new HttpsError("internal", "Échec de la vérification du statut du paiement Lygos.");
    }
  } catch (error) {
    console.error(`[lygos_checkPaymentStatus] Erreur: ${error.message}`, error.response ? error.response.data : '');
    throw new HttpsError("internal", `Erreur lors de la vérification du statut: ${error.message}`);
  }
});

exports.lygos_processPaymentResult = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Vous devez être authentifié pour finaliser un paiement.");
  const uid = request.auth.uid;
  const { orderId, success, reason } = request.data;
  if (!orderId || typeof success !== 'boolean') throw new HttpsError("invalid-argument", "L'orderId et le statut de succès sont requis.");

  const pendingPaymentRef = db.collection('profiles').doc(uid).collection('pendingLygosPayments').doc(orderId);
  const pendingPaymentDoc = await pendingPaymentRef.get();
  if (!pendingPaymentDoc.exists) throw new HttpsError("not-found", "Détails du paiement en attente introuvables.");

  const paymentData = pendingPaymentDoc.data();
  const { paymentType, targetId, targetType, boostLevel, boostDurationMinutes, amountFc, promoCode, storeId } = paymentData;
  const writeBatch = db.batch();

  try {
    const resolvedPaymentRef = db.collection('profiles').doc(uid).collection('payments').doc(orderId);
    writeBatch.set(resolvedPaymentRef, {
      ...paymentData, status: success ? 'SUCCESS' : (reason || 'FAILED'), resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    if (!success) {
      const notifRef = db.collection('profiles').doc(uid).collection('notifications').doc();
      writeBatch.set(notifRef, {
        title: paymentType === 'subscription' ? 'Paiement d\'abonnement échoué' : 'Paiement de Boost échoué',
        message: `Le paiement pour votre ${paymentType} a échoué. Raison: ${reason || 'inconnue'}.`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(), read: false,
      });
    } else {
      if (paymentType === 'subscription') {
        const remoteConfigDoc = await db.collection('settings').doc('subscription_config').get();
        const configData = remoteConfigDoc.data() || {};
        const durationMinutes = configData.durationMinutes ?? (30 * 24 * 60);
        const allowedStores = configData.allowedStores ?? -1;
        const nowMillis = Date.now();
        const expiresMillis = nowMillis + (durationMinutes * 60 * 1000);

        const subRef = db.collection('profiles').doc(uid).collection('meta').doc('subscription');
        writeBatch.set(subRef, {
          planId: paymentData.planId || 'single_5000_month', expiresAtMillis: expiresMillis, trialUsed: false,
          allowedStores: allowedStores, promoCode: paymentData.promoCode || null, startAtMillis: nowMillis,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        const notifRef = db.collection('profiles').doc(uid).collection('notifications').doc();
        writeBatch.set(notifRef, {
          title: 'Abonnement activé !',
          message: `Votre abonnement est actif jusqu'au ${new Date(expiresMillis).toLocaleString('fr-FR')}.`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(), read: false,
        });
      } else if (paymentType === 'boost') {
        // Validation des données nécessaires pour le boost
        if (!targetId || !targetType || !boostLevel || typeof boostDurationMinutes !== 'number' || isNaN(boostDurationMinutes) || typeof amountFc !== 'number' || isNaN(amountFc)) {
          console.error(`[lygos_processPaymentResult] Données de boost manquantes ou incomplètes pour orderId: ${orderId}. boostDurationMinutes: ${boostDurationMinutes}, amountFc: ${amountFc}`);
          throw new HttpsError("internal", "Données de boost incomplètes.");
        }
        
        const now = admin.firestore.FieldValue.serverTimestamp();
        const nowMillis = Date.now();
        const boostExpiresAtMillis = nowMillis + (boostDurationMinutes * 60 * 1000);

        let mainTargetDocRef;
        if (targetType === 'product') {
          if (!storeId) throw new HttpsError("internal", "storeId manquant pour le boost de produit.");
          mainTargetDocRef = db.collection('profiles').doc(uid).collection('stores').doc(storeId).collection('products').doc(targetId);
        } else if (targetType === 'store') {
          mainTargetDocRef = db.collection('profiles').doc(uid).collection('stores').doc(targetId);
        } else {
          throw new HttpsError("internal", "Type de cible de boostage non valide.");
        }

        const mainDocPayload = {
          boostLevel: boostLevel, boostExpiresAt: admin.firestore.Timestamp.fromMillis(boostExpiresAtMillis),
          boostActivatedAt: now, boostedBy: uid, amountFc: amountFc, promoCode: promoCode || null,
          targetType: targetType, targetId: targetId, lastUpdatedAt: now, isBoosted: true,
        };
        writeBatch.set(mainTargetDocRef, mainDocPayload, { merge: true });

        const boostHistoryRef = mainTargetDocRef.collection('boosts').doc();
        writeBatch.set(boostHistoryRef, {
          boostLevel: boostLevel, expiresAtMillis: boostExpiresAtMillis, activatedAt: now,
          paymentOrderId: orderId, amountFc: amountFc, promoCode: promoCode || null, status: 'ACTIVE',
        });

        const notifRef = db.collection('profiles').doc(uid).collection('notifications').doc();
        writeBatch.set(notifRef, {
          title: 'Boost activé !',
          message: `Votre ${targetType} "${targetId}" est maintenant boosté pour ${boostDurationMinutes / (24 * 60)} jours !`,
          createdAt: now, read: false,
        });
      }
    }
    writeBatch.delete(pendingPaymentRef);
    await writeBatch.commit();
    return { status: success ? 'COMPLETED' : 'FAILED' };
  } catch (error) {
    console.error(`[lygos_processPaymentResult] Erreur lors de la finalisation du paiement pour orderId ${orderId}: ${error.message}`, error);
    await db.collection('profiles').doc(uid).collection('payments').doc(orderId).set({
      ...paymentData, status: 'ACTIVATION_FAILED', error: error.message, resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await db.collection('profiles').doc(uid).collection('notifications').add({
      title: 'Erreur d\'activation après paiement',
      message: `Votre paiement a été reçu, mais l'activation du ${paymentType} a échoué. Contactez le support.`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(), read: false,
    });
    throw new HttpsError("internal", `Erreur lors de la finalisation du paiement: ${error.message}`);
  }
});

// =====================================================================================================================
// FONCTION PLANIFIÉE UNIFIÉE
// =====================================================================================================================

/**
 * Fonction planifiée UNIFIÉE qui s'exécute périodiquement pour :
 * 1. Envoyer des notifications sur l'état des abonnements (seuils, expiration).
 * 2. Vérifier et désactiver les boosts (produits/boutiques) expirés.
 *
 * Exécution recommandée : toutes les 1 à 6 heures.
 * "every 1 hours" est un bon compromis.
 */
exports.checkExpirationsAndNotify = onSchedule("every 20 hours", async (event) => {
  console.log(`[Monitor] Démarrage de la vérification des abonnements et boosts.`);
  const now = Date.now();
  const db = admin.firestore();

  // On récupère tous les profils utilisateurs
  const usersSnapshot = await db.collection('profiles').get();
  if (usersSnapshot.empty) {
    console.log("[Monitor] Aucun utilisateur trouvé. Fin de la tâche.");
    return null;
  }

  // Boucle sur chaque utilisateur pour une gestion centralisée
  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    const batch = db.batch(); // Un batch par utilisateur pour regrouper les écritures

    // --- TÂCHE 1 : Vérification de l'abonnement de l'utilisateur ---
    await checkUserSubscription(userId, now, db, batch);

    // --- TÂCHE 2 : Vérification des boosts de l'utilisateur ---
    await checkUserBoosts(userId, now, db, batch);

    // Commit toutes les modifications pour cet utilisateur
    await batch.commit().catch(e => console.error(`[Monitor] Erreur lors du commit du batch pour l'utilisateur ${userId}:`, e));
  }

  console.log("[Monitor] Vérification des abonnements et boosts terminée.");
  return null;
});


/**
 * Helper pour vérifier l'abonnement d'un utilisateur.
 */
async function checkUserSubscription(userId, now, db, batch) {
  const subRef = db.collection('profiles').doc(userId).collection('meta').doc('subscription');
  const subDoc = await subRef.get();

  if (!subDoc.exists) return;

  const sub = subDoc.data();
  if (!sub.expiresAtMillis || !sub.startAtMillis) return;

  const { expiresAtMillis, startAtMillis } = sub;
  const notifiedThresholds = sub.notifiedThresholds || [];

  // A. Abonnement expiré
  if (expiresAtMillis < now) {
    if (!notifiedThresholds.includes('expired')) {
      createNotification(userId, 'Abonnement expiré', 'Votre abonnement a expiré. Veuillez le renouveler pour continuer à profiter de tous nos services.', 'expired', db, batch);
      batch.update(subRef, { notifiedThresholds: admin.firestore.FieldValue.arrayUnion('expired') });
    }
    return; // Pas besoin de vérifier d'autres seuils
  }

  // B. Notifications de seuil avant expiration
  const totalDuration = expiresAtMillis - startAtMillis;
  if (totalDuration <= 0) return;

  const remainingMillis = expiresAtMillis - now;
  const usedPct = (1 - (remainingMillis / totalDuration)) * 100;
  
  // Seuil de 90%
  if (usedPct >= 90 && !notifiedThresholds.includes('90')) {
      createNotification(userId, 'Votre abonnement expire bientôt', 'Plus de 90% de votre abonnement a été utilisé. Pensez à renouveler !', 'sub_90', db, batch);
      batch.update(subRef, { notifiedThresholds: admin.firestore.FieldValue.arrayUnion('90') });
  } 
  // Seuil de 50%
  else if (usedPct >= 50 && !notifiedThresholds.includes('50')) {
      createNotification(userId, 'Abonnement à mi-parcours', 'Vous avez utilisé 50% de la durée de votre abonnement.', 'sub_50', db, batch);
      batch.update(subRef, { notifiedThresholds: admin.firestore.FieldValue.arrayUnion('50') });
  }
}


/**
 * Helper pour vérifier les boosts d'un utilisateur et les désactiver si besoin.
 */
async function checkUserBoosts(userId, now, db, batch) {
    const nowTimestamp = admin.firestore.Timestamp.fromMillis(now);

    // On cherche les produits de cet utilisateur qui sont boostés ET dont la date d'expiration est passée
    const boostedProductsRef = db.collectionGroup('products')
                                 .where('boostedBy', '==', userId)
                                 .where('isBoosted', '==', true)
                                 .where('boostExpiresAt', '<', nowTimestamp);
                                 
    const productsSnapshot = await boostedProductsRef.get();

    if (!productsSnapshot.empty) {
        console.log(`[Monitor] ${productsSnapshot.docs.length} produit(s) expiré(s) trouvé(s) pour l'utilisateur ${userId}.`);
        productsSnapshot.docs.forEach(doc => {
            const productRef = doc.ref;
            batch.update(productRef, {
                isBoosted: false,
                boostLevel: null,
                boostExpiresAt: null,
                // On garde les autres infos de boost pour l'historique si besoin
            });
            // Créer une notification pour l'utilisateur
            createNotification(userId, 'Boost Terminé', `Le boost pour votre produit "${doc.data().name || 'sans nom'}" est maintenant terminé.`, `boost_expired_${doc.id}`, db, batch);
        });
    }
    
    // Vous pouvez ajouter une logique similaire pour les boutiques ('stores') ici si nécessaire
}


/**
 * Helper unifié pour ajouter une notification à un batch.
 */
function createNotification(userId, title, message, key, db, batch) {
    const notifRef = db.collection('profiles').doc(userId).collection('notifications').doc();
    batch.set(notifRef, {
        title: title,
        message: message,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        key: key, // Clé unique pour identifier le type de notif
    });
}



exports.sendPushNotification = onDocumentCreated("profiles/{userId}/notifications/{notificationId}", async (event) => {
  const { userId, notificationId } = event.params;
  const notificationData = event.data.data();
  const { title, message } = notificationData;
  if (!title || !message) return null;
  try {
    const userProfile = await db.collection('profiles').doc(userId).get();
    const fcmToken = userProfile.data()?.fcmToken;
    if (!fcmToken) return null;
    const fcmMessage = {
      token: fcmToken, notification: { title: title, body: message, },
      data: { click_action: "FLUTTER_NOTIFICATION_CLICK", userId: userId, notificationId: notificationId, },
    };
    await messaging.send(fcmMessage);
    await db.collection('profiles').doc(userId).collection('notifications').doc(notificationId).update({
      sentPush: true, sentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(`[sendPushNotification] Erreur lors de l'envoi de la notification push pour ${userId}, notification ${notificationId}:`, error);
  }
  return null;
});


exports.sendChatMessageNotification = onDocumentWritten(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const { chatId, messageId } = event.params;

    if (!after) return null;

    const prevStatus = before ? before.status : null;
    const newStatus = after.status;

    if (after.cfProcessed === true || after.deliveredAt) return null;

    if (prevStatus === "sent" || newStatus !== "sent") return null;

    const senderId = after.senderId;
    const receiverId = after.receiverId;
    const messageBody = after.message || "";

    try {
      const receiverProfile = await db.collection("profiles").doc(receiverId).get();
      const fcmToken = receiverProfile.data()?.fcmToken;

      if (!fcmToken) {
        await event.data.after.ref.set(
          {
            status: "delivered",
            deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
            cfProcessed: true,
          },
          { merge: true }
        );
        return null;
      }

      const senderSnap = await db.collection("profiles").doc(senderId).get();
      const senderData = senderSnap.data() || {};
      const senderName = senderData.username || "Quelqu'un";
      const senderPhoto = senderData.photoUrl || "";

      const payload = {
        token: fcmToken,
        notification: {
          title: senderName,
          body:
            messageBody.length > 100
              ? messageBody.substring(0, 97) + "..."
              : messageBody,
        },
        data: {
          type: "chat_message",
          chatId,
          messageId,
          senderId,
          senderName,
          senderPhotoUrl: senderPhoto,
        },
        android: { priority: "high" },
        apns: { payload: { aps: { "content-available": 1 } } },
      };

      await messaging.send(payload);

      await event.data.after.ref.set(
        {
          status: "delivered",
          deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
          cfProcessed: true,
        },
        { merge: true }
      );
    } catch (err) {
      try {
        await event.data.after.ref.set(
          {
            status: "delivered",
            deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
            cfProcessed: true,
          },
          { merge: true }
        );
      } catch {}
    }

    return null;
  }
);
