// Importez les bibliothèques Firebase nécessaires (version compat pour les Service Workers)
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Votre configuration Firebase pour l'application Web
// C'est l'objet que vous avez copié de la console Firebase
const firebaseConfig = {
  apiKey: "AIzaSyBHld7nKnauHWA4vsANMIrwxrOkyomW-XI",
  authDomain: "tendance-52721.firebaseapp.com",
  projectId: "tendance-527tendanceofficiel21",
  storageBucket: "tendance-52721.firebasestorage.app",
  messagingSenderId: "276268441943",
  appId: "1:276268441943:web:67e590aac14be87739de12",
  measurementId: "G-QB7BS4P6EE" // measurementId est optionnel mais peut être inclus
};

// Initialisez Firebase avec votre configuration
const app = firebase.initializeApp(firebaseConfig);

// Obtenez l'instance de Messaging
const messaging = firebase.messaging();

// Gérez les messages en arrière-plan (quand l'application n'est pas ouverte)
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  // Personnalisez la notification ici
  const notificationTitle = payload.notification.title || 'Notification en arrière-plan';
  const notificationOptions = {
    body: payload.notification.body || 'Ceci est une notification reçue en arrière-plan.',
    icon: '/favicon.png' // Assurez-vous d'avoir une icône accessible à la racine de votre site
                        // ou un chemin valide pour votre icône de notification.
                        // /favicon.png est un exemple courant.
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Optionnel: Gérer les événements de clic sur la notification (si vous en avez besoin)
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  // event.waitUntil(clients.openWindow('https://example.com/notification-target'));
  // Vous pouvez ouvrir une URL spécifique ou gérer une action ici
}); 