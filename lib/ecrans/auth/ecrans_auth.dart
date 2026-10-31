// Inscription et connexion : téléphone + code SMS pour les clients,
// e-mail + mot de passe + double facteur pour l'administration.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/depot_auth.dart';
import '../../auth/session.dart';
import '../../comptes/depot_comptes.dart';
import '../../config/app_config.dart';
import '../../core/textes_legaux.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';

/// Indicatifs des pays de l'UEMOA (Togo par défaut).
const indicatifsUemoa = {
  '+228': 'Togo',
  '+229': 'Bénin',
  '+226': 'Burkina Faso',
  '+225': "Côte d'Ivoire",
  '+245': 'Guinée-Bissau',
  '+223': 'Mali',
  '+227': 'Niger',
  '+221': 'Sénégal',
};

/// Champ de numéro de téléphone avec choix de l'indicatif.
class ChampTelephone extends StatelessWidget {
  const ChampTelephone({
    super.key,
    required this.indicatif,
    required this.onIndicatif,
    required this.controleur,
    this.actif = true,
    this.onChanged,
  });

  final ValueChanged<String>? onChanged;
  final String indicatif;
  final ValueChanged<String> onIndicatif;
  final TextEditingController controleur;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: DropdownButtonFormField<String>(
            initialValue: indicatif,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Pays'),
            items: [
              for (final e in indicatifsUemoa.entries)
                DropdownMenuItem(value: e.key, child: Text(e.key, semanticsLabel: e.value)),
            ],
            onChanged: actif ? (v) => onIndicatif(v!) : null,
          ),
        ),
        const SizedBox(width: ArzikiEspaces.s),
        Expanded(
          child: TextField(
            controller: controleur,
            enabled: actif,
            onChanged: onChanged,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: const InputDecoration(labelText: 'Numéro de téléphone', hintText: '90 00 00 00'),
          ),
        ),
      ],
    );
  }
}

/// Champ pour un code à 6 chiffres.
class ChampCode extends StatelessWidget {
  const ChampCode({super.key, required this.controleur, this.libelle = 'Code reçu par SMS'});
  final TextEditingController controleur;
  final String libelle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controleur,
      keyboardType: TextInputType.number,
      autofocus: true,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
      decoration: InputDecoration(
        labelText: libelle,
        helperText: AppConfig.estDemo ? 'Démonstration : le code est ${AppConfig.codeSmsDemo}' : null,
        helperMaxLines: 2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Code d'invitation (investisseurs privés invités par l'administrateur)
// ---------------------------------------------------------------------------

class EcranInvitation extends ConsumerStatefulWidget {
  const EcranInvitation({super.key});

  @override
  ConsumerState<EcranInvitation> createState() => _EcranInvitationState();
}

class _EcranInvitationState extends ConsumerState<EcranInvitation> {
  final _code = TextEditingController();
  final _tel = TextEditingController();
  String _indicatif = '+228';
  String? _erreur;
  bool _enCours = false;

  Future<void> _verifier() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final telephone = '$_indicatif${_tel.text}';
    try {
      final inv = await ref.read(depotComptesProvider).verifierInvitation(code: _code.text, telephone: telephone);
      if (!mounted) return;
      context.push(Uri(path: Chemins.inscription, queryParameters: {
        'parcours': Parcours.invitation.code,
        'code': inv.code,
        'tel': telephone,
        if (inv.pourNom.isNotEmpty) 'nom': inv.pourNom,
      }).toString());
    } on ErreurAcces catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Code d'invitation")),
      body: Colonne(children: [
        const Text(
          "Le Cercle Arziki est privé. Votre code d'invitation est personnel : "
          'il ne fonctionne qu\'avec le numéro de téléphone auquel il a été attribué.',
        ),
        const SizedBox(height: ArzikiEspaces.l),
        TextField(
          controller: _code,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: "Code d'invitation",
            hintText: 'ARZ-XXXX-XXXX',
            helperText: AppConfig.estDemo ? 'Démonstration : ARZ-DEMO-2026 avec le 90 00 00 71' : null,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        ChampTelephone(
          indicatif: _indicatif,
          onIndicatif: (v) => setState(() => _indicatif = v),
          controleur: _tel,
        ),
        if (_erreur != null) ...[
          const SizedBox(height: ArzikiEspaces.m),
          Encadre(_erreur!, type: TypeEncadre.erreur),
        ],
        const SizedBox(height: ArzikiEspaces.l),
        FilledButton(onPressed: _enCours ? null : _verifier, child: const Text('Vérifier mon code')),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Inscription par téléphone (tous les parcours clients)
// ---------------------------------------------------------------------------

class EcranInscription extends ConsumerStatefulWidget {
  const EcranInscription({super.key, required this.parcours, this.codeInvitation, this.telephone, this.nomInvite});

  final Parcours parcours;
  final String? codeInvitation;
  final String? telephone;
  final String? nomInvite;

  @override
  ConsumerState<EcranInscription> createState() => _EcranInscriptionState();
}

class _EcranInscriptionState extends ConsumerState<EcranInscription> {
  final _tel = TextEditingController();
  final _code = TextEditingController();
  String _indicatif = '+228';
  bool _cgAcceptees = false; // jamais pré-cochée
  bool _codeEnvoye = false;
  bool _enCours = false;
  String? _erreur;

  bool get _telephoneImpose => widget.telephone != null;

  @override
  void initState() {
    super.initState();
    final t = widget.telephone;
    if (t != null) {
      final ind = indicatifsUemoa.keys.firstWhere((k) => t.startsWith(k), orElse: () => '+228');
      _indicatif = ind;
      _tel.text = t.substring(ind.length);
    }
  }

  String get _telephone => '$_indicatif${_tel.text}';

  Future<void> _envoyer() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(depotAuthProvider).envoyerCodeSms(_telephone);
      setState(() => _codeEnvoye = true);
    } on ErreurAuth catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _valider() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final u = await ref.read(depotAuthProvider).inscrireParTelephone(
            DemandeInscription(
              parcours: widget.parcours,
              telephone: _telephone,
              cgVersion: TextesLegaux.versionConditions,
              codeInvitation: widget.codeInvitation,
            ),
            _code.text,
          );
      ref.read(sessionProvider.notifier).connecter(u);
      if (mounted) context.go(Chemins.enAttente);
    } on ErreurAuth catch (e) {
      setState(() => _erreur = e.message);
    } on ErreurAcces catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.parcours;
    return Scaffold(
      appBar: AppBar(title: const Text('Créer mon compte')),
      body: Colonne(children: [
        Text(p.libelle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: ArzikiEspaces.s),
        if (widget.nomInvite != null)
          Encadre('Invitation reconnue au nom de ${widget.nomInvite}.', icone: Icons.verified_outlined),
        if (p == Parcours.candidature) const Encadre(TextesLegaux.cerclePrive, type: TypeEncadre.alerte),
        const SizedBox(height: ArzikiEspaces.l),
        ChampTelephone(
          indicatif: _indicatif,
          onIndicatif: (v) => setState(() => _indicatif = v),
          controleur: _tel,
          actif: !_codeEnvoye && !_telephoneImpose,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        CheckboxListTile(
          value: _cgAcceptees,
          onChanged: _codeEnvoye ? null : (v) => setState(() => _cgAcceptees = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            "J'ai lu et j'accepte les conditions d'utilisation et la politique de confidentialité.",
          ),
          subtitle: const Text('Version ${TextesLegaux.versionConditions}'),
        ),
        if (_codeEnvoye) ...[
          const SizedBox(height: ArzikiEspaces.m),
          ChampCode(controleur: _code),
        ],
        if (_erreur != null) ...[
          const SizedBox(height: ArzikiEspaces.m),
          Encadre(_erreur!, type: TypeEncadre.erreur),
        ],
        const SizedBox(height: ArzikiEspaces.l),
        if (!_codeEnvoye)
          FilledButton(
            onPressed: _enCours || !_cgAcceptees || _tel.text.length < 8 ? null : _envoyer,
            child: const Text('Recevoir mon code par SMS'),
          )
        else
          FilledButton(
            onPressed: _enCours ? null : _valider,
            child: const Text('Valider'),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Connexion d'un client existant
// ---------------------------------------------------------------------------

class EcranConnexion extends ConsumerStatefulWidget {
  const EcranConnexion({super.key});

  @override
  ConsumerState<EcranConnexion> createState() => _EcranConnexionState();
}

class _EcranConnexionState extends ConsumerState<EcranConnexion> {
  final _tel = TextEditingController();
  final _code = TextEditingController();
  String _indicatif = '+228';
  bool _codeEnvoye = false;
  bool _enCours = false;
  String? _erreur;

  Future<void> _action() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    final auth = ref.read(depotAuthProvider);
    final telephone = '$_indicatif${_tel.text}';
    try {
      if (!_codeEnvoye) {
        await auth.envoyerCodeSms(telephone);
        setState(() => _codeEnvoye = true);
      } else {
        final u = await auth.connecterParTelephone(telephone, _code.text);
        if (u == null) {
          setState(() => _erreur = "Aucun compte n'existe pour ce numéro. Revenez en arrière pour en créer un.");
          return;
        }
        ref.read(sessionProvider.notifier).connecter(u);
        if (mounted) context.go(Chemins.demarrage);
      }
    } on ErreurAuth catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Se connecter')),
      body: Colonne(children: [
        ChampTelephone(
          indicatif: _indicatif,
          onIndicatif: (v) => setState(() => _indicatif = v),
          controleur: _tel,
          actif: !_codeEnvoye,
        ),
        if (AppConfig.estDemo && !_codeEnvoye) ...[
          const SizedBox(height: ArzikiEspaces.s),
          const Encadre(
            'Démonstration : 90 00 00 21 (membre), 90 00 00 31 (partenaire), 90 00 00 11 (entreprise), '
            '90 00 00 41 (fournisseur), 90 00 00 51 (notaire), 90 00 00 61 (candidat).',
          ),
        ],
        if (_codeEnvoye) ...[
          const SizedBox(height: ArzikiEspaces.m),
          ChampCode(controleur: _code),
        ],
        if (_erreur != null) ...[
          const SizedBox(height: ArzikiEspaces.m),
          Encadre(_erreur!, type: TypeEncadre.erreur),
        ],
        const SizedBox(height: ArzikiEspaces.l),
        FilledButton(
          onPressed: _enCours ? null : _action,
          child: Text(_codeEnvoye ? 'Me connecter' : 'Recevoir mon code par SMS'),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Connexion administrateur : e-mail + mot de passe, puis double facteur
// ---------------------------------------------------------------------------

class EcranConnexionAdmin extends ConsumerStatefulWidget {
  const EcranConnexionAdmin({super.key});

  @override
  ConsumerState<EcranConnexionAdmin> createState() => _EcranConnexionAdminState();
}

class _EcranConnexionAdminState extends ConsumerState<EcranConnexionAdmin> {
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  bool _enCours = false;
  bool _masque = true;
  String? _erreur;

  Future<void> _connecter() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(depotAuthProvider).connecterAdmin(_email.text, _mdp.text);
      if (mounted) context.push(Chemins.doubleFacteur);
    } on ErreurAuth catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppConfig.estConsole ? null : AppBar(title: const Text('Accès administrateur')),
      body: Colonne(children: [
        const SizedBox(height: ArzikiEspaces.l),
        const Center(child: LogoArziki(hauteur: 72)),
        const SizedBox(height: ArzikiEspaces.l),
        Text("Console d'administration", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: ArzikiEspaces.s),
        const Text("Réservée à l'équipe ARZIKI. Chaque connexion est enregistrée."),
        const SizedBox(height: ArzikiEspaces.l),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Adresse e-mail'),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        TextField(
          controller: _mdp,
          obscureText: _masque,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _connecter(),
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            suffixIcon: IconButton(
              tooltip: _masque ? 'Afficher' : 'Masquer',
              icon: Icon(_masque ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _masque = !_masque),
            ),
          ),
        ),
        if (AppConfig.estDemo) ...[
          const SizedBox(height: ArzikiEspaces.s),
          const Encadre(
            'Démonstration : admin@arziki.demo (super administrateur), afi@arziki.demo (administrateur), '
            'analyste@arziki.demo (analyste). Mot de passe : demo1234.',
          ),
        ],
        if (_erreur != null) ...[
          const SizedBox(height: ArzikiEspaces.m),
          Encadre(_erreur!, type: TypeEncadre.erreur),
        ],
        const SizedBox(height: ArzikiEspaces.l),
        FilledButton(onPressed: _enCours ? null : _connecter, child: const Text('Continuer')),
      ]),
    );
  }
}

class EcranDoubleFacteur extends ConsumerStatefulWidget {
  const EcranDoubleFacteur({super.key});

  @override
  ConsumerState<EcranDoubleFacteur> createState() => _EcranDoubleFacteurState();
}

class _EcranDoubleFacteurState extends ConsumerState<EcranDoubleFacteur> {
  final _code = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  Future<void> _verifier() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final u = await ref.read(depotAuthProvider).verifierDoubleFacteur(_code.text);
      ref.read(sessionProvider.notifier).connecter(u);
      if (mounted) context.go(Chemins.admin);
    } on ErreurAuth catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Double vérification')),
      body: Colonne(children: [
        const Text(
          'Pour protéger la console, saisissez le code à 6 chiffres envoyé sur votre téléphone '
          "ou affiché dans votre application d'authentification.",
        ),
        const SizedBox(height: ArzikiEspaces.l),
        ChampCode(controleur: _code, libelle: 'Code de vérification'),
        if (_erreur != null) ...[
          const SizedBox(height: ArzikiEspaces.m),
          Encadre(_erreur!, type: TypeEncadre.erreur),
        ],
        const SizedBox(height: ArzikiEspaces.l),
        FilledButton(onPressed: _enCours ? null : _verifier, child: const Text('Vérifier')),
        const SizedBox(height: ArzikiEspaces.m),
        Text(
          'Code perdu ? Le super administrateur peut réinitialiser votre double facteur.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: ArzikiCouleurs.texteSecondaire),
        ),
      ]),
    );
  }
}
