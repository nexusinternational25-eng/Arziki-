// Authentification de production avec Firebase Auth :
// - clients : numéro de téléphone + code SMS ;
// - administration : e-mail + mot de passe + double facteur (TOTP),
//   fonction « Multi-factor » de Firebase Authentication with Identity Platform.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../comptes/depot_comptes.dart';
import '../comptes/depot_comptes_firebase.dart';
import '../config/region.dart';
import '../models/utilisateur.dart';
import 'depot_auth.dart';

class DepotAuthFirebase implements DepotAuth {
  DepotAuthFirebase({FirebaseAuth? auth, FirebaseFirestore? db, FirebaseFunctions? fonctions})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _fonctions = fonctions ?? FirebaseFunctions.instanceFor(region: regionFirebase);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _fonctions;

  String? _verificationId;
  ConfirmationResult? _confirmationWeb;
  MultiFactorResolver? _resolveur;

  ErreurAuth _traduire(FirebaseAuthException e) => ErreurAuth(switch (e.code) {
        'invalid-verification-code' => 'Code incorrect.',
        'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
        'invalid-phone-number' => 'Numéro de téléphone invalide.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Adresse e-mail ou mot de passe incorrect.',
        'user-disabled' => 'Ce compte est désactivé.',
        _ => 'Connexion impossible pour le moment.',
      });

  @override
  Future<void> envoyerCodeSms(String telephone) async {
    final numero = ReglesAcces.normaliserTelephone(telephone);
    try {
      if (kIsWeb) {
        _confirmationWeb = await _auth.signInWithPhoneNumber(numero);
        return;
      }
      final envoye = Completer<void>();
      await _auth.verifyPhoneNumber(
        phoneNumber: numero,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          if (!envoye.isCompleted) envoye.completeError(_traduire(e));
        },
        codeSent: (id, _) {
          _verificationId = id;
          if (!envoye.isCompleted) envoye.complete();
        },
        codeAutoRetrievalTimeout: (id) => _verificationId = id,
      );
      await envoye.future;
    } on FirebaseAuthException catch (e) {
      throw _traduire(e);
    }
  }

  Future<User> _validerCode(String code) async {
    try {
      final UserCredential cred;
      if (kIsWeb) {
        final c = _confirmationWeb;
        if (c == null) throw const ErreurAuth('Demandez d\'abord un code.');
        cred = await c.confirm(code.trim());
      } else {
        final id = _verificationId;
        if (id == null) throw const ErreurAuth('Demandez d\'abord un code.');
        cred = await _auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: id, smsCode: code.trim()));
      }
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw _traduire(e);
    }
  }

  Future<Utilisateur?> _profil(String uid) async {
    final d = await _db.doc('users/$uid').get();
    return d.exists ? utilisateurDepuis(uid, d.data()!) : null;
  }

  @override
  Future<Utilisateur?> connecterParTelephone(String telephone, String code) async {
    final user = await _validerCode(code);
    final profil = await _profil(user.uid);
    if (profil == null) {
      await _auth.signOut();
      return null;
    }
    if (profil.role.estAdministration) {
      await _auth.signOut();
      throw const ErreurAuth('Les administrateurs se connectent avec leur adresse e-mail.');
    }
    return profil;
  }

  @override
  Future<Utilisateur> inscrireParTelephone(DemandeInscription demande, String code) async {
    final user = await _validerCode(code);
    try {
      await _fonctions.httpsCallable('inscrire').call<Map<String, dynamic>>({
        'parcours': demande.parcours.code,
        'codeInvitation': demande.codeInvitation,
        'cgVersion': demande.cgVersion,
      });
    } on FirebaseFunctionsException catch (e) {
      await _auth.signOut();
      throw ErreurAuth(e.message ?? 'Inscription impossible pour le moment.');
    }
    // Recharge le jeton pour obtenir le rôle posé par le serveur.
    await user.getIdToken(true);
    return (await _profil(user.uid))!;
  }

  @override
  Future<void> connecterAdmin(String email, String motDePasse) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: motDePasse);
      // Pas de double facteur enregistré : refus. Le super administrateur
      // active le double facteur à la création du compte.
      await _auth.signOut();
      throw const ErreurAuth(
          'Double facteur non activé sur ce compte. Contactez le super administrateur.');
    } on FirebaseAuthMultiFactorException catch (e) {
      _resolveur = e.resolver;
    } on FirebaseAuthException catch (e) {
      throw _traduire(e);
    }
  }

  @override
  Future<Utilisateur> verifierDoubleFacteur(String code) async {
    final resolveur = _resolveur;
    if (resolveur == null) throw const ErreurAuth('Reprenez la connexion depuis le début.');
    final indice = resolveur.hints.whereType<TotpMultiFactorInfo>().firstOrNull;
    if (indice == null) throw const ErreurAuth("Aucune application d'authentification n'est enregistrée.");
    try {
      final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(indice.uid, code.trim());
      final cred = await resolveur.resolveSignIn(assertion);
      _resolveur = null;
      final profil = await _profil(cred.user!.uid);
      if (profil == null || !profil.role.estAdministration) {
        await _auth.signOut();
        throw const ErreurAuth("Ce compte n'a pas accès à la console.");
      }
      return profil;
    } on FirebaseAuthException catch (e) {
      throw _traduire(e);
    }
  }

  @override
  Future<void> deconnecter() async {
    _resolveur = null;
    await _auth.signOut();
  }
}
