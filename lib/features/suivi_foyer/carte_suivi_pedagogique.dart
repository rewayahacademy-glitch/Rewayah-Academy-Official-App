/// SUIVI-ELEVE (07/11/2026) : « Où j'en suis » dans le Suivi de l'eleve, et
/// « Où en est `prénom` » en tete de l'Historique du tuteur, pour l'enfant
/// choisi.
///
/// L'etape en cours et ses objectifs, l'endroit ou la Classe s'est arretee
/// (derniere page presentee, CAHIER-C1), la date limite et le rythme. Tout
/// vient du serveur (`suivi_pedagogique_eleve`) ; la vitesse est calculee en
/// base, jamais ici. Aucune saisie : ce sont les donnees deja posees par la
/// salle et le programme.
///
/// En Interface guidee, ni le rythme ni la date limite (garde-cap, 07/11) :
/// la situation face a l'echeance est l'affaire du tuteur.
///
/// Le bloc n'est pas pose sans port, sans Classe active ou sans etape publiee
/// (l'etat vide de la page couvre ce cas) ; chaque ligne se cache quand sa
/// donnee manque. Une lecture en echec le dit, avec « Reessayer » (K-59),
/// hors ligne compris ; pendant la lecture, un squelette tient la place.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/suivi/port_suivi_pedagogique.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';

/// Le bloc, ou rien.
class CarteSuiviPedagogique extends ConsumerWidget {
  /// Cree le bloc pour [eleveId] et [prenom] (le tuteur, l'enfant choisi),
  /// ou, sans eux, pour l'eleve connecte qui lit pour lui-meme.
  const CarteSuiviPedagogique({this.eleveId, this.prenom, super.key});

  /// L'eleve concerne ; nul : la personne connectee (son profil eleve).
  final String? eleveId;

  /// Le prenom de l'enfant, ou nul quand l'eleve lit pour lui-meme.
  final String? prenom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(portSuiviPedagogiqueProvider) == null) {
      return const SizedBox.shrink();
    }
    final String? eleveId =
        this.eleveId ?? ref.watch(sessionProvider).profileId;
    if (eleveId == null) return const SizedBox.shrink();
    final s = t.suiviPedagogique;
    final AsyncValue<SuiviPedagogique?> lecture = ref.watch(
      suiviPedagogiqueProvider(eleveId),
    );
    if (lecture.hasError && !lecture.hasValue) {
      // EA-HL-DOUBLE-1 : hors ligne, le bandeau de la page le dit ; le bloc
      // dit seulement ce qui manque.
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      void relire() => ref.invalidate(suiviPedagogiqueProvider(eleveId));
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: horsLigne
            ? EtatSansDonnees(
                key: const ValueKey<String>('suivi-pedagogique-erreur'),
                quoi: s.erreur,
                onAction: relire,
              )
            : EtatSysteme(
                key: const ValueKey<String>('suivi-pedagogique-erreur'),
                nature: NatureEtat.echecServeur,
                phrase: s.erreur,
                libelleAction: t.commun.reessayer,
                onAction: relire,
              ),
      );
    }
    if (!lecture.hasValue) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.xl),
        child: Skeleton.liste(
          key: ValueKey<String>('suivi-pedagogique-chargement'),
          lignes: 3,
        ),
      );
    }
    final SuiviPedagogique? suivi = lecture.value;
    if (suivi == null) return const SizedBox.shrink();

    final String? p = prenom;
    // Interface guidee (garde-cap, 07/11/2026) : l'enfant voit son etape, ses
    // objectifs et l'endroit ou la Classe s'est arretee ; ni le rythme ni la
    // date limite, que son tuteur lit dans son Historique.
    final bool guidee = AppMetriques.of(context).estEnfant;
    final String? rythme = guidee ? null : libelleRythme(suivi);
    final DateTime? date = guidee ? null : suivi.dateLimite;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        key: const ValueKey<String>('suivi-pedagogique'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(titre: p == null ? s.titreSoi : s.titre(prenom: p)),
          Ecart.vMd,
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                icone: AppIcons.coran,
                libelle: s.etape,
                legende: suivi.etapeNom,
              ),
              if (suivi.pageReprise case final int page)
                LigneRubrique(
                  icone: AppIcons.signet,
                  libelle: s.reprise,
                  legende: s.reprisePage(page: '$page'),
                ),
              if (suivi.objectifs.isNotEmpty)
                LigneRubrique(
                  icone: AppIcons.marqueur,
                  libelle: s.objectifs,
                  legende: suivi.objectifs.join('\n'),
                ),
              if (date != null)
                LigneRubrique(
                  icone: AppIcons.journee,
                  libelle: s.aFinirAvant,
                  legende: LibellesGroupe.insecable(
                    s.aFinirAvantDate(
                      numero: '${date.day}',
                      mois: t.commun.dates.mois[date.month - 1],
                      annee: '${date.year}',
                      prevue: '${suivi.dureePrevueSemaines ?? ''}',
                    ),
                  ),
                ),
              if (rythme != null)
                LigneRubrique(
                  icone: AppIcons.horloge,
                  libelle: s.rythme,
                  legende: rythme,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Le libelle du rythme rendu par le serveur ; nul quand il est inconnu (la
/// ligne se cache). Pure.
String? libelleRythme(SuiviPedagogique suivi) {
  final s = t.suiviPedagogique;
  final int ecoulees = suivi.semainesEcoulees ?? 0;
  final String prevue = '${suivi.dureePrevueSemaines ?? ''}';
  return switch (suivi.rythme) {
    Rythme.dansLesTemps => s.dansLesTemps(ecoulees: ecoulees, prevue: prevue),
    Rythme.auDelaDuPrevu => s.auDelaDuPrevu(ecoulees: ecoulees, prevue: prevue),
    Rythme.dateLimiteDepassee => s.dateLimiteDepassee,
    Rythme.inconnu => null,
  };
}
