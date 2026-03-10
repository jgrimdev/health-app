import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> inicializovatPozadi() async {
  final service = FlutterBackgroundService();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'krokomer_kanal',
    'Krokoměr na pozadí',
    description: 'Udržuje krokoměr aktivní',
    importance: Importance.low,
  );
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStartPozadi,
      autoStart: false, 
      isForegroundMode: true,
      notificationChannelId: 'krokomer_kanal',
      initialNotificationTitle: 'Krokoměr připraven',
      initialNotificationContent: 'Čekám na první krok...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false, onForeground: onStartPozadi),
  );
}

@pragma('vm:entry-point')
void onStartPozadi(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

// 🔥 TOTO TU CHYBĚLO: Nastartování Firebase na pozadí!
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  try {
    Pedometer.stepCountStream.listen((StepCount event) async {
      int celkoveKroky = event.steps;
      final prefs = await SharedPreferences.getInstance();
      
      String dnesniDatum = DateTime.now().toString().substring(0, 10);
      String? ulozeneDatum = prefs.getString('posledni_datum');
      
      if (ulozeneDatum != dnesniDatum) {
        await prefs.setInt('startovaci_kroky', celkoveKroky);
        await prefs.setString('posledni_datum', dnesniDatum);
      }
      
      int startovaciKroky = prefs.getInt('startovaci_kroky') ?? celkoveKroky;
      int dnesniKroky = celkoveKroky - startovaciKroky;

// TOTO JE NOVÉ ULOŽENÍ DO SQLITE DATABÁZE:
      await DatabaseService.instance.ulozKroky(dnesniDatum, dnesniKroky);
      // NOVÉ: Tichá záloha do cloudu (provede se jen, když je uživatel přihlášený)
      await FirebaseService.zalohovatKroky(dnesniDatum, dnesniKroky);
      
      double vyska = prefs.getDouble('vyska') ?? 171.0;
      int cil = prefs.getInt('cil') ?? 10000;
      double delkaKrokuMetry = (vyska * 0.414) / 100;
      double vzdalenostKm = (dnesniKroky * delkaKrokuMetry) / 1000;

      flutterLocalNotificationsPlugin.show(
        id: 888,
        title: '👣 $dnesniKroky kroků',
        body: 'Vzdálenost: ${vzdalenostKm.toStringAsFixed(2)} km  |  Cíl: $cil',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'krokomer_kanal',
            'Krokoměr na pozadí',
            icon: '@mipmap/ic_launcher', 
            ongoing: true,
            showWhen: false,
            onlyAlertOnce: true,
          ),
        ),
      );

      service.invoke('update', {'kroky': dnesniKroky});
    });
  } catch (e) {
    print("Chyba senzoru na pozadí: $e");
  }
}