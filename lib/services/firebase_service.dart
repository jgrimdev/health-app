import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Rychlá kontrola, zda je někdo přihlášený
  static User? get currentUser => _auth.currentUser;

  // --- E-MAIL A HESLO (Chytré přihlášení/registrace) ---
  static Future<String?> prihlasit(String email, String heslo) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: heslo);
      return null; // Vše v pořádku
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

  // --- ODHLÁŠENÍ ---
  static Future<void> odhlasit() async {
    await _auth.signOut();          
  }

  // --- ZÁLOHA DO CLOUDU ---
  static Future<void> zalohovatKroky(String datum, int kroky) async {
    if (currentUser == null) return; 
    
    try {
      await _db.collection('uzivatele').doc(currentUser!.uid)
               .collection('historie').doc(datum).set({'kroky': kroky});
    } catch (e) {
      // Ignorujeme tiché chyby při zápisu offline
    }
  }
}