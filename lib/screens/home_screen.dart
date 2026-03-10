import 'package:flutter/material.dart';

class DomuObrazovka extends StatelessWidget {
  final int kroky;
  final double vyska;
  final int cil;

  const DomuObrazovka({super.key, required this.kroky, required this.vyska, required this.cil});

  @override
  Widget build(BuildContext context) {
    double delkaKrokuMetry = (vyska * 0.414) / 100;
    double vzdalenostKm = (kroky * delkaKrokuMetry) / 1000;
    double progres = kroky / cil;
    if (progres > 1.0) progres = 1.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                  Text('$kroky', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
                  Text('/ $cil', style: const TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Vzdálenost', '${vzdalenostKm.toStringAsFixed(2)} km', Icons.map),
              _buildStatCard('Spáleno', '${(kroky * 0.04).toStringAsFixed(0)} kcal', Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

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