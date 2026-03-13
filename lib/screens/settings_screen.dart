import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  
import '../services/firebase_service.dart';

class NastaveniObrazovka extends StatefulWidget {
  final double vyska;
  final int cil;
  final Function(double, int) onZmena;

  const NastaveniObrazovka({super.key, required this.vyska, required this.cil, required this.onZmena});

  @override
  State<NastaveniObrazovka> createState() => _NastaveniObrazovkaState();
}

class _NastaveniObrazovkaState extends State<NastaveniObrazovka> {
  late double _nastavenaVyska;
  late double _nastavenyCil;
  String _vybranyJazyk = 'cs'; 

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hesloController = TextEditingController();
  
  bool _stahujeSe = false; // Ukazatel načítání pro synchronizaci

  @override
  void initState() {
    super.initState();
    _nastavenaVyska = widget.vyska;
    _nastavenyCil = widget.cil.toDouble();
  }

  void _zpracujVysledekPrihlaseni(String? chyba) async {
    if (!mounted) return;
    if (chyba == null) {
      // ⬇️ TADY SE SPOUŠTÍ SYNCHRONIZACE Z CLOUDU! ⬇️
      setState(() => _stahujeSe = true);
      await FirebaseService.stahnoutHistoriiZCloudu();
      
      if (!mounted) return;
      setState(() => _stahujeSe = false);
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Přihlášeno a data synchronizována!'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(chyba), backgroundColor: Colors.redAccent));
    }
  }

  void _ukazEmailDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Záloha do cloudu'),
        content: AutofillGroup( 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Zadej e-mail a heslo.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(labelText: 'E-mail')),
              TextField(controller: _hesloController, obscureText: true, autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Heslo')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () async {
              TextInput.finishAutofillContext(); 
              String? chyba = await FirebaseService.prihlasit(_emailController.text, _hesloController.text);
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _zpracujVysledekPrihlaseni(chyba); 
            },
            child: const Text('Přihlásit'),
          )
        ],
      ),
    );
  }

  // ✨ NOVÁ, MINIMALISTICKÁ KARTA ✨
  Widget _buildMinimalCard({required String titulek, required String hodnota, required Widget slider}) {
    return Container(
      padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 5),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulek, style: const TextStyle(fontSize: 16, color: Colors.white70)),
              Text(hodnota, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            ],
          ),
          slider,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool jePrihlasen = FirebaseService.currentUser != null;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          const Text('Nastavení', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          _buildMinimalCard(
            titulek: 'Tvoje výška',
            hodnota: '${_nastavenaVyska.toInt()} cm',
            slider: Slider(
              value: _nastavenaVyska, min: 100, max: 220, divisions: 120, activeColor: Colors.greenAccent,
              onChanged: (val) {
                setState(() => _nastavenaVyska = val);
                widget.onZmena(_nastavenaVyska, _nastavenyCil.toInt());
              },
            ),
          ),
          const SizedBox(height: 15),

          _buildMinimalCard(
            titulek: 'Denní cíl',
            hodnota: '${_nastavenyCil.toInt()}',
            slider: Slider(
              value: _nastavenyCil, min: 1000, max: 30000, divisions: 29, activeColor: Colors.greenAccent,
              onChanged: (val) {
                setState(() => _nastavenyCil = val);
                widget.onZmena(_nastavenaVyska, _nastavenyCil.toInt());
              },
            ),
          ),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [Icon(Icons.language, color: Colors.white70, size: 20), SizedBox(width: 10), Text('Jazyk', style: TextStyle(fontSize: 16))]),
                DropdownButton<String>(
                  value: _vybranyJazyk, dropdownColor: Colors.grey[900], underline: const SizedBox(),
                  items: const [DropdownMenuItem(value: 'cs', child: Text('🇨🇿 CZ')), DropdownMenuItem(value: 'en', child: Text('🇬🇧 EN'))],
                  onChanged: (val) { if (val != null) setState(() => _vybranyJazyk = val); },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // KARTA ZÁLOHY S INDIKÁTOREM NAČÍTÁNÍ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: jePrihlasen ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.white10, 
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: jePrihlasen ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.transparent)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(jePrihlasen ? Icons.cloud_done : Icons.cloud_off, color: jePrihlasen ? Colors.greenAccent : Colors.grey),
                    const SizedBox(width: 10),
                    const Text('Záloha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_stahujeSe) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                const SizedBox(height: 10),
                if (jePrihlasen) ...[
                  Text('${FirebaseService.currentUser!.email}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 15),
                  SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () async { await FirebaseService.odhlasit(); if (mounted) setState(() {}); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)), child: const Text('Odhlásit se')))
                ] else ...[
                  const Text('Tvá data se neukládají do cloudu.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 15),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _ukazEmailDialog, style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black), child: const Text('Zapnout zálohu')))
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}