import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Inicializace Flutteru předtím, než spustíme službu
  WidgetsFlutterBinding.ensureInitialized();
  await inicializovatPozadi();
  runApp(const MujKrokomerApp());
}

// ==========================================
// LOGIKA PRO BĚH NA POZADÍ A NOTIFIKACE
// ==========================================
Future<void> inicializovatPozadi() async {
  final service = FlutterBackgroundService();

  // Nastavení kanálu pro notifikace (nutné pro Android)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'krokomer_kanal', // id kanálu
    'Krokoměr na pozadí', // jméno
    description: 'Udržuje krokoměr aktivní',
    importance:
        Importance.low, // Nízká důležitost = nebude to při každém kroku pípat
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStartPozadi, // Funkce, co se spustí na pozadí
      autoStart: false, // Necháme službu zapnout až ručně tlačítkem
      isForegroundMode: true,
      notificationChannelId: 'krokomer_kanal',
      initialNotificationTitle: 'Krokoměr běží',
      initialNotificationContent: 'Načítám kroky...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStartPozadi,
    ),
  );
}

// TOTO BĚŽÍ ZCELA NEZÁVISLE NA ZAVŘENÉ APLIKACI
@pragma('vm:entry-point')
void onStartPozadi(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Zkusíme se napojit na senzor přímo v pozadí
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

      // Aktualizujeme notifikaci novým číslem!
      // Aktualizujeme notifikaci novým číslem!
      flutterLocalNotificationsPlugin.show(
        id: 888,
        title: 'Dnešní kroky',
        body: '$dnesniKroky kroků', // Text v notifikační liště
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'krokomer_kanal',
            'Krokoměr na pozadí',
            icon: '@mipmap/ic_launcher', // Výchozí ikona
            ongoing: true,
          ),
        ),
      );

      // Pošleme data do hlavní aplikace (kdyby byla náhodou otevřená)
      service.invoke('update', {'kroky': dnesniKroky});
    });
  } catch (e) {
    print("Chyba senzoru na pozadí: $e");
  }
}

// ==========================================
// UŽIVATELSKÉ ROZHRANÍ (APLIKACE)
// ==========================================
class MujKrokomerApp extends StatelessWidget {
  const MujKrokomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biohack Krokoměr',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const KrokomerObrazovka(),
    );
  }
}

class KrokomerObrazovka extends StatefulWidget {
  const KrokomerObrazovka({super.key});

  @override
  State<KrokomerObrazovka> createState() => _KrokomerObrazovkaState();
}

class _KrokomerObrazovkaState extends State<KrokomerObrazovka> {
  String _dnesniKrokyZobrazeni = 'Stiskni Start';
  bool _jeSluzbaAktivni = false;

  @override
  void initState() {
    super.initState();
    zkontrolovatPrava();

    // Nasloucháme zprávám ze služby na pozadí
    FlutterBackgroundService().on('update').listen((event) {
      if (event != null && mounted) {
        setState(() {
          _dnesniKrokyZobrazeni = event['kroky'].toString();
        });
      }
    });
  }

  Future<void> zkontrolovatPrava() async {
    // Android 13+ vyžaduje práva na notifikace
    await Permission.notification.request();
    await Permission.activityRecognition.request();
  }

  void prepnoutSluzbu() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();

    if (isRunning) {
      service.invoke("stopService");
      setState(() => _jeSluzbaAktivni = false);
    } else {
      service.startService();
      setState(() => _jeSluzbaAktivni = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Můj Krokoměr'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dnešní kroky:', style: TextStyle(fontSize: 24)),
            Text(
              _dnesniKrokyZobrazeni,
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: prepnoutSluzbu,
              style: ElevatedButton.styleFrom(
                backgroundColor: _jeSluzbaAktivni ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: Text(
                _jeSluzbaAktivni ? 'Zastavit krokoměr' : 'Spustit krokoměr',
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
