import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart'; // NOVÝ IMPORT

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  // --- E-MAIL A HESLO ---
  static Future<String?> prihlasit(String email, String heslo) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: heslo);
      return null; 
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        try {
          await _auth.createUserWithEmailAndPassword(email: email, password: heslo);
          return null; 
        } catch (err) {
          return err.toString();
        }
      }
      return e.message; 
    } catch (e) {
      return e.toString();
    }
  }

  static Future<void> odhlasit() async {
    await _auth.signOut();          
  }

  // --- ZÁLOHA DO CLOUDU (Odeslání) ---
  static Future<void> zalohovatKroky(String datum, int kroky) async {
    if (currentUser == null) return; 
    try {
      await _db.collection('uzivatele').doc(currentUser!.uid)
               .collection('historie').doc(datum).set({'kroky': kroky});
    } catch (e) {
      debugPrint("Chyba zálohy: $e");
    }
  }

  // --- ⬇️ NOVÉ: STAŽENÍ Z CLOUDU (Při přihlášení) ⬇️ ---
  static Future<void> stahnoutHistoriiZCloudu() async {
    if (currentUser == null) return;
    try {
      // Stáhne celou složku 'historie' pro daného uživatele
      final snapshot = await _db.collection('uzivatele').doc(currentUser!.uid).collection('historie').get();
      
      // Projde všechny dny v cloudu a uloží je do tvé lokální SQLite databáze
      for (var doc in snapshot.docs) {
        String datum = doc.id;
        int kroky = doc.data()['kroky'] ?? 0;
        await DatabaseService.instance.ulozKroky(datum, kroky);
      }
    } catch (e) {
      debugPrint("Chyba při stahování historie: $e");
    }
  }
}