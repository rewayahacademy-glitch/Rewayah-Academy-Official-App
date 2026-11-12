/// SALLE-2-ENTRETIEN (plan des trois salles, lot 3, 07/11/2026) : la page
/// « Faisons connaissance » du candidat, `/attente/entretien`.
///
/// - Entretien fixe (`mon_entretien()`) : sa date, heure de l'appareil, et
///   « Rejoindre l'entretien » des l'ouverture (10 minutes avant). Le bouton
///   ouvre la salle existante (`/salle`) sur la seance de l'entretien ; le
///   jeton vient du serveur seul (`autoriser_jeton_video`, retouche V1-a :
///   un compte en attente n'entre que dans SA seance d'entretien).
/// - Entretien a fixer (etat `entretien_a_planifier`) : les moments ouverts
///   et leur reservation ([ChoixCreneauEntretien]).
/// - Sinon : l'entretien n'est pas encore ouvert pour cette candidature.
///
/// Le candidat lit « Faisons connaissance », jamais un nom de salle.
///
/// Les cinq etats : chargement (squelette), contenu, vide (aucun moment
/// ouvert, ou entretien pas encore ouvert), erreur (« Reessayer »), hors
/// ligne (le bloc de ce qui manque, sous le bandeau de la coquille).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/entretien_candidat.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/billet_salle.dart';
import '../../core/router/routes.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/skeleton.dart';
import 'entretien_creneaux.dart';
import 'lecture_page.dart';

/// L'horloge de la page (surchargee par les tests).
final Provider<DateTime Function()> horlogeEntretienProvider =
    Provider<DateTime Function()>((Ref _) => DateTime.now);

/// La page « Faisons connaissance ».
class EntretienCandidatPage extends ConsumerWidget {
  /// Cree la page.
  const EntretienCandidatPage({super.key});

  /// La cle de la page.
  static const Key pageKey = ValueKey<String>('entretien-page');

  @override
  Widget build(BuildContext context, WidgetRef ref) => lecturePage<EtatDossier>(
    ref: ref,
    key: pageKey,
    titre: t.recrutement.entretien.titre,
    valeur: ref.watch(etatDossierProvider),
    titreEchec: t.recrutement.portail.nonCharge,
    onReessayer: () => ref.invalidate(etatDossierProvider),
    construire: (EtatDossier lu) {
      // Une adresse tapee sans candidature : le portail dit ou on en est.
      if (!lu.profilExiste || !lu.candidature.existe) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) GoRouter.of(context).go(Routes.attente);
        });
        return PageSimple(
          titre: t.recrutement.entretien.titre,
          corps: const Skeleton.liste(lignes: 3),
        );
      }
      return PageSimple(
        key: pageKey,
        titre: t.recrutement.entretien.titre,
        corps: ContenuEntretien(candidature: lu.candidature),
      );
    },
  );
}

/// Le contenu, selon ce que le serveur rend.
class ContenuEntretien extends ConsumerStatefulWidget {
  /// Cree le contenu.
  const ContenuEntretien({required this.candidature, super.key});

  /// La candidature lue dans le dossier.
  final CandidatureDossier candidature;

  /// La carte de l'entretien fixe.
  static const Key carteKey = ValueKey<String>('entretien-carte');

  /// « Rejoindre l'entretien ».
  static const Key rejoindreKey = ValueKey<String>('entretien-rejoindre');

  /// L'etat « pas encore ouvert ».
  static const Key pasEncoreKey = ValueKey<String>('entretien-pas-encore');

  /// L'etat d'erreur de lecture.
  static const Key erreurKey = ValueKey<String>('entretien-erreur');

  @override
  ConsumerState<ContenuEntretien> createState() => _ContenuEntretienEtat();
}

class _ContenuEntretienEtat extends ConsumerState<ContenuEntretien> {
  Timer? _minute;

  @override
  void initState() {
    super.initState();
    // L'ouverture arrive pendant que la page est ouverte : le bouton
    // apparait sans recharger.
    _minute = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minute?.cancel();
    super.dispose();
  }

  void _rejoindre(String seanceId) => GoRouter.of(context).go(
    Routes.salle,
    // Le billet passe par `extra`, jamais par l'URL (ADR-005).
    extra: BilletSalle(sessionId: seanceId, emisA: DateTime.now()),
  );

  @override
  Widget build(BuildContext context) {
    // HEURES-PROFIL H4 : se redessine quand le fuseau du profil arrive.
    ref.watch(monHorlogeProvider);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final AsyncValue<MonEntretien?> lecture = lectureHorsLigne(
      ref.watch(monEntretienProvider),
      horsLigne: horsLigne,
    );
    void relire() => ref.invalidate(monEntretienProvider);

    if (!lecture.hasValue) {
      if (lecture.hasError) {
        return sansDonneesHorsLigne(lecture, horsLigne: horsLigne)
            ? EtatSansDonnees(
                key: ContenuEntretien.erreurKey,
                quoi: t.recrutement.entretien.erreurLecture,
                onAction: relire,
              )
            : EtatSysteme(
                key: ContenuEntretien.erreurKey,
                nature: NatureEtat.echecServeur,
                phrase: t.recrutement.entretien.erreurLecture,
                libelleAction: t.commun.reessayer,
                onAction: relire,
              );
      }
      return const Skeleton.liste(lignes: 3);
    }

    final MonEntretien? entretien = lecture.requireValue;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final TextStyle corps = textes.bodyLarge ?? const TextStyle();
    final TextStyle muet = palette.inkMuted.applyTo(
      textes.bodyMedium ?? const TextStyle(),
    );

    if (entretien != null) {
      final DateTime maintenant = ref.watch(horlogeEntretienProvider)();
      final bool ouvert = entretien.ouvertA(maintenant);
      final bool passe = !maintenant.isBefore(entretien.fin);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppCard(
            key: ContenuEntretien.carteKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  t.recrutement.entretien.votreEntretien,
                  style: textes.titleMedium,
                ),
                Ecart.vSm,
                Text(
                  horaireEntretien(entretien.debut, entretien.fin),
                  style: corps,
                ),
                // HEURES-PROFIL H4 : la mention seulement quand l'appareil sert.
                if (estHeureDeLAppareil(entretien.debut)) ...<Widget>[
                  Ecart.vXs,
                  Text(t.recrutement.entretien.heureAppareil, style: muet),
                ],
              ],
            ),
          ),
          Ecart.vLg,
          if (ouvert)
            ActionPrincipale(
              key: ContenuEntretien.rejoindreKey,
              libelle: t.recrutement.entretien.rejoindre,
              onPress: () => _rejoindre(entretien.seanceId),
            )
          else
            Semantics(
              liveRegion: true,
              child: Text(
                passe
                    ? t.recrutement.entretien.termine
                    : t.recrutement.entretien.ouvreA(
                        heure: heureChezMoi(
                          entretien.ouvertureLe ?? entretien.debut,
                        ),
                      ),
                style: corps,
              ),
            ),
        ],
      );
    }

    if (widget.candidature.etat == EtatCandidature.entretienAPlanifier) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(t.recrutement.entretien.intro, style: corps),
          Ecart.vLg,
          ChoixCreneauEntretien(candidature: widget.candidature),
        ],
      );
    }

    return EtatSysteme(
      key: ContenuEntretien.pasEncoreKey,
      nature: NatureEtat.indisponible,
      phrase: t.recrutement.entretien.pasEncore,
    );
  }
}
