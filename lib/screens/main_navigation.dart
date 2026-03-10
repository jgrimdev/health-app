import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

// Tady natahujeme ty naše nové rozsekané soubory!
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HlavniNavigace extends StatefulWidget {
  const HlavniNavigace({super.key});

  @override
  State<HlavniNavigace> createState() => _HlavniNavigaceState();
}

class _HlavniNavigaceState extends State<HlavniNavigace> {
  int _aktualniZalozka = 0;
  int _dnesniKroky = 0;
  double _vyska = 171.0;
  int _cil = 10000;

  @override
  void initState() {
    super.initState();
    _nactiNastaveni();
    _spustitSenzor();
    
    FlutterBackgroundService().on('update').listen((event) {
      if (event != null && mounted) {
        setState(() => _dnesniKroky = event['kroky'] as int);
      }
    });
  }

  Future<void> _nactiNastaveni() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _vyska = prefs.getDouble('vyska') ?? 171.0;
      _cil = prefs.getInt('cil') ?? 10000;
      String dnesniDatum = DateTime.now().toString().substring(0, 10);
      _dnesniKroky = prefs.getInt('history_$dnesniDatum') ?? 0;
    });
  }

  Future<void> _ulozNastaveni(double novaVyska, int novyCil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('vyska', novaVyska);
    await prefs.setInt('cil', novyCil);
    setState(() {
      _vyska = novaVyska;
      _cil = novyCil;
    });
  }

  Future<void> _spustitSenzor() async {
    await Permission.activityRecognition.request();
    await Permission.notification.request();
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) await service.startService();
  }

  @override
  Widget build(BuildContext context) {
    // Tady posíláme data do jednotlivých obrazovek
    final List<Widget> obrazovky = [
      DomuObrazovka(kroky: _dnesniKroky, vyska: _vyska, cil: _cil),
      HistorieObrazovka(cil: _cil),
      NastaveniObrazovka(
        vyska: _vyska,
        cil: _cil,
        onZmena: (v, c) => _ulozNastaveni(v, c),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Můj Krokoměr', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(child: obrazovky[_aktualniZalozka]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _aktualniZalozka,
        onTap: (index) => setState(() => _aktualniZalozka = index),
        selectedItemColor: Colors.greenAccent,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Domů'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Historie'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Nastavení'),
        ],
      ),
    );
  }
}