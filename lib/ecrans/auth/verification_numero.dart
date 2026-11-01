// Vérification du numéro de téléphone, commune à l'inscription et à la connexion.
// Décision du propriétaire (1er novembre 2026) : WhatsApp d'abord, SMS en secours.
//
// 1. Voie principale : « Vérifier avec WhatsApp ». WhatsApp s'ouvre avec un message
//    déjà écrit, adressé au numéro d'ARZIKI. Le client l'envoie, ARZIKI le reçoit,
//    la vérification se termine toute seule. Rien à payer pour ARZIKI.
// 2. Secours : un code à 6 chiffres envoyé par WhatsApp, puis par SMS.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/depot_auth.dart';
import '../../auth/session.dart';
import '../../comptes/depot_comptes.dart';
import '../../config/app_config.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';
import 'ecrans_auth.dart' show ChampCode;

enum _Etape { choix, attenteMessage, saisieCode }

class VerificationNumero extends ConsumerStatefulWidget {
  const VerificationNumero({
    super.key,
    required this.telephone,
    required this.actif,
    required this.onPreuve,
    this.onVerrouillage,
    this.libelleValider = 'Valider',
  });

  /// Numéro complet saisi (avec l'indicatif).
  final String Function() telephone;

  /// Vrai quand le numéro est saisi (et les conditions acceptées, à l'inscription).
  final bool actif;

  /// Appelée avec la preuve ; lève ErreurAuth ou ErreurAcces en cas de refus.
  final Future<void> Function(PreuveTelephone preuve) onPreuve;

  /// Prévient l'écran quand le numéro ne doit plus être modifié.
  final ValueChanged<bool>? onVerrouillage;

  final String libelleValider;

  @override
  ConsumerState<VerificationNumero> createState() => _VerificationNumeroState();
}

class _VerificationNumeroState extends ConsumerState<VerificationNumero> {
  static const _intervalle = Duration(seconds: 3);
  static const _delaiMax = Duration(minutes: 10);

  final _code = TextEditingController();
  _Etape _etape = _Etape.choix;
  bool _autresMoyens = false;
  bool _enCours = false;
  String? _erreur;
  CanalCode? _canal;
  VerificationParMessage? _verification;
  Timer? _minuteur;
  DateTime? _debut;

  @override
  void dispose() {
    _minuteur?.cancel();
    _code.dispose();
    super.dispose();
  }

  String _message(Object e) => switch (e) {
        ErreurAuth(:final message) => message,
        ErreurAcces(:final message) => message,
        _ => 'Une erreur est survenue. Réessayez.',
      };

  void _verrouiller(bool v) => widget.onVerrouillage?.call(v);

  Future<void> _executer(Future<void> Function() action) async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _erreur = _message(e));
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  // ----- Voie principale : le client envoie le message -----

  Future<void> _verifierAvecWhatsapp() => _executer(() async {
        final v = await ref.read(depotAuthProvider).demarrerVerificationParMessage(widget.telephone());
        _verrouiller(true);
        setState(() {
          _verification = v;
          _etape = _Etape.attenteMessage;
          _debut = DateTime.now();
        });
        await _ouvrirWhatsapp();
        _minuteur?.cancel();
        _minuteur = Timer.periodic(_intervalle, (_) => _consulter());
      });

  Future<void> _ouvrirWhatsapp() async {
    final v = _verification;
    // En démonstration, on n'ouvre pas WhatsApp : la réception est simulée.
    if (v == null || AppConfig.estDemo) return;
    final ok = await launchUrl(v.lien, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) {
      setState(() => _erreur = "WhatsApp n'a pas pu s'ouvrir. Choisissez de recevoir un code.");
    }
  }

  bool _consultationEnCours = false;

  Future<void> _consulter() async {
    final v = _verification;
    if (v == null || _consultationEnCours) return;
    if (DateTime.now().difference(_debut!) > _delaiMax) {
      _minuteur?.cancel();
      setState(() {
        _etape = _Etape.choix;
        _erreur = 'Le délai est dépassé. Recommencez la vérification.';
      });
      _verrouiller(false);
      return;
    }
    _consultationEnCours = true;
    try {
      final recu = await ref.read(depotAuthProvider).verificationConfirmee(v.id);
      if (!recu || !mounted) return;
      _minuteur?.cancel();
      await _executer(() => widget.onPreuve(PreuveMessage(v.id)));
    } catch (e) {
      _minuteur?.cancel();
      if (mounted) setState(() => _erreur = _message(e));
    } finally {
      _consultationEnCours = false;
    }
  }

  // ----- Secours : code par WhatsApp ou par SMS -----

  Future<void> _recevoirCode(CanalCode canal) => _executer(() async {
        _minuteur?.cancel();
        await ref.read(depotAuthProvider).envoyerCode(widget.telephone(), canal);
        _verrouiller(true);
        _code.clear();
        setState(() {
          _canal = canal;
          _etape = _Etape.saisieCode;
        });
      });

  Future<void> _validerCode() => _executer(() => widget.onPreuve(PreuveCode(_code.text)));

  void _changerDeMoyen() {
    _minuteur?.cancel();
    _verrouiller(false);
    setState(() {
      _etape = _Etape.choix;
      _autresMoyens = true;
      _erreur = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final contenu = switch (_etape) {
      _Etape.choix => _choix(t),
      _Etape.attenteMessage => _attente(t),
      _Etape.saisieCode => _saisie(t),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...contenu,
      if (_erreur != null) ...[
        const SizedBox(height: ArzikiEspaces.m),
        Encadre(_erreur!, type: TypeEncadre.erreur),
      ],
    ]);
  }

  List<Widget> _choix(TextTheme t) {
    final actif = widget.actif && !_enCours;
    return [
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: ArzikiCouleurs.vert),
        onPressed: actif ? _verifierAvecWhatsapp : null,
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Vérifier avec WhatsApp'),
      ),
      const SizedBox(height: ArzikiEspaces.s),
      Text(
        "WhatsApp s'ouvre avec un message déjà écrit : vous n'avez qu'à l'envoyer à ARZIKI.",
        style: t.bodySmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: ArzikiEspaces.s),
      if (!_autresMoyens)
        TextButton(
          onPressed: () => setState(() => _autresMoyens = true),
          child: const Text('Je préfère recevoir un code'),
        )
      else ...[
        const SizedBox(height: ArzikiEspaces.s),
        OutlinedButton.icon(
          onPressed: actif ? () => _recevoirCode(CanalCode.whatsapp) : null,
          icon: const Icon(Icons.mark_chat_unread_outlined),
          label: const Text('Recevoir un code par WhatsApp'),
        ),
        const SizedBox(height: ArzikiEspaces.s),
        OutlinedButton.icon(
          onPressed: actif ? () => _recevoirCode(CanalCode.sms) : null,
          icon: const Icon(Icons.sms_outlined),
          label: const Text('Recevoir un code par SMS'),
        ),
      ],
    ];
  }

  List<Widget> _attente(TextTheme t) => [
        CarteArziki(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Envoyez le message WhatsApp', style: t.titleMedium),
            const SizedBox(height: ArzikiEspaces.s),
            const _Etape1('1', "WhatsApp s'ouvre avec un message déjà écrit pour ARZIKI."),
            const _Etape1('2', 'Appuyez sur Envoyer.'),
            const _Etape1('3', 'Revenez ici : la vérification se termine toute seule.'),
            const SizedBox(height: ArzikiEspaces.m),
            const LinearProgressIndicator(),
            const SizedBox(height: ArzikiEspaces.s),
            Text('En attente de votre message', style: t.bodySmall),
          ]),
        ),
        if (AppConfig.estDemo) ...[
          const SizedBox(height: ArzikiEspaces.s),
          const Encadre(
            "Démonstration : WhatsApp ne s'ouvre pas, la réception du message est simulée en quelques secondes.",
          ),
        ],
        const SizedBox(height: ArzikiEspaces.m),
        OutlinedButton.icon(
          onPressed: _enCours ? null : _ouvrirWhatsapp,
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Rouvrir WhatsApp'),
        ),
        TextButton(
          onPressed: _enCours ? null : _changerDeMoyen,
          child: const Text("Je n'ai pas WhatsApp sur ce numéro"),
        ),
      ];

  List<Widget> _saisie(TextTheme t) => [
        Text(
          _canal == CanalCode.whatsapp
              ? 'Nous vous avons envoyé un code par WhatsApp.'
              : 'Nous vous avons envoyé un code par SMS.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: ArzikiEspaces.m),
        ChampCode(
          controleur: _code,
          libelle: 'Code reçu par ${_canal?.libelle ?? 'SMS'}',
          onSubmitted: (_) => _validerCode(),
        ),
        const SizedBox(height: ArzikiEspaces.l),
        FilledButton(onPressed: _enCours ? null : _validerCode, child: Text(widget.libelleValider)),
        if (_canal == CanalCode.whatsapp)
          TextButton(
            onPressed: _enCours ? null : () => _recevoirCode(CanalCode.sms),
            child: const Text('Rien reçu ? Recevoir le code par SMS'),
          ),
        TextButton(
          onPressed: _enCours ? null : _changerDeMoyen,
          child: const Text('Changer de moyen de vérification'),
        ),
      ];
}

/// Une étape numérotée dans la carte d'attente.
class _Etape1 extends StatelessWidget {
  const _Etape1(this.numero, this.texte);
  final String numero;
  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: ArzikiEspaces.s),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: ArzikiCouleurs.vert,
            child: Text(numero, style: const TextStyle(color: ArzikiCouleurs.blanc, fontSize: 12)),
          ),
          const SizedBox(width: ArzikiEspaces.s),
          Expanded(child: Text(texte)),
        ]),
      );
}
