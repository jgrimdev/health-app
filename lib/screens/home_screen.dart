import 'package:flutter/material.dart';
import '../services/database_service.dart'; // 👈 Import databáze pro Streak

class DomuObrazovka extends StatefulWidget {
  final int kroky;
  final double vyska;
  final int cil;

  const DomuObrazovka({super.key, required this.kroky, required this.vyska, required this.cil});

  @override
  State<DomuObrazovka> createState() => _DomuObrazovkaState();
}

class _DomuObrazovkaState extends State<DomuObrazovka> {
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _nactiStreak();
  }

  // Funkce, která spočítá, kolik dní v kuse jsi splnil cíl
  Future<void> _nactiStreak() async {
    int streak = await DatabaseService.instance.spocitejStreak(widget.cil);
    if (mounted) {
      setState(() => _streak = streak);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Matematika (bere data přes "widget.", protože jsme teď ve StatefulWidgetu)
    double delkaKrokuMetry = (widget.vyska * 0.414) / 100;
    double vzdalenostKm = (widget.kroky * delkaKrokuMetry) / 1000;
    double progres = widget.kroky / widget.cil;
    if (progres > 1.0) progres = 1.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔥 PLAMÍNEK STREAKU (Ukáže se jen, pokud je větší než 0) 🔥
          if (_streak > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orangeAccent),
              ),
              child: Text(
                '🔥 $_streak dní v řadě!', 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)
              ),
            ),
          
          // Hlavní kruhový graf
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250, height: 250,
                child: CircularProgressIndicator(
                  value: progres,
                  strokeWidth: 15,
                  backgroundColor: Colors.white10,
                  color: progres >= 1.0 ? Colors.blue : Colors.greenAccent,
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.directions_walk, size: 40, color: Colors.greenAccent),
                  Text('${widget.kroky}', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
                  Text('/ ${widget.cil}', style: const TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 50),
          
          // Karty statistik pod grafem
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Vzdálenost', '${vzdalenostKm.toStringAsFixed(2)} km', Icons.map),
              _buildStatCard('Spáleno', '${(widget.kroky * 0.04).toStringAsFixed(0)} kcal', Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  // Pomocný widget pro spodní karty
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 30),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}