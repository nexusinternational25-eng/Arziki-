// Mise en oeuvre de production de DepotComptes : lectures dans Firestore
// (autorisées par firestore.rules), écritures par les Cloud Functions.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../config/region.dart';
import '../core/roles.dart';
import '../models/acces.dart';
import '../models/utilisateur.dart';
import 'depot_comptes.dart';

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;

Utilisateur utilisateurDepuis(String uid, Map<String, dynamic> d) {
  return Utilisateur(
    uid: uid,
    role: Role.depuisCode(d['role'] as String?) ?? Role.candidatCercle,
    statut: StatutCompte.depuisCode(d['statut'] as String?),
    kycStatut: StatutKyc.depuisCode(d['kycStatut'] as String?),
    nom: d['nom'] as String? ?? '',
    prenom: d['prenom'] as String? ?? '',
    telephone: d['telephone'] as String?,
    email: d['email'] as String?,
    pays: d['pays'] as String? ?? 'TG',
    ville: d['ville'] as String?,
    invitationCode: d['invitationCode'] as String?,
    cgVersionAcceptee: d['cgVersionAcceptee'] as String?,
    cgAccepteeLe: _date(d['cgAccepteeLe']),
    creeLe: _date(d['creeLe']),
  );
}

class DepotComptesFirebase implements DepotComptes {
  DepotComptesFirebase({FirebaseFirestore? db, FirebaseFunctions? fonctions})
      : _db = db ?? FirebaseFirestore.instance,
        _fonctions = fonctions ?? FirebaseFunctions.instanceFor(region: regionFirebase);

  final FirebaseFirestore _db;
  final FirebaseFunctions _fonctions;

  /// Appelle une Cloud Function et traduit son erreur en message lisible.
  Future<Map<String, dynamic>> _appeler(String nom, Map<String, dynamic> donnees) async {
    try {
      final r = await _fonctions.httpsCallable(nom).call<Map<String, dynamic>>(donnees);
      return Map<String, dynamic>.from(r.data);
    } on FirebaseFunctionsException catch (e) {
      throw ErreurAcces(e.message ?? 'Action impossible pour le moment.');
    }
  }

  // ----- Lecture -----

  @override
  Future<Utilisateur?> lireProfil(String uid) async {
    final d = await _db.doc('users/$uid').get();
    return d.exists ? utilisateurDepuis(uid, d.data()!) : null;
  }

  @override
  Future<List<Utilisateur>> listerComptes() async {
    final q = await _db.collection('users').orderBy('nom').limit(500).get();
    return [for (final d in q.docs) utilisateurDepuis(d.id, d.data())];
  }

  @override
  Future<List<Invitation>> listerInvitations() async {
    final q = await _db.collection('invitations').orderBy('creeLe', descending: true).limit(200).get();
    return [
      for (final d in q.docs)
        Invitation(
          code: d.id,
          pourNom: d['pourNom'] as String,
          pourTelephone: d['pourTelephone'] as String,
          niveau: NiveauCercle.depuisCode(d['niveau'] as String?) ?? NiveauCercle.membre,
          creePar: d['creePar'] as String,
          creeLe: _date(d['creeLe']) ?? DateTime.now(),
          expireLe: _date(d['expireLe']) ?? DateTime.now(),
          note: d.data()['note'] as String?,
          utiliseLe: _date(d.data()['utiliseLe']),
          utilisePar: d.data()['utilisePar'] as String?,
          annuleeLe: _date(d.data()['annuleeLe']),
        ),
    ];
  }

  Candidature _candidature(Map<String, dynamic> d) => Candidature(
        uid: d['uid'] as String,
        nomComplet: d['nomComplet'] as String? ?? '',
        telephone: d['telephone'] as String? ?? '',
        niveauSouhaite: NiveauCercle.depuisCode(d['niveauSouhaite'] as String?) ?? NiveauCercle.membre,
        trancheEnvisagee: d['trancheEnvisagee'] as String? ?? '',
        commentNousConnu: d['commentNousConnu'] as String? ?? '',
        soumiseLe: _date(d['soumiseLe']) ?? DateTime.now(),
        statut: StatutCandidature.values.firstWhere((s) => s.code == d['statut'],
            orElse: () => StatutCandidature.soumise),
        decidePar: d['decidePar'] as String?,
        decideLe: _date(d['decideLe']),
        motif: d['motif'] as String?,
      );

  @override
  Future<List<Candidature>> listerCandidatures() async {
    final q = await _db.collection('candidatures').orderBy('soumiseLe', descending: true).limit(200).get();
    return [for (final d in q.docs) _candidature(d.data())];
  }

  @override
  Future<Candidature?> candidatureDe(String uid) async {
    final d = await _db.doc('candidatures/$uid').get();
    return d.exists ? _candidature(d.data()!) : null;
  }

  @override
  Future<List<EntreeAudit>> lireJournal() async {
    final q = await _db.collection('audit').orderBy('date', descending: true).limit(300).get();
    return [
      for (final d in q.docs)
        EntreeAudit(
          id: d.id,
          date: _date(d['date']) ?? DateTime.now(),
          acteurUid: d['acteurUid'] as String,
          action: d['action'] as String,
          cible: d['cible'] as String,
          avant: d.data()['avant'] as String?,
          apres: d.data()['apres'] as String?,
        ),
    ];
  }

  @override
  Future<int> tailleDuCercle() async {
    final r = await _db
        .collection('users')
        .where('role', whereIn: [for (final n in NiveauCercle.values) n.code])
        .where('statut', whereIn: ['actif', 'en_attente'])
        .count()
        .get();
    return r.count ?? 0;
  }

  // ----- Écritures : toujours par une Cloud Function -----

  @override
  Future<Invitation> creerInvitation({
    required Utilisateur acteur,
    required String pourNom,
    required String pourTelephone,
    required NiveauCercle niveau,
    int joursValidite = 30,
    String? note,
  }) async {
    final r = await _appeler('creerInvitation', {
      'pourNom': pourNom,
      'pourTelephone': pourTelephone,
      'niveau': niveau.code,
      'joursValidite': joursValidite,
      'note': note,
    });
    return Invitation(
      code: r['code'] as String,
      pourNom: pourNom.trim(),
      pourTelephone: ReglesAcces.normaliserTelephone(pourTelephone),
      niveau: niveau,
      creePar: acteur.uid,
      creeLe: DateTime.now(),
      expireLe: DateTime.fromMillisecondsSinceEpoch(r['expireLe'] as int),
      note: note,
    );
  }

  @override
  Future<void> annulerInvitation({required Utilisateur acteur, required String code}) =>
      _appeler('annulerInvitation', {'code': code});

  /// En production, le code est vérifié par la fonction « inscrire », après la
  /// vérification du numéro par SMS. Ici, on contrôle seulement le format.
  @override
  Future<Invitation> verifierInvitation({required String code, required String telephone}) async {
    final c = code.trim().toUpperCase();
    if (!RegExp(r'^ARZ-[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(c)) {
      throw const ErreurAcces("Ce code d'invitation n'a pas le bon format (ARZ-XXXX-XXXX).");
    }
    return Invitation(
      code: c,
      pourNom: '',
      pourTelephone: ReglesAcces.normaliserTelephone(telephone),
      niveau: NiveauCercle.membre,
      creePar: '',
      creeLe: DateTime.now(),
      expireLe: DateTime.now(),
    );
  }

  @override
  Future<Candidature> deposerCandidature({
    required Utilisateur candidat,
    required String prenom,
    required String nom,
    required NiveauCercle niveauSouhaite,
    required String trancheEnvisagee,
    required String commentNousConnu,
  }) async {
    await _appeler('deposerCandidature', {
      'prenom': prenom,
      'nom': nom,
      'niveauSouhaite': niveauSouhaite.code,
      'trancheEnvisagee': trancheEnvisagee,
      'commentNousConnu': commentNousConnu,
    });
    return (await candidatureDe(candidat.uid))!;
  }

  @override
  Future<void> admettreCandidat({required Utilisateur acteur, required String uid, required NiveauCercle niveau}) =>
      _appeler('deciderCandidature', {'uid': uid, 'decision': 'admettre', 'niveau': niveau.code});

  @override
  Future<void> refuserCandidat({required Utilisateur acteur, required String uid, required String motif}) =>
      _appeler('deciderCandidature', {'uid': uid, 'decision': 'refuser', 'motif': motif});

  @override
  Future<Utilisateur> soumettreKyc({
    required Utilisateur utilisateur,
    required Map<String, String> pieces,
    String? origineFonds,
  }) async {
    await _appeler('soumettreKyc', {'pieces': pieces, 'origineFonds': origineFonds});
    return utilisateur.copier(kycStatut: StatutKyc.enCours);
  }

  @override
  Future<void> validerKyc({required Utilisateur acteur, required String uid}) => _appeler('validerKyc', {'uid': uid});

  @override
  Future<void> demanderComplementKyc({required Utilisateur acteur, required String uid, required String motif}) =>
      _appeler('demanderComplementKyc', {'uid': uid, 'motif': motif});

  @override
  Future<void> suspendre({required Utilisateur acteur, required String uid, required String motif}) =>
      _appeler('changerStatutCompte', {'uid': uid, 'action': 'suspendre', 'motif': motif});

  @override
  Future<void> reactiver({required Utilisateur acteur, required String uid}) =>
      _appeler('changerStatutCompte', {'uid': uid, 'action': 'reactiver'});

  @override
  Future<void> attribuerRole({required Utilisateur acteur, required String uid, required Role role}) =>
      _appeler('attribuerRole', {'uid': uid, 'role': role.code});

  @override
  Future<Utilisateur> creerCompteEquipe({
    required Utilisateur acteur,
    required String prenom,
    required String nom,
    required String email,
    required Role role,
  }) async {
    final r = await _appeler('creerCompteEquipe', {'prenom': prenom, 'nom': nom, 'email': email, 'role': role.code});
    return Utilisateur(
      uid: r['uid'] as String,
      role: role,
      statut: StatutCompte.actif,
      kycStatut: StatutKyc.valide,
      prenom: prenom,
      nom: nom,
      email: email,
    );
  }

  @override
  Future<void> signalerAccesRefuse({required Utilisateur utilisateur, required String chemin}) async {
    try {
      await _appeler('signalerAccesRefuse', {'chemin': chemin});
    } on ErreurAcces {
      // Le signalement ne doit jamais bloquer l'affichage de l'écran.
    }
  }
}
