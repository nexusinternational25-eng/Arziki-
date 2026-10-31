// Accès sécurisé du super administrateur en mode démonstration.
//
// Tant que le projet Firebase n'est pas branché, il n'y a pas de serveur pour
// vérifier les mots de passe. Pour que la console ne soit pas ouverte à tous :
//   1. le mot de passe n'est JAMAIS écrit ici : on garde seulement une empreinte
//      PBKDF2-SHA256 (20 000 itérations, sel aléatoire), impossible à inverser ;
//   2. la double vérification utilise un code à 6 chiffres qui change toutes les
//      30 secondes (TOTP, RFC 6238), généré par une application d'authentification
//      (Google Authenticator, Microsoft Authenticator...) ;
//   3. la clé de ces codes est elle-même chiffrée avec le mot de passe : sans le
//      bon mot de passe, impossible de la retrouver.
// En production, tout cela est remplacé par Firebase Authentication (serveur).

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Paramètres de vérification d'un compte d'administration.
class ParametresAccesAdmin {
  const ParametresAccesAdmin({
    required this.identifiant,
    required this.uid,
    required this.sel,
    required this.iterations,
    required this.empreinte,
    required this.cleTotpChiffree,
  });

  final String identifiant;
  final String uid;
  final String sel;
  final int iterations;
  final String empreinte;
  final String cleTotpChiffree;

  /// Compte du super administrateur (le propriétaire). Valeurs générées une seule fois ;
  /// le mot de passe et la clé des codes ont été remis au propriétaire, nulle part ailleurs.
  static const proprietaire = ParametresAccesAdmin(
    identifiant: 'oumara',
    uid: 'u-super-admin',
    sel: '8b31a336dd5506f101b07f7745d28e91',
    iterations: 20000,
    empreinte: '4bd59cbf6383fd700cf61704f71629e5e3176e378b6a78f2fa41ea2ffd9b6ef6',
    cleTotpChiffree: '2a3aa122c06aa4a8ce7f298858c6dbe2a667e89d',
  );
}

Uint8List hexVersOctets(String h) =>
    Uint8List.fromList([for (var i = 0; i < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16)]);

/// PBKDF2 avec HMAC-SHA256 (RFC 8018).
Uint8List pbkdf2(List<int> motDePasse, List<int> sel, int iterations, int longueur) {
  final hmac = Hmac(sha256, motDePasse);
  final resultat = BytesBuilder();
  var bloc = 1;
  while (resultat.length < longueur) {
    final entree = [...sel, (bloc >> 24) & 0xff, (bloc >> 16) & 0xff, (bloc >> 8) & 0xff, bloc & 0xff];
    var u = hmac.convert(entree).bytes;
    final t = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    resultat.add(t);
    bloc++;
  }
  return Uint8List.fromList(resultat.toBytes().sublist(0, longueur));
}

/// Comparaison en temps constant (évite de deviner l'empreinte octet par octet).
bool _egaux(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// Vérifie le mot de passe. Renvoie la clé des codes à 6 chiffres si c'est le bon, sinon null.
Uint8List? verifierMotDePasse(ParametresAccesAdmin compte, String motDePasse) {
  final derive = pbkdf2(utf8.encode(motDePasse), hexVersOctets(compte.sel), compte.iterations, 52);
  if (!_egaux(derive.sublist(0, 32), hexVersOctets(compte.empreinte))) return null;
  final chiffree = hexVersOctets(compte.cleTotpChiffree);
  return Uint8List.fromList([for (var i = 0; i < chiffree.length; i++) chiffree[i] ^ derive[32 + i]]);
}

/// Code à 6 chiffres pour une période de 30 secondes (TOTP, RFC 6238, HMAC-SHA1).
String codeTotp(List<int> cle, DateTime instant) {
  final compteur = instant.toUtc().millisecondsSinceEpoch ~/ 1000 ~/ 30;
  final message = Uint8List(8);
  var c = compteur;
  for (var i = 7; i >= 0; i--) {
    message[i] = c & 0xff;
    c >>= 8;
  }
  final h = Hmac(sha1, cle).convert(message).bytes;
  final decalage = h[h.length - 1] & 0x0f;
  final binaire = ((h[decalage] & 0x7f) << 24) |
      ((h[decalage + 1] & 0xff) << 16) |
      ((h[decalage + 2] & 0xff) << 8) |
      (h[decalage + 3] & 0xff);
  return (binaire % 1000000).toString().padLeft(6, '0');
}

/// Accepte le code de la période en cours et des périodes voisines
/// (tolérance de 30 secondes si l'heure du téléphone est un peu décalée).
bool verifierCodeTotp(List<int> cle, String code, DateTime maintenant) {
  final saisi = code.trim();
  if (!RegExp(r'^\d{6}$').hasMatch(saisi)) return false;
  for (final decalage in const [-30, 0, 30]) {
    if (codeTotp(cle, maintenant.add(Duration(seconds: decalage))) == saisi) return true;
  }
  return false;
}
