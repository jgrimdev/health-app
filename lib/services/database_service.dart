import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  // Tzv. Singleton - chceme, aby běžela vždy jen jedna instance databáze
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('krokomer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Při prvním spuštění se vytvoří databáze
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Vytváříme tabulku 'historie'
    await db.execute('''
      CREATE TABLE historie (
        datum TEXT PRIMARY KEY,
        kroky INTEGER NOT NULL
      )
    ''');
  }

  // 💾 Funkce pro uložení kroků
  Future<void> ulozKroky(String datum, int kroky) async {
    final db = await instance.database;
    await db.insert(
      'historie',
      {'datum': datum, 'kroky': kroky},
      conflictAlgorithm: ConflictAlgorithm.replace, // Pokud datum už existuje, přepíše ho
    );
  }

  // 📖 Funkce pro čtení konkrétního dne
  Future<int> nactiKrokyProDatum(String datum) async {
    final db = await instance.database;
    final result = await db.query('historie', where: 'datum = ?', whereArgs: [datum]);
    
    if (result.isNotEmpty) {
      return result.first['kroky'] as int;
    }
    return 0; // Pokud pro daný den nic není, vrátí nulu
  }

// --- GAMIFIKACE: Výpočet Streaku (Dny v řadě) ---
  Future<int> spocitejStreak(int denniCil) async {
    int streak = 0;
    // Půjdeme do minulosti (den po dni, max 1000 dní)
    for (int i = 0; i < 1000; i++) {
      String den = DateTime.now().subtract(Duration(days: i)).toString().substring(0, 10);
      int kroky = await nactiKrokyProDatum(den);
      
      if (kroky >= denniCil) {
        streak++; // Cíl splněn, přidáme den
      } else {
        if (i == 0) {
          // Dnes jsi ještě nesplnil cíl? To nevadí, streak se nepřeruší, dokud nezkontrolujeme včerejšek
          continue;
        } else {
          // Včera (nebo dřív) jsi cíl nesplnil -> Streak končí
          break;
        }
      }
    }
    return streak;
  }

  // --- GAMIFIKACE: Celkový součet kroků za celou historii ---
  Future<int> spocitejCelkoveKroky() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT SUM(kroky) as total FROM historie');
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

}