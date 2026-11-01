// Profil (photo, statut de vérification, complétude, documents) et Paramètres.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/session.dart';
import '../../config/app_config.dart';
import '../../contenu/contenus.dart';
import '../../core/kyc.dart';
import '../../core/roles.dart';
import '../../models/utilisateur.dart';
import '../../preferences/preferences.dart';
import '../../router/garde_roles.dart';
import '../../theme/arziki_theme.dart';
import '../../ui/composants.dart';

/// Complétude du profil, en pourcentage (nom, prénom, ville, téléphone ou e-mail, identité).
int completude(Utilisateur u) {
  var points = 0;
  if (u.prenom.isNotEmpty) points++;
  if (u.nom.isNotEmpty) points++;
  if ((u.ville ?? '').isNotEmpty) points++;
  if ((u.telephone ?? u.email ?? '').isNotEmpty) points++;
  if (u.kycStatut == StatutKyc.valide) {
    points += 2;
  } else if (u.kycStatut == StatutKyc.enCours) {
    points += 1;
  }
  return (points * 100 / 6).round();
}

BadgeStatut badgeKyc(StatutKyc s) => switch (s) {
      StatutKyc.valide => const BadgeStatut('Identité vérifiée', ton: TonBadge.succes, icone: Icons.verified_rounded),
      StatutKyc.enCours => const BadgeStatut('Vérification en cours', ton: TonBadge.info, icone: Icons.hourglass_top_rounded),
      StatutKyc.aCompleter => const BadgeStatut('Pièces à compléter', ton: TonBadge.alerte, icone: Icons.error_outline_rounded),
      StatutKyc.refuse => const BadgeStatut('Vérification refusée', ton: TonBadge.erreur),
      StatutKyc.nonCommence => const BadgeStatut('Identité non vérifiée', ton: TonBadge.attente),
    };

class EcranProfil extends ConsumerWidget {
  const EcranProfil({super.key, this.integre = false});
  final bool integre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final t = Theme.of(context).textTheme;
    final pct = completude(u);

    Widget lien(IconData icone, String titre, String sousTitre, VoidCallback onTap) => CarteArziki(
          onTap: onTap,
          child: Row(children: [
            Icon(icone, color: ArzikiCouleurs.vert),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titre, style: t.titleSmall),
                Text(sousTitre, style: t.bodySmall),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        );

    final corps = Colonne(children: [
      if (integre) const EnTetePage('Mon profil', 'Vos informations, vos documents et vos réglages.'),
      CarteArziki(
        child: Column(children: [
          Row(children: [
            Stack(children: [
              AvatarArziki(nom: u.nomComplet, taille: 72),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: ArzikiCouleurs.orange,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => annoncer(context, 'Choisissez une photo depuis votre galerie (disponible avec le projet Firebase).'),
                    child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.photo_camera_rounded, size: 16, color: ArzikiCouleurs.blanc)),
                  ),
                ),
              ),
            ]),
            const SizedBox(width: ArzikiEspaces.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.nomComplet, style: t.titleLarge),
                Text(u.role.libelle, style: t.bodySmall),
                const SizedBox(height: 6),
                badgeKyc(u.kycStatut),
              ]),
            ),
          ]),
          const SizedBox(height: ArzikiEspaces.m),
          Row(children: [
            Expanded(child: Text('Profil complété à $pct %', style: t.labelLarge)),
            if (pct < 100)
              TextButton(onPressed: () => _modifier(context, ref, u), child: const Text('Compléter')),
          ]),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: ArzikiCouleurs.vert.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(pct == 100 ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
            ),
          ),
        ]),
      ),
      CarteArziki(
        child: Column(children: [
          _Info('Téléphone', u.telephone ?? 'Non renseigné'),
          _Info('E-mail', u.email ?? 'Non renseigné'),
          _Info('Ville', u.ville ?? 'Non renseignée'),
          if (u.niveau != null) _Info('Niveau dans le Cercle', u.niveau!.libelle),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(onPressed: () => _modifier(context, ref, u), icon: const Icon(Icons.edit_rounded), label: const Text('Modifier')),
          ),
        ]),
      ),
      lien(Icons.folder_rounded, 'Mes documents', "Pièces d'identité, contrats, reçus", () => context.push(Chemins.documents)),
      lien(Icons.settings_rounded, 'Paramètres', 'Notifications, sécurité, affichage', () => context.push(Chemins.parametres)),
      lien(Icons.support_agent_rounded, "Centre d'aide", 'Guides, WhatsApp, e-mail', () => context.push(Chemins.info(PagesId.aide))),
      const SizedBox(height: ArzikiEspaces.m),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(foregroundColor: ArzikiCouleurs.erreur, side: const BorderSide(color: ArzikiCouleurs.erreur)),
        onPressed: () async {
          if (await confirmer(context, titre: 'Se déconnecter ?', message: 'Vous devrez saisir à nouveau votre code pour vous reconnecter.', valider: 'Me déconnecter')) {
            await ref.read(sessionProvider.notifier).deconnecter();
            if (context.mounted) context.go(Chemins.choix);
          }
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Se déconnecter'),
      ),
    ]);
    if (integre) return corps;
    return Scaffold(appBar: AppBar(title: const Text('Mon profil')), body: corps);
  }

  void _modifier(BuildContext context, WidgetRef ref, Utilisateur u) {
    final prenom = TextEditingController(text: u.prenom);
    final nom = TextEditingController(text: u.nom);
    final ville = TextEditingController(text: u.ville ?? '');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(ArzikiEspaces.l, 0, ArzikiEspaces.l, MediaQuery.viewInsetsOf(ctx).bottom + ArzikiEspaces.l),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Mes informations', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(controller: prenom, decoration: const InputDecoration(labelText: 'Prénom')),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(controller: nom, decoration: const InputDecoration(labelText: 'Nom')),
          const SizedBox(height: ArzikiEspaces.m),
          TextField(controller: ville, decoration: const InputDecoration(labelText: 'Ville')),
          const SizedBox(height: ArzikiEspaces.l),
          FilledButton(
            onPressed: () {
              final maj = u.copier(prenom: prenom.text.trim(), nom: nom.text.trim(), ville: ville.text.trim());
              if (AppConfig.estDemo) ref.read(baseDemoProvider).utilisateurs[u.uid] = maj;
              ref.read(sessionProvider.notifier).connecter(maj);
              Navigator.pop(ctx);
              annoncer(context, 'Vos informations sont enregistrées.');
            },
            child: const Text('Enregistrer'),
          ),
        ]),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.libelle, this.valeur);
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(libelle, style: t.bodySmall)),
        Flexible(child: Text(valeur, style: t.titleSmall, textAlign: TextAlign.right)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Mes documents
// ---------------------------------------------------------------------------

class EcranDocuments extends ConsumerWidget {
  const EcranDocuments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(sessionProvider).utilisateur!;
    final t = Theme.of(context).textTheme;
    final pieces = piecesKyc(u.role);
    final fournies = u.kycStatut == StatutKyc.valide || u.kycStatut == StatutKyc.enCours;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes documents')),
      body: Colonne(children: [
        const EnTetePage('Mes documents', 'Vos pièces sont chiffrées et visibles uniquement par vous et l\'équipe de vérification.'),
        Row(children: [Text("Vérification d'identité", style: t.titleMedium), const Spacer(), badgeKyc(u.kycStatut)]),
        const SizedBox(height: ArzikiEspaces.s),
        if (pieces.isEmpty)
          const EcranVide(icone: Icons.folder_off_rounded, titre: 'Aucune pièce demandée', texte: 'Votre rôle ne nécessite pas de pièces justificatives.'),
        for (final p in pieces)
          CarteArziki(
            child: Row(children: [
              Icon(fournies ? Icons.check_circle_rounded : Icons.upload_file_rounded, color: fournies ? ArzikiCouleurs.vert : ArzikiCouleurs.orange),
              const SizedBox(width: ArzikiEspaces.m),
              Expanded(child: Text(p.libelle)),
              Text(fournies ? 'Déposé' : 'À déposer', style: t.labelMedium),
            ]),
          ),
        if (!fournies) ...[
          const SizedBox(height: ArzikiEspaces.s),
          FilledButton(onPressed: () => context.push(Chemins.identite), child: const Text('Déposer mes pièces')),
        ],
        const TitreSection('Contrats et reçus'),
        const EcranVide(
          icone: Icons.receipt_long_rounded,
          titre: 'Vos contrats et reçus apparaîtront ici',
          texte: 'Contrats de participation, attestations de fin d\'opération et reçus de paiement.',
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Paramètres
// ---------------------------------------------------------------------------

class EcranParametres extends ConsumerWidget {
  const EcranParametres({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(preferencesProvider);
    final ctrl = ref.read(preferencesProvider.notifier);
    final u = ref.watch(sessionProvider).utilisateur!;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: Colonne(children: [
        const EnTetePage('Paramètres', 'Choisissez vos notifications, sécurisez votre compte et adaptez l\'affichage.'),
        Text('Notifications', style: t.titleMedium),
        CarteArziki(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (final type in TypeNotification.values)
              SwitchListTile(
                value: p.notifications[type] ?? true,
                onChanged: (v) => ctrl.notification(type, v),
                title: Text(type.libelle),
                subtitle: Text(type.detail),
              ),
          ]),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        Text('Sécurité', style: t.titleMedium),
        CarteArziki(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.pin_rounded),
              title: const Text('Code PIN'),
              subtitle: Text(p.codePin == null ? "Non défini. Il protège l'ouverture de l'application et vos participations." : 'Défini'),
              trailing: TextButton(onPressed: () => _definirPin(context, ref), child: Text(p.codePin == null ? 'Définir' : 'Modifier')),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              value: p.empreinte,
              onChanged: p.codePin == null
                  ? null
                  : (v) {
                      ctrl.empreinte(v);
                      annoncer(context, v ? 'Empreinte activée sur ce téléphone.' : 'Empreinte désactivée.');
                    },
              title: const Text('Déverrouiller avec mon empreinte'),
              subtitle: const Text('Nécessite un code PIN.'),
            ),
          ]),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        Text('Affichage', style: t.titleMedium),
        CarteArziki(
          padding: EdgeInsets.zero,
          child: Column(children: [
            const ListTile(
              leading: Icon(Icons.language_rounded),
              title: Text('Langue'),
              subtitle: Text('Français. Anglais bientôt disponible.'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(ArzikiEspaces.m, 0, ArzikiEspaces.m, ArzikiEspaces.m),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Taille du texte', style: t.titleSmall),
                const SizedBox(height: ArzikiEspaces.s),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 1.0, label: Text('Normal')),
                    ButtonSegment(value: 1.15, label: Text('Grand')),
                    ButtonSegment(value: 1.3, label: Text('Très grand')),
                  ],
                  selected: {p.tailleTexte},
                  onSelectionChanged: (s) => ctrl.tailleTexte(s.first),
                ),
              ]),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_rounded),
              value: p.modeTheme == ThemeMode.dark,
              onChanged: ctrl.modeSombre,
              title: const Text('Mode sombre'),
            ),
          ]),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        Text('Mes données', style: t.titleMedium),
        CarteArziki(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Télécharger mes données'),
              subtitle: const Text('Une copie de vos informations personnelles.'),
              onTap: () => _exporter(context, u),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: ArzikiCouleurs.erreur),
              title: const Text('Supprimer mon compte', style: TextStyle(color: ArzikiCouleurs.erreur)),
              subtitle: const Text('Les contrats et justificatifs sont conservés pendant la durée légale.'),
              onTap: () async {
                if (await confirmer(
                  context,
                  titre: 'Supprimer votre compte ?',
                  message: 'Votre demande sera traitée sous 30 jours. Les contrats et justificatifs sont conservés pendant la durée imposée par la loi.',
                  valider: 'Demander la suppression',
                  danger: true,
                )) {
                  ref.read(baseDemoProvider).auditer(u.uid, 'demande_suppression_compte', 'users/${u.uid}');
                  if (context.mounted) annoncer(context, 'Demande de suppression enregistrée. Nous vous confirmerons par e-mail ou SMS.');
                }
              },
            ),
          ]),
        ),
        const SizedBox(height: ArzikiEspaces.m),
        Text('À propos', style: t.titleMedium),
        CarteArziki(
          padding: EdgeInsets.zero,
          child: Column(children: [
            const ListTile(leading: Icon(Icons.info_rounded), title: Text("Version de l'application"), trailing: Text(AppConfig.version)),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: const Text("Conditions d'utilisation"),
              onTap: () => context.push(Chemins.info(PagesId.cgu)),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_rounded),
              title: const Text('Politique de confidentialité'),
              onTap: () => context.push(Chemins.info(PagesId.confidentialite)),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: const Text('Mentions légales'),
              onTap: () => context.push(Chemins.info(PagesId.mentions)),
            ),
          ]),
        ),
        const SizedBox(height: ArzikiEspaces.s),
        Center(child: Text('Une offre de NEXUS International', style: t.labelMedium)),
      ]),
    );
  }

  void _definirPin(BuildContext context, WidgetRef ref) {
    final pin = TextEditingController();
    final confirmation = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Code PIN'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: pin, obscureText: true, maxLength: 4, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Nouveau code (4 chiffres)')),
          TextField(controller: confirmation, obscureText: true, maxLength: 4, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Confirmer le code')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              if (pin.text.length != 4 || pin.text != confirmation.text) {
                annoncer(ctx, 'Les deux codes doivent être identiques et comporter 4 chiffres.', erreur: true);
                return;
              }
              ref.read(preferencesProvider.notifier).definirPin(pin.text);
              Navigator.pop(ctx);
              annoncer(context, 'Code PIN enregistré.');
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _exporter(BuildContext context, Utilisateur u) {
    final donnees = const JsonEncoder.withIndent('  ').convert({
      'identifiant': u.uid,
      'prenom': u.prenom,
      'nom': u.nom,
      'telephone': u.telephone,
      'email': u.email,
      'ville': u.ville,
      'role': u.role.libelle,
      'statut': u.statut.libelle,
      'verification_identite': u.kycStatut.libelle,
      'conditions_acceptees': u.cgVersionAcceptee,
      'export_le': dateLongue(DateTime.now()),
    });
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mes données'),
        content: SingleChildScrollView(child: SelectableText(donnees, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: donnees));
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) annoncer(context, 'Données copiées.');
            },
            child: const Text('Copier'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
