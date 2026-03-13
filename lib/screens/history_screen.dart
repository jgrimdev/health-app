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
  String _vybranyPohled = 'tyden'; 
  final Map<int, List<int>> _nacteneTydny = {};
  final Map<int, List<int>> _nacteneMesice = {};
  
  // Pamatuje si, na který sloupec jsi zrovna "ťuknul" prstem
  int? _dotknutyIndex;

  Future<void> _nactiData(int index) async {
    bool jeTyden = _vybranyPohled == 'tyden';
    int pocetDni = jeTyden ? 7 : 30; 
    
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
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tyden', label: Text('Týden')),
              ButtonSegment(value: 'mesic', label: Text('Měsíc')),
            ],
            selected: {_vybranyPohled},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _vybranyPohled = newSelection.first;
                _dotknutyIndex = null; // Resetuje bublinu při změně pohledu
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.white10,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: Colors.greenAccent.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 30),
          
          Expanded(
            key: ValueKey(_vybranyPohled), 
            child: PageView.builder(
              reverse: true,
              onPageChanged: (index) {
                setState(() => _dotknutyIndex = null); // Reset při swajpnutí
                _nactiData(index);
              },
              itemBuilder: (context, index) {
                if ((jeTyden && !_nacteneTydny.containsKey(index)) || (!jeTyden && !_nacteneMesice.containsKey(index))) {
                  _nactiData(index);
                  return const Center(child: CircularProgressIndicator());
                }

                List<int> data = jeTyden ? _nacteneTydny[index]! : _nacteneMesice[index]!;
                String nadpisZobrazeni = index == 0 
                  ? (jeTyden ? 'Tento týden' : 'Posledních 30 dní') 
                  : 'Před $index ${jeTyden ? (index == 1 ? 'týdnem' : 'týdny') : (index == 1 ? 'měsícem' : 'měsíci')}';

                return Column(
                  children: [
                    Text(nadpisZobrazeni, style: const TextStyle(fontSize: 18, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 40), // Větší mezera pro bubliny nahoře
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (widget.cil * 1.5).toDouble(), // Osa Y je vždy 1.5x větší než cíl
                          
                          // ✨ 1. PŘERUŠOVANÁ ČÁRA DENNÍHO CÍLE ✨
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: widget.cil.toDouble(),
                                color: Colors.greenAccent.withValues(alpha: 0.5),
                                strokeWidth: 2,
                                dashArray: [10, 5], // Efekt přerušování
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                                  style: const TextStyle(fontSize: 10, color: Colors.greenAccent),
                                  labelResolver: (line) => 'Cíl: ${widget.cil}',
                                ),
                              ),
                            ],
                          ),
                          
                          // ✨ 2. KLIKACÍ BUBLINY S POČTEM KROKŮ ✨
                          barTouchData: BarTouchData(
                            enabled: true,
                            handleBuiltInTouches: false, // 👈 TÍMTO ZAKÁŽEME VÝCHOZÍ SCHOVÁVÁNÍ
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.grey[800]!,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${rod.toY.toInt()}',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                            touchCallback: (FlTouchEvent event, barTouchResponse) {
                              setState(() {
                                // Pokud uživatel klikne do prázdna, bublina zmizí
                                if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
                                  _dotknutyIndex = null;
                                  return;
                                }
                                // Uloží si, na který sloupec bylo kliknuto
                                _dotknutyIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                              });
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (double value, TitleMeta meta) {
                                  DateTime den = DateTime.now().subtract(Duration(days: (index * (jeTyden ? 7 : 30)) + (jeTyden ? 6 : 29) - value.toInt()));
                                  if (jeTyden) {
                                    const dny = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
                                    return Text(dny[den.weekday - 1], style: const TextStyle(fontSize: 12));
                                  } else {
                                    if (value == 0 || value == 9 || value == 19 || value == 29) {
                                      return Text('${den.day}.', style: const TextStyle(fontSize: 10, color: Colors.grey));
                                    }
                                    return const Text('');
                                  }
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          
                          barGroups: data.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              // ✨ ZOBRAZÍ BUBLINU NATRVALO, POKUD JE INDEX VYBRÁN ✨
                              showingTooltipIndicators: _dotknutyIndex == entry.key ? [0] : [],
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.toDouble(),
                                  color: entry.value >= widget.cil ? Colors.greenAccent : Colors.white24,
                                  width: jeTyden ? 20 : 6, 
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