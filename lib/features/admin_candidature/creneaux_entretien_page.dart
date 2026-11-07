/// SALLE-2-ENTRETIEN (07/11/2026) : les creneaux d'entretien de la direction,
/// `/admin/personnes/candidatures/creneaux`, sur V1-b (en production, jamais
/// appele jusqu'ici) : la liste des 30 prochains jours, « Ouvrir un
/// creneau », « Retirer ce creneau » (un creneau libre).
///
/// Le serveur decide de tout : la portee de genre, la regle des fondateurs,
/// les bornes du debut et de la duree, les langues. Ses refus sont dits avec
/// les mots de l'entretien quand il les connait deja.
///
/// La page defile seule (DECISION-DEFILEMENT) : aucune liste dans un cadre de
/// hauteur fixe.
///
/// Etats : chargement (squelette), contenu, vide (« Ouvrir un creneau »),
/// erreur (« Reessayer »), hors ligne (la derniere lecture reste ; rien lu :
/// le bloc de ce qui manque ; aucun geste), capacite indisponible, acces
/// refuse.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/creneaux_direction.dart';
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../candidature/entretien_creneaux.dart' show horaireEntretien;
import '../candidature/libelles_parcours.dart' show nomDeLangue;
import 'feuilles_creneau.dart';

/// La page des creneaux.
class CreneauxEntretienPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const CreneauxEntretienPage({super.key});

  /// La cle de la page.
  static const Key clePage = ValueKey<String>('creneaux-page');

  /// « Ouvrir un creneau ».
  static const Key ouvrirKey = ValueKey<String>('creneaux-ouvrir');

  @override
  ConsumerState<CreneauxEntretienPage> createState() => _EtatPage();
}

class _EtatPage extends ConsumerState<CreneauxEntretienPage> {
  String? _retour;

  void _fait(String? m) {
    if (m == null || !mounted) return;
    ref.invalidate(creneauxDirectionProvider);
    setState(() => _retour = m);
  }

  Future<void> _ouvrir() async => _fait(
    await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.admin.candidatures.creneaux.ouvrir,
      constructeur: (BuildContext contexte) => FeuilleOuvrirCreneau(
        onFini: (String m) => Navigator.of(contexte).pop(m),
        onAnnuler: () => Navigator.of(contexte).pop(),
      ),
    ),
  );

  Future<void> _retirer(CreneauDirection c) async => _fait(
    await AppBottomSheet.ouvrir<String>(
      context,
      titre: t.admin.candidatures.creneaux.retirer,
      constructeur: (BuildContext contexte) => FeuilleRetirerCreneau(
        creneau: c,
        onFini: (String m) => Navigator.of(contexte).pop(m),
        onAnnuler: () => Navigator.of(contexte).pop(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = t.admin.candidatures.creneaux;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<List<CreneauDirection>> lecture = ref.watch(
      creneauxDirectionProvider,
    );
    final bool gestes = !horsLigne && lecture.hasValue;
    return PageShell(
      key: CreneauxEntretienPage.clePage,
      titre: c.titre,
      onRetour: () =>
          GoRouter.of(context).go(Routes.adminPersonnesCandidatures),
      // Une colonne de lecture (garde bureau B4) : les cartes et les
      // phrases ne s'etirent pas sur toute la largeur d'un ordinateur.
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // L'explication defile avec la liste (garde bureau B6 : la tete
              // fixe reste courte).
              TexteSansCoupure(
                c.intro,
                style: AppPalette.of(context).inkMuted.applyTo(
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                ),
              ),
              Ecart.vLg,
              if (_retour != null) ...<Widget>[
                LocalFeedback(
                  key: const ValueKey<String>('creneaux-retour'),
                  message: _retour!,
                ),
                Ecart.vLg,
              ],
              if (gestes && (lecture.value?.isNotEmpty ?? false)) ...<Widget>[
                ActionPrincipale(
                  key: CreneauxEntretienPage.ouvrirKey,
                  libelle: c.ouvrir,
                  onPress: () => unawaited(_ouvrir()),
                ),
                Ecart.vLg,
              ],
              BlocAsynchrone<List<CreneauDirection>>(
                key: const ValueKey<String>('creneaux-bloc'),
                valeur: lecture,
                squelette: const Skeleton.liste(lignes: 4),
                onReessayer: () => ref.invalidate(creneauxDirectionProvider),
                estVide: (List<CreneauDirection> l) => l.isEmpty,
                vide: EmptyState(
                  key: const ValueKey<String>('creneaux-vide'),
                  message: c.aucun,
                  invitation: c.aucunInvitation,
                  libelleAction: gestes ? c.ouvrir : null,
                  onAction: gestes ? () => unawaited(_ouvrir()) : null,
                ),
                erreurVersEtat: (Object e, VoidCallback? reessayer) {
                  if (e is CapaciteIndisponible) {
                    return EtatSysteme(
                      key: const ValueKey<String>('creneaux-indisponible'),
                      nature: NatureEtat.indisponible,
                      titre: t.commun.etats.branchementServeur,
                      phrase: '',
                      dependance: e.dependance,
                    );
                  }
                  if (e is PermissionInsuffisante) {
                    return EtatSysteme(
                      key: const ValueKey<String>('creneaux-refus'),
                      nature: NatureEtat.echecServeur,
                      phrase: t.admin.candidatures.erreurs.permission,
                    );
                  }
                  return horsLigne
                      ? EtatSansDonnees(
                          key: const ValueKey<String>('creneaux-sans-donnees'),
                          quoi: c.sansDonnees,
                          onAction: reessayer,
                        )
                      : EtatSysteme(
                          key: const ValueKey<String>('creneaux-erreur'),
                          nature: NatureEtat.echecServeur,
                          phrase: c.lectureEchec,
                          onAction: reessayer,
                        );
                },
                construire: (List<CreneauDirection> liste) => Column(
                  key: const ValueKey<String>('creneaux-liste'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final CreneauDirection cr in liste) ...<Widget>[
                      CarteCreneau(
                        creneau: cr,
                        onRetirer: gestes && cr.etat == EtatCreneau.libre
                            ? () => unawaited(_retirer(cr))
                            : null,
                      ),
                      Ecart.vLg,
                    ],
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

/// Un creneau : le moment, l'etat, le cote, les langues, les personnes.
class CarteCreneau extends StatelessWidget {
  /// Cree la carte.
  const CarteCreneau({required this.creneau, this.onRetirer, super.key});

  /// Le creneau.
  final CreneauDirection creneau;

  /// « Retirer ce creneau » ; nul : pas de geste.
  final VoidCallback? onRetirer;

  @override
  Widget build(BuildContext context) {
    final c = t.admin.candidatures.creneaux;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final String etat = switch (creneau.etat) {
      EtatCreneau.libre => c.libre,
      EtatCreneau.reserve => c.reserve,
      EtatCreneau.annule => c.retire,
    };
    final String cote = creneau.cote == 'female' ? c.coteFemmes : c.coteHommes;
    final String langues = <String>[
      for (final String l in creneau.langues) nomDeLangue(l) ?? l,
    ].join(', ');
    TextStyle? muet(TextStyle? s) =>
        s == null ? null : palette.inkMuted.applyTo(s);
    return AppCard(
      key: ValueKey<String>('creneau-${creneau.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TexteSansCoupure(
            horaireEntretien(creneau.debut, creneau.fin),
            style: textes.titleMedium,
          ),
          Ecart.vXs,
          TexteSansCoupure('$etat · $cote', style: textes.bodyMedium),
          Ecart.vXs,
          TexteSansCoupure(langues, style: muet(textes.bodyMedium)),
          Ecart.vXs,
          TexteSansCoupure(
            LibellesGroupe.insecable(
              c.participants(n: '${creneau.participants}'),
            ),
            style: muet(textes.bodyMedium),
          ),
          if (creneau.fondateurs > 0)
            TexteSansCoupure(
              LibellesGroupe.insecable(
                c.fondateurs(n: '${creneau.fondateurs}'),
              ),
              style: muet(textes.bodyMedium),
            ),
          if (onRetirer != null) ...<Widget>[
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LienFleche(
                key: ValueKey<String>('creneau-retirer-${creneau.id}'),
                libelle: c.retirer,
                fleche: false,
                onPress: onRetirer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
