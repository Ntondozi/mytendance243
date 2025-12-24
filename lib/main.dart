// file: main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tendance/controlers/storeControlers.dart';

import 'firebase_options.dart';
import 'package:tendance/services/notification_service.dart';
import 'package:tendance/splash_loader.dart';

// GetX controllers
import 'package:tendance/controlers/authControler.dart';
import 'package:tendance/controlers/messageController.dart';
import 'package:tendance/controlers/boostController.dart';
import 'package:tendance/controlers/cartController.dart';
import 'package:tendance/controlers/navControler.dart';
import 'package:tendance/controlers/productControler.dart';
import 'package:tendance/controlers/subscription_controller.dart';

// Pages
import 'package:tendance/views/pagesOut/loginOutPage.dart';
import 'package:tendance/views/pagesOut/signupOutPage.dart';
import 'package:tendance/landingPage/landingPage.dart';

import 'services/notificationChat_service.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'views/pagesIn/homeIn.dart';


// Handler FCM background (Android/iOS)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await NotificationService.initialize();
    NotificationService.showNotification(message);

    // Affichez la notification personnalisée
    await NotificationChatService().initialize();
    await NotificationChatService().showChatNotification(message);

  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialisation unique de Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if(kIsWeb){
    await initializeDateFormatting('fr_FR', null);  
    
  }
  // 🔥 Notifications pour mobile
  if (!kIsWeb) {
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.initialize();
    await NotificationChatService().initialize();
  }

  // 🔥 Injection GetX globale
  Get.put(AuthController(), permanent: true);
  Get.put(CartController(), permanent: true);
  Get.put(NavigationInController(), permanent: true);
  Get.put(SubscriptionController(), permanent: true);
  Get.put(ProductController(), permanent: true);
  Get.put(BoostController(), permanent: true);
  Get.put(MessageController(), permanent: true);
  Get.put(StoreController());

  setUrlStrategy(PathUrlStrategy());

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        fontFamily: "NotoSans",
        textTheme: GoogleFonts.latoTextTheme().copyWith(
          bodyMedium: GoogleFonts.oswald(),
        ),
      ),

      // ✅ WEB → pas de splash
      // ✅ MOBILE → splash
      initialRoute: kIsWeb ? '/' : '/splash',

      getPages: [
        // ✅ Pages publiques SEO
        GetPage(name: '/', page: () => LandingPageTendance()),
        GetPage(name: '/login', page: () => Loginoutpage()),
        GetPage(name: '/signup', page: () => Signupoutpage()),

        // ✅ Splash uniquement pour mobile
        GetPage(name: '/splash', page: () => SplashLoader()),

        // ✅ Home utilisateur connecté
        GetPage(name: '/home', page: () => homeIn()),
      ],

      debugShowCheckedModeBanner: false,
    );
  }
}


