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
/// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026) : lu par la lecture unique
/// `etape_eleve_lecture` ; le bloc montre aussi les matieres de l'etape, la
/// date d'entree dans l'etape, sa duree prevue et sa date limite en semaines,
/// la date limite de l'etape (depuis l'entree dans l'etape), l'horizon du
/// niveau et le chemin des etapes du niveau pour la tranche d'age de l'eleve,
/// la sienne mise en avant. En Interface guidee, ni date limite, ni horizon, ni
/// rythme, ni durees ; le serveur retient deja date limite, horizon et rythme
/// pour l'enfant de 6 a 9 ans qui lit pour lui-meme.
///
/// Le bloc n'est pas pose sans port ; sans etape (pas encore de classe), il dit
/// en une ligne que l'etape apparaitra a l'entree en classe ; chaque ligne se
/// cache quand sa donnee manque. Une lecture en echec le dit, avec « Reessayer » (K-59),
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
    final String? p = prenom;
    final Widget titre = SectionHeader(
      titre: p == null ? s.titreSoi : s.titre(prenom: p),
    );
    if (suivi == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          key: const ValueKey<String>('suivi-pedagogique-vide'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            titre,
            Ecart.vMd,
            GroupeReglages(
              lignes: <LigneRubrique>[
                LigneRubrique(
                  icone: AppIcons.coran,
                  libelle: s.etape,
                  legende: s.vide,
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Interface guidee (garde-cap, 07/11/2026 ; charte, partie 10) : l'enfant
    // voit son etape, ses objectifs, ses matieres, le chemin et l'endroit ou la
    // Classe s'est arretee ; ni le rythme, ni la date limite, ni les reperes,
    // que son tuteur lit dans son Historique.
    final bool guidee = AppMetriques.of(context).estEnfant;
    final String? rythme = guidee ? null : libelleRythme(suivi);
    final DateTime? date = guidee ? null : suivi.dateLimite;
    final DateTime? horizon = guidee ? null : suivi.horizon;
    final DateTime? entree = suivi.entreeLe;
    final String niveau = suivi.niveauNom ?? '';
    String jour(DateTime d) => LibellesGroupe.insecable(
      s.dateJour(
        numero: '${d.day}',
        mois: t.commun.dates.mois[d.month - 1],
        annee: '${d.year}',
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        key: const ValueKey<String>('suivi-pedagogique'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          titre,
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
              if (suivi.matierePrincipale case final String principale)
                LigneRubrique(
                  icone: AppIcons.livreOuvert,
                  libelle: s.matierePrincipale,
                  legende: principale,
                ),
              if (suivi.matiereSecondaire case final String secondaire)
                LigneRubrique(
                  icone: AppIcons.lecon,
                  libelle: s.matiereSecondaire,
                  legende: secondaire,
                ),
              if (entree != null)
                LigneRubrique(
                  icone: AppIcons.historique,
                  libelle: s.depuis,
                  legende: jour(entree),
                ),
              if (!guidee && suivi.dureePrevueSemaines != null)
                LigneRubrique(
                  icone: AppIcons.attente,
                  libelle: s.dureePrevue,
                  legende: LibellesGroupe.insecable(
                    s.dureesEtape(
                      prevue: '${suivi.dureePrevueSemaines}',
                      limite:
                          '${suivi.dateLimiteSemaines ?? suivi.dureePrevueSemaines}',
                    ),
                  ),
                ),
              if (date != null)
                LigneRubrique(
                  icone: AppIcons.journee,
                  libelle: s.aFinirAvant,
                  legende: jour(date),
                ),
              if (horizon != null && niveau.isNotEmpty)
                LigneRubrique(
                  icone: AppIcons.echeance,
                  libelle: s.horizonNiveau(niveau: niveau),
                  legende: jour(horizon),
                ),
              if (rythme != null)
                LigneRubrique(
                  icone: AppIcons.horloge,
                  libelle: s.rythme,
                  legende: rythme,
                ),
            ],
          ),
          if (suivi.chemin.isNotEmpty) ...<Widget>[
            Ecart.vLg,
            SectionHeader(
              key: const ValueKey<String>('suivi-pedagogique-chemin'),
              titre: niveau.isEmpty ? s.etape : s.chemin(niveau: niveau),
            ),
            Ecart.vMd,
            GroupeReglages(
              lignes: <LigneRubrique>[
                for (final EtapeDuChemin e in suivi.chemin)
                  LigneRubrique(
                    icone: switch (e.statut) {
                      StatutEtape.franchie => AppIcons.succes,
                      StatutEtape.enCours => AppIcons.signet,
                      StatutEtape.aVenir => AppIcons.attente,
                    },
                    libelle: s.etapeNumero(ordre: '${e.ordre}', nom: e.nom),
                    legende: <String>[
                      switch (e.statut) {
                        StatutEtape.franchie => s.statutValidee,
                        StatutEtape.enCours => s.statutEnCours,
                        StatutEtape.aVenir => s.statutAVenir,
                      },
                      if (!guidee &&
                          e.dureePrevueSemaines != null &&
                          e.dateLimiteSemaines != null)
                        LibellesGroupe.insecable(
                          s.dureesEtape(
                            prevue: '${e.dureePrevueSemaines}',
                            limite: '${e.dateLimiteSemaines}',
                          ),
                        ),
                      ...e.objectifs,
                    ].join('\n'),
                  ),
              ],
            ),
          ],
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
