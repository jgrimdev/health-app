import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart'; 
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'database_service.dart';
import 'firebase_service.dart';

Future<void> inicializovatPozadi() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'tichy_krokomer_v1', 
    'Služba Krokoměru',
    description: 'Běží tiše na pozadí bez vibrací.',
    importance: Importance.low, // Nízká priorita zaručuje, že to nevibruje a necinká
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStartPozadi,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'tichy_krokomer_v1', 
      // ✨ Výchozí texty, než se načtou data z databáze ✨
      initialNotificationTitle: '👣 Načítám kroky...',
      initialNotificationContent: 'Počítám vzdálenost...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStartPozadi,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStartPozadi(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) => service.setAsForegroundService());
    service.on('setAsBackground').listen((event) => service.setAsBackgroundService());

    // Rychlý start notifikace z uložených dat
    String dnesniDatum = DateTime.now().toString().substring(0, 10);
    int startovniKroky = await DatabaseService.instance.nactiKrokyProDatum(dnesniDatum);
    double vyska = prefs.getDouble('vyska') ?? 171.0;
    double vzdalenostKm = (startovniKroky * ((vyska * 0.414) / 100)) / 1000;
    
    service.setForegroundNotificationInfo(
      title: '👣 $startovniKroky kroků', 
      content: 'Vzdálenost: ${vzdalenostKm.toStringAsFixed(2)} km'
    );
  }

  service.on('stopService').listen((event) => service.stopSelf());

  int posledniZapsaneKroky = 0;
  int posledniZapsanyFirebase = 0;

  Pedometer.stepCountStream.listen((StepCount event) async {
    int aktualniKrokySenzoru = event.steps;
    String dnesniDatum = DateTime.now().toString().substring(0, 10);

    int posledniHodnotaSenzoru = prefs.getInt('posledni_senzor') ?? aktualniKrokySenzoru;
    int dnesniUlozeneKroky = await DatabaseService.instance.nactiKrokyProDatum(dnesniDatum);

    int pridaneKroky = (aktualniKrokySenzoru >= posledniHodnotaSenzoru) 
        ? aktualniKrokySenzoru - posledniHodnotaSenzoru 
        : aktualniKrokySenzoru;

    int novyCelkem = dnesniUlozeneKroky + pridaneKroky;

    // Plynulý update do UI (nežere baterku)
    service.invoke('update', {'kroky': novyCelkem});

    // Update databáze a notifikace každých 15 kroků
    if ((novyCelkem - posledniZapsaneKroky).abs() >= 15 || posledniZapsaneKroky == 0) {
      await DatabaseService.instance.ulozKroky(dnesniDatum, novyCelkem);
      await prefs.setInt('posledni_senzor', aktualniKrokySenzoru);
      
      // ✨ KRÁSNÁ NOTIFIKACE S IKONKOU A VZDÁLENOSTÍ ✨
      if (service is AndroidServiceInstance) {
        double vyska = prefs.getDouble('vyska') ?? 171.0;
        double vzdalenostKm = (novyCelkem * ((vyska * 0.414) / 100)) / 1000;

        service.setForegroundNotificationInfo(
          title: '👣 $novyCelkem kroků',
          content: 'Vzdálenost: ${vzdalenostKm.toStringAsFixed(2)} km',
        );
      }
      posledniZapsaneKroky = novyCelkem;
    }

    // Odeslání do Firebase každých 200 kroků
    if ((novyCelkem - posledniZapsanyFirebase).abs() >= 200 || posledniZapsanyFirebase == 0) {
      await FirebaseService.zalohovatKroky(dnesniDatum, novyCelkem);
      posledniZapsanyFirebase = novyCelkem;
    }

  }).onError((error) {
    debugPrint("Chyba senzoru na pozadí: $error");
  });
}