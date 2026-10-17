/// L2-05 : « Offres vitrine », la liste d'administration des offres.
///
/// Decision du directeur du 09/10/2026 (`DECISION-OFFRES-GROUPES-2026-10-09.md`
/// §1) : l'administration cree a l'avance les creneaux de la vitrine et **seule
/// elle publie**. Cet ecran liste les offres (brouillon, publiee, retiree),
/// ouvre la creation (`NouvelleOffrePage`), publie un brouillon et retire une
/// offre avec un motif. Il ne montre aucun enseignant ni aucun nombre
/// d'inscrits : la vitrine n'en a pas.
///
/// L'ecran lit le port, jamais un role : la garde d'acces est celle des pages
/// de la section Operations, et le serveur refuse tout compte qui n'est pas
/// administrateur.
///
/// Un seul bouton plein, « Nouvelle offre » (K-56) ; les actions de carte sont
/// secondaires.
///
/// Etats : chargement (`Skeleton`), contenu, vide (`EmptyState`), erreur
/// (`EtatSysteme`, « Reessayer »), hors ligne (bandeau de `PageShell` ;
/// `EtatSansDonnees` si rien n'a pu etre lu).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/port_offres_admin.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/skeleton.dart';
import 'carte_offre.dart';
import 'feuille_retrait_offre.dart';
import 'nouvelle_offre_page.dart';

/// L'ecran des offres vitrine.
class AdminOffresPage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const AdminOffresPage({super.key});

  @override
  ConsumerState<AdminOffresPage> createState() => _AdminOffresPageEtat();
}

class _AdminOffresPageEtat extends ConsumerState<AdminOffresPage> {
  /// Ce que la derniere action a donne (reussite ou refus), lu des qu'il
  /// parait.
  String? _message;

  /// L'offre dont une publication est en cours : un seul envoi a la fois.
  String? _enCours;

  void _relire() => ref.invalidate(offresAdminProvider);

  Future<void> _creer() async {
    final bool? creee = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext _) => const NouvelleOffrePage(),
      ),
    );
    if (!mounted || creee != true) return;
    _relire();
    setState(() => _message = t.admin.offres.creee);
  }

  Future<void> _publier(OffreAdmin offre) async {
    if (_enCours != null) return;
    setState(() {
      _enCours = offre.id;
      _message = null;
    });
    String message;
    try {
      await ref.read(portOffresAdminProvider).publier(offre.id);
      message = t.admin.offres.publiee;
    } on OffreAdminRefusee catch (e) {
      message = t.admin.offres.refusee(motif: e.message);
    } on Object {
      message = t.admin.offres.nonConfirmee;
    }
    if (!mounted) return;
    _relire();
    setState(() {
      _enCours = null;
      _message = message;
    });
  }

  Future<void> _retirer(OffreAdmin offre) async {
    final bool? retiree = await AppBottomSheet.ouvrir<bool>(
      context,
      titre: t.admin.offres.retraitTitre,
      constructeur: (BuildContext _) => FeuilleRetraitOffre(offre: offre),
    );
    if (!mounted || retiree != true) return;
    _relire();
    setState(() => _message = t.admin.offres.retiree);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<OffreAdmin>> valeur = ref.watch(offresAdminProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final o = t.admin.offres;

    return PageShell(
      titre: o.titre,
      sousTitre: o.sousTitre,
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Sous le titre et non a cote : a 320 px en texte double, un
              // bouton dans l'en-tete ecrasait le titre jusqu'a couper ses mots.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ActionPrincipale(
                  key: const ValueKey<String>('offres-nouvelle'),
                  libelle: o.nouvelle,
                  pleineLargeur: false,
                  onPress: () => unawaited(_creer()),
                ),
              ),
              Ecart.vXl,
              if (_message != null) ...<Widget>[
                Semantics(
                  liveRegion: true,
                  child: TexteSansCoupure(
                    _message!,
                    key: const ValueKey<String>('offres-message'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Ecart.vLg,
              ],
              if (horsLigne && valeur.hasValue) ...<Widget>[
                TexteSansCoupure(
                  o.horsLigneAction,
                  key: const ValueKey<String>('offres-hors-ligne'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Ecart.vLg,
              ],
              BlocAsynchrone<List<OffreAdmin>>(
                key: const ValueKey<String>('offres-bloc'),
                valeur: valeur,
                squelette: const Skeleton.liste(lignes: 3),
                onReessayer: _relire,
                estVide: (List<OffreAdmin> l) => l.isEmpty,
                vide: EmptyState(
                  key: const ValueKey<String>('offres-vide'),
                  message: o.vide,
                  icone: AppIcons.classes,
                ),
                erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
                    horsLigne
                    ? EtatSansDonnees(
                        key: const ValueKey<String>('offres-sans-donnees'),
                        quoi: o.sansDonnees,
                        onAction: reessayer,
                      )
                    : EtatSysteme(
                        key: const ValueKey<String>('offres-erreur'),
                        nature: NatureEtat.echecServeur,
                        phrase: o.erreur,
                        onAction: reessayer,
                      ),
                construire: (List<OffreAdmin> offres) => PileCartes(
                  key: const ValueKey<String>('offres-contenu'),
                  children: <Widget>[
                    for (final OffreAdmin offre in offres)
                      CarteOffre(
                        offre: offre,
                        onPublier:
                            !horsLigne &&
                                _enCours == null &&
                                offre.etat == EtatOffreAdmin.brouillon
                            ? () => unawaited(_publier(offre))
                            : null,
                        onRetirer:
                            !horsLigne &&
                                _enCours == null &&
                                offre.etat != EtatOffreAdmin.retiree
                            ? () => unawaited(_retirer(offre))
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
