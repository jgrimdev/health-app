import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';

class HistorieObrazovka extends StatefulWidget {
  final int cil;
  const HistorieObrazovka({super.key, required this.cil});

  @override
  State<HistorieObrazovka> createState() => _HistorieObrazovkaState();
}

class _HistorieObrazovkaState extends State<HistorieObrazovka> {
  String _vybranyPohled = 'tyden'; // 'tyden' nebo 'mesic'
  
  // Oddělené paměti pro swajpování, ať se to nemíchá
  final Map<int, List<int>> _nacteneTydny = {};
  final Map<int, List<int>> _nacteneMesice = {};

  Future<void> _nactiData(int index) async {
    bool jeTyden = _vybranyPohled == 'tyden';
    int pocetDni = jeTyden ? 7 : 30; // Buď 7 dní nebo 30 dní zpět
    
    if (jeTyden && _nacteneTydny.containsKey(index)) return;
    if (!jeTyden && _nacteneMesice.containsKey(index)) return;

    List<int> data = [];
    int posun = index * pocetDni;
    
    for (int i = pocetDni - 1; i >= 0; i--) {
      DateTime den = DateTime.now().subtract(Duration(days: i + posun));
      String datumStr = den.toString().substring(0, 10);
      data.add(await DatabaseService.instance.nactiKrokyProDatum(datumStr));
    }

    setState(() {
      if (jeTyden) {
        _nacteneTydny[index] = data;
      } else {
        _nacteneMesice[index] = data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool jeTyden = _vybranyPohled == 'tyden';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ELEGANTNÍ PŘEPÍNAČ TÝDEN / MĚSÍC
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tyden', label: Text('Týden')),
              ButtonSegment(value: 'mesic', label: Text('Měsíc')),
            ],
            selected: {_vybranyPohled},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _vybranyPohled = newSelection.first;
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white10,
              selectedForegroundColor: Colors.white,
selectedBackgroundColor: Colors.greenAccent.withValues(alpha: 0.3),            ),
          ),
          const SizedBox(height: 30),
          
          Expanded(
            // Důležité: 'key' zajistí, že když přepneš na Měsíc, PageView se resetuje na stranu 0
            key: ValueKey(_vybranyPohled), 
            child: PageView.builder(
              reverse: true,
              onPageChanged: _nactiData,
              itemBuilder: (context, index) {
                if ((jeTyden && !_nacteneTydny.containsKey(index)) || 
                    (!jeTyden && !_nacteneMesice.containsKey(index))) {
                  _nactiData(index);
                  return const Center(child: CircularProgressIndicator());
                }

                List<int> data = jeTyden ? _nacteneTydny[index]! : _nacteneMesice[index]!;
                
                // Krásný čistý nadpis grafu (např. "Před 1 měsícem")
                String nadpisZobrazeni = index == 0 
                  ? (jeTyden ? 'Tento týden' : 'Posledních 30 dní') 
                  : 'Před $index ${jeTyden ? (index == 1 ? 'týdnem' : 'týdny') : (index == 1 ? 'měsícem' : 'měsíci')}';

                return Column(
                  children: [
                    Text(nadpisZobrazeni, style: const TextStyle(fontSize: 18, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 30),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (widget.cil * 1.5).toDouble(),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                // Schováme popisky u měsíce, aby to nebylo přeplácané
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  DateTime den = DateTime.now().subtract(Duration(days: (index * (jeTyden ? 7 : 30)) + (jeTyden ? 6 : 29) - value.toInt()));
                                  if (jeTyden) {
                                    const dny = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
                                    return Text(dny[den.weekday - 1], style: const TextStyle(fontSize: 12));
                                  } else {
                                    // U měsíce ukážeme jen každý 10. den jako orientaci
                                    if (value == 0 || value == 9 || value == 19 || value == 29) {
                                      return Text('${den.day}.', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                    }
                                    return const Text('');
                                  }
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: data.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.toDouble(),
                                  color: entry.value >= widget.cil ? Colors.blue : Colors.white24, // Splněný cíl svítí modře
                                  width: jeTyden ? 20 : 6, // Tenčí sloupečky u měsíce
                                  borderRadius: BorderRadius.circular(5),
                                )
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}