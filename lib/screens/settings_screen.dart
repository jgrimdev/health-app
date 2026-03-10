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

  @override
  void initState() {
    super.initState();
    _nastavenaVyska = widget.vyska;
    _nastavenyCil = widget.cil.toDouble();
  }

  void _zpracujVysledekPrihlaseni(String? chyba) {
    if (!mounted) return;
    if (chyba == null) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Záloha aktivní!'), backgroundColor: Colors.green));
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
              const Text('Zadej e-mail a heslo. Pokud účet nemáš, automaticky tě zaregistrujeme.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              TextField(
                controller: _hesloController,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Heslo'),
              ),
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
            child: const Text('Přihlásit / Registrovat'),
          )
        ],
      ),
    );
  }

  // Pomocný widget pro moderní karty
  Widget _buildModernCard({required String titulek, required String hodnota, required Widget slider}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text(titulek, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(hodnota, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          const SizedBox(height: 10),
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
          const SizedBox(height: 30),

          // --- 1. VÝŠKA ---
          _buildModernCard(
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
          const SizedBox(height: 20),

          // --- 2. CÍL KROKŮ ---
          _buildModernCard(
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
          const SizedBox(height: 30),

          // --- 3. JAZYK ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.language, color: Colors.white70),
                    SizedBox(width: 15),
                    Text('Jazyk aplikace', style: TextStyle(fontSize: 16)),
                  ],
                ),
                DropdownButton<String>(
                  value: _vybranyJazyk,
                  dropdownColor: Colors.grey[900],
                  underline: const SizedBox(), 
                  items: const [
                    DropdownMenuItem(value: 'cs', child: Text('🇨🇿 CZ')),
                    DropdownMenuItem(value: 'en', child: Text('🇬🇧 EN')),
                  ],
                  onChanged: (String? novaHodnota) {
                    if (novaHodnota != null) {
                      setState(() => _vybranyJazyk = novaHodnota);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Překlady brzy přidáme!')));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 4. ZÁLOHA DO CLOUDU (Nejvíc dole) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: jePrihlasen ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.white10, 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: jePrihlasen ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.transparent)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(jePrihlasen ? Icons.cloud_done : Icons.cloud_off, color: jePrihlasen ? Colors.greenAccent : Colors.grey),
                    const SizedBox(width: 10),
                    const Text('Cloudová záloha', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                if (jePrihlasen) ...[
                  Text('Záloha probíhá na účet:\n${FirebaseService.currentUser!.email}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await FirebaseService.odhlasit();
                        if (mounted) setState(() {});
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                      child: const Text('Odhlásit se'),
                    ),
                  )
                ] else ...[
                  const Text('Tvá data se neukládají do cloudu.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _ukazEmailDialog, 
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                      child: const Text('Zapnout zálohu'),
                    ),
                  )
                ]
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}