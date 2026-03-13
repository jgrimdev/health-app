import 'package:flutter/material.dart';
import '../services/database_service.dart';

class UspechyObrazovka extends StatefulWidget {
  final int cil;
  const UspechyObrazovka({super.key, required this.cil});

  @override
  State<UspechyObrazovka> createState() => _UspechyObrazovkaState();
}

class _UspechyObrazovkaState extends State<UspechyObrazovka> {
  int _streak = 0;
  int _celkoveKroky = 0;
  bool _nacteno = false;

  @override
  void initState() {
    super.initState();
    _nactiData();
  }

  Future<void> _nactiData() async {
    int s = await DatabaseService.instance.spocitejStreak(widget.cil);
    int c = await DatabaseService.instance.spocitejCelkoveKroky();
    if (mounted) {
      setState(() {
        _streak = s;
        _celkoveKroky = c;
        _nacteno = true;
      });
    }
  }

  // Šablona pro jeden odznak
  Widget _buildOdznak(String nazev, String popis, String emoji, bool splneno) {
    return Container(
      decoration: BoxDecoration(
        color: splneno ? Colors.white10 : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: splneno ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white12, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: TextStyle(fontSize: 40, color: splneno ? Colors.white : Colors.grey.withValues(alpha: 0.2))),
          const SizedBox(height: 10),
          Text(nazev, style: TextStyle(fontWeight: FontWeight.bold, color: splneno ? Colors.white : Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(popis, style: TextStyle(fontSize: 10, color: splneno ? Colors.greenAccent : Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_nacteno) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tvoje Úspěchy', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Celkově jsi ušel $_celkoveKroky kroků!', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildOdznak('První krok', 'Ujdi 1000 kroků', '👶', _celkoveKroky >= 1000),
                _buildOdznak('Výletník', 'Ujdi 10 000 kroků', '🎒', _celkoveKroky >= 10000),
                _buildOdznak('Maratonec', 'Ujdi 42 000 kroků', '🏃', _celkoveKroky >= 42000),
                _buildOdznak('Cíl splněn!', 'Splň 1x denní cíl', '🎯', _streak >= 1),
                _buildOdznak('V plamenech', 'Splň cíl 3 dny v řadě', '🔥', _streak >= 3),
                _buildOdznak('Nezastavitelný', 'Splň cíl 7 dní v řadě', '🌋', _streak >= 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}