/// SUPPRIMER (garde-cap, 03/11/2026, PLAN-LOTS §12) : dans la fiche d'un
/// enfant du foyer, la ligne « Supprimer le profil de … ».
///
/// Le geste passe par une confirmation qui dit la consequence (plus de
/// connexion, les classes quittees, l'anonymisation a la fin du delai, la
/// direction qui peut le retrouver avant). Le serveur decide de tout
/// (`tuteur_supprimer_profil_enfant` : un enfant mineur du foyer seulement) ;
/// la ligne n'est posee que pour un profil cree par le foyer, jamais pour le
/// titulaire. Une fois le profil supprime, le foyer est relu et la page y
/// revient : le profil n'y est plus.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/appairage/service_appairage.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/capacites/port_retraits_comptes.dart';
import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/confirm_destructive.dart';
import '../../core/widgets/groupe_reglages.dart';

/// Le groupe « Supprimer le profil » de la fiche d'un enfant.
class SupprimerProfilEleve extends ConsumerStatefulWidget {
  /// Cree le groupe.
  const SupprimerProfilEleve({required this.profil, super.key, this.onAller});

  /// L'enfant.
  final ProfilEleveFoyer profil;

  /// Ouvre un chemin ; par defaut, le routeur.
  final void Function(String chemin)? onAller;

  /// La cle du groupe.
  static const Key cle = ValueKey<String>('ficheEleve.supprimer');

  /// La phrase qui dit pourquoi rien n'a ete supprime.
  static const Key messageKey = ValueKey<String>(
    'ficheEleve.supprimer.message',
  );

  @override
  ConsumerState<SupprimerProfilEleve> createState() =>
      _SupprimerProfilEleveState();
}

class _SupprimerProfilEleveState extends ConsumerState<SupprimerProfilEleve> {
  bool _enCours = false;
  String? _message;

  bool get _horsLigne => ref.read(horsLigneProvider).value ?? false;

  Future<void> _supprimer() async {
    if (_enCours) return;
    final s = t.ficheEleve.supprimer;
    final String prenom = widget.profil.prenom;
    final String dePrenom = deDevant(prenom);
    // SUPPRIMER-PRENOM (07/11/2026) : la feuille fait ecrire le prenom, et
    // son bouton ne porte pas le libelle de la ligne : deux appuis rapides ne
    // suppriment plus un enfant.
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: s.question(dePrenom: dePrenom),
      consequence: s.consequence,
      libelleConfirmer: s.confirmer(prenom: prenom),
      libelleAnnuler: s.rester,
      saisie: SaisieConfirmation(
        attendu: prenom,
        libelle: s.saisieLibelle(prenom: prenom),
        erreur: s.saisieErreur(prenom: prenom),
      ),
    );
    if (!oui || !mounted) return;
    if (_horsLigne) {
      setState(() => _message = s.horsLigne);
      return;
    }
    setState(() {
      _enCours = true;
      _message = null;
    });
    String? message;
    try {
      message = switch (await ref
          .read(portRetraitsComptesProvider)
          .supprimerProfilEnfant(widget.profil.eleveId)) {
        ResultatSuppressionEnfant.retire => null,
        ResultatSuppressionEnfant.horsFoyer => s.horsFoyer,
        ResultatSuppressionEnfant.dejaRetire => s.dejaRetire,
      };
    } on PermissionInsuffisante {
      message = s.refuse;
    } on CapaciteIndisponible {
      message = s.indisponible;
    } on Object {
      message = _horsLigne ? s.horsLigne : s.echec;
    }
    if (!mounted) return;
    if (message == null || message == s.dejaRetire) {
      // Le profil n'existe plus dans le foyer : relu, et la page y revient.
      ref.invalidate(elevesDuFoyerProvider);
      (widget.onAller ?? GoRouter.of(context).go)(Routes.tuteurFoyer);
      return;
    }
    setState(() {
      _enCours = false;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = t.ficheEleve.supprimer;
    // Ecoute l'etat du reseau : le geste le lit avant d'envoyer.
    ref.watch(horsLigneProvider);
    final String? message = _message;
    final AppPalette palette = AppPalette.of(context);
    return Column(
      key: SupprimerProfilEleve.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GroupeReglages(
          titre: s.groupe,
          lignes: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.toutEffacer,
              libelle: s.ligne(dePrenom: deDevant(widget.profil.prenom)),
              legende: s.legende,
              // Pendant l'envoi, la ligne ne repart pas.
              onPress: _enCours ? null : () => unawaited(_supprimer()),
            ),
          ],
        ),
        if (message != null) ...<Widget>[
          Ecart.vMd,
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: SupprimerProfilEleve.messageKey,
              style: palette.inkAlert.applyTo(
                Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
