// Import des bibliothèques Firebase compat
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Configuration Firebase
firebase.initializeApp({
  apiKey: "AIzaSyBHld7nKnauHWA4vsANMIrwxrOkyomW-XI",
  authDomain: "tendance-52721.firebaseapp.com",
  projectId: "tendance-52721",
  storageBucket: "tendance-52721.firebasestorage.app",
  messagingSenderId: "276268441943",
  appId: "1:276268441943:web:67e590aac14be87739de12"
});

// Instance Messaging
const messaging = firebase.messaging();

// Notifications en arrière-plan
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/favicon.png'
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Gestion du clic sur notification
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(clients.openWindow('/')); // ouvre la page d’accueil
});

// ⚡ Forcer le SW à prendre le contrôle immédiatement
self.addEventListener('install', (event) => {
  self.skipWaiting(); // active le SW immédiatement
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim()); // prend le contrôle de toutes les pages ouvertes
});
