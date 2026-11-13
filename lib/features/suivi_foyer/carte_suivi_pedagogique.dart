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
/// SOCLE-PROGRAMME (lot 1 de la charte, 12/11/2026) : lu par la lecture unique
/// `etape_eleve_lecture` ; le bloc montre aussi les matieres de l'etape, la
/// date d'entree dans l'etape, sa duree prevue et sa date limite en semaines,
/// la date limite de l'etape (depuis l'entree dans l'etape), l'horizon du
/// niveau et le chemin des etapes du niveau pour la tranche d'age de l'eleve,
/// la sienne mise en avant. Dans l'espace de l'eleve, dates, durees et rythme
/// seulement si le serveur dit `eleve_voit_dates` (des 10 ans, ou adulte) ;
/// le serveur retient deja ces valeurs pour l'enfant de 6 a 9 ans qui lit avec
/// son propre compte. Chez le tuteur, toujours.
///
/// Le bloc n'est pas pose sans port ; sans etape (pas encore de classe), il dit
/// en une ligne que l'etape apparaitra a l'entree en classe ; chaque ligne se
/// cache quand sa donnee manque. Une lecture en echec le dit, avec « Reessayer » (K-59),
/// hors ligne compris ; pendant la lecture, un squelette tient la place.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/port_progression_famille.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/session/session_controleur.dart';
import '../../core/suivi/ma_progression.dart';
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
    if (ref.watch(portMaProgressionProvider) == null) {
      return const SizedBox.shrink();
    }
    final String? eleveId =
        this.eleveId ?? ref.watch(sessionProvider).profileId;
    if (eleveId == null) return const SizedBox.shrink();
    final s = t.suiviPedagogique;
    final AsyncValue<MaProgression?> lecture = ref.watch(
      maProgressionProvider(eleveId),
    );
    if (lecture.hasError && !lecture.hasValue) {
      // EA-HL-DOUBLE-1 : hors ligne, le bandeau de la page le dit ; le bloc
      // dit seulement ce qui manque.
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      void relire() => ref.invalidate(maProgressionProvider(eleveId));
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
    // Ce que l'enseignant a saisi et que la famille lisait deja : le niveau
    // declare et le dernier jalon publie. Un refus ou un echec le cache, sans
    // faire tomber le bloc.
    final ProgressionEleve? famille = ref
        .watch(progressionFamilleLueProvider(eleveId))
        .value;
    final String? jalon = famille?.jalons.isEmpty ?? true
        ? null
        : famille!.jalons.first;
    final String? niveauDeclare =
        famille?.niveauHumain?.trim().isNotEmpty ?? false
        ? famille!.niveauHumain!.trim()
        : null;
    final MaProgression? lue = lecture.value;
    if (lue == null && jalon == null && niveauDeclare == null) {
      return const SizedBox.shrink();
    }
    final MaProgression progression = lue ?? const MaProgression();
    final SuiviPedagogique? suivi = progression.suivi;
    final bool attente = suivi?.enAttenteEntretien ?? false;

    final String? p = prenom;
    final Widget titre = SectionHeader(
      titre: p == null ? s.titreSoi : s.titre(prenom: p),
    );
    // SOCLE-PROGRAMME : un eleve qui a declare savoir lire n'a pas d'etape
    // supposee ; il attend l'entretien de lecture avec la direction.
    final String phraseAttente = p != null
        ? s.attenteEntretienPour(prenom: p)
        : (AppMetriques.of(context).estEnfant
              ? s.attenteEntretienTu
              : s.attenteEntretien);

    // Qui voit les dates (correction de l'architecte, 12/11 ; refus par defaut,
    // 13/11) : le mode d'interface ne decide rien quand le serveur parle. Dans
    // l'espace de l'eleve (eleveId nul : il lit pour lui-meme), dates, durees et
    // rythme seulement si le serveur dit `eleve_voit_dates` (des 10 ans, ou
    // adulte, meme en Interface guidee) ; un drapeau absent vaut FAUX, quelle que
    // soit la presentation. Dans les ecrans de l'adulte responsable (eleveId
    // donne : tuteur), toujours quand le serveur parle ; une reponse d'avant le
    // socle, qui ne le dit pas, garde la regle d'avant (Interface guidee : ni
    // rythme ni date limite ni reglage).
    final bool guidee = AppMetriques.of(context).estEnfant;
    final bool? serveurDit = suivi?.eleveVoitDates;
    final bool dates = this.eleveId == null
        ? (serveurDit ?? false)
        : (serveurDit == null ? !guidee : true);
    final String? rythme = suivi == null || attente || !dates
        ? null
        : libelleRythme(suivi);
    final DateTime? date = dates && !attente ? suivi?.dateLimite : null;
    final DateTime? horizon = dates && !attente ? suivi?.horizon : null;
    // Aucune date, la date d'entree comprise, quand l'eleve ne voit pas ses
    // dates (charte : l'enfant de 6 a 9 ans ne recoit aucune date).
    final DateTime? entree = dates && !attente ? suivi?.entreeLe : null;
    final String niveau = suivi?.niveauNom ?? '';
    final ReglageEtape? reglage = dates && !attente
        ? progression.reglage
        : null;
    final SouratesValidees? sourates = progression.sourates;
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
              if (suivi != null)
                LigneRubrique(
                  icone: AppIcons.coran,
                  libelle: s.etape,
                  legende: attente ? phraseAttente : suivi.etapeNom,
                ),
              if (sourates != null)
                LigneRubrique(
                  cle: const ValueKey<String>('suivi-pedagogique-sourates'),
                  icone: AppIcons.coran,
                  libelle: s.sourates,
                  legende: s.souratesDe(
                    validees: sourates.validees,
                    total: sourates.total,
                  ),
                ),
              // Sans etape publiee, le niveau declare tient lieu de niveau ;
              // avec une etape, c'est elle qui le dit.
              if (suivi == null && niveauDeclare != null)
                LigneRubrique(
                  cle: const ValueKey<String>('suivi-pedagogique-niveau'),
                  icone: AppIcons.coran,
                  libelle: s.niveauDeclare,
                  legende: niveauDeclare,
                ),
              if (jalon != null)
                LigneRubrique(
                  cle: const ValueKey<String>('suivi-pedagogique-jalon'),
                  icone: AppIcons.signet,
                  libelle: s.dernierJalon,
                  legende: LibellesGroupe.joindre(
                    jalon,
                    // Aucune date pour l'enfant de 6 a 9 ans qui lit pour lui-meme.
                    !dates || famille?.dernierJalonLe == null
                        ? null
                        : _jour(famille!.dernierJalonLe!.toLocal()),
                  ),
                ),
              if (!attente)
                if (suivi?.pageReprise case final int page)
                  LigneRubrique(
                    icone: AppIcons.signet,
                    libelle: s.reprise,
                    legende: s.reprisePage(page: '$page'),
                  ),
              if (suivi != null && !attente && suivi.objectifs.isNotEmpty)
                LigneRubrique(
                  icone: AppIcons.marqueur,
                  libelle: s.objectifs,
                  legende: suivi.objectifs.join('\n'),
                ),
              if (suivi != null && !attente)
                if (suivi.matierePrincipale case final String principale)
                  LigneRubrique(
                    icone: AppIcons.livreOuvert,
                    libelle: s.matierePrincipale,
                    legende: principale,
                  ),
              if (suivi != null && !attente)
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
              if (suivi != null &&
                  !attente &&
                  dates &&
                  suivi.dureePrevueSemaines != null &&
                  suivi.dateLimiteSemaines != null)
                LigneRubrique(
                  icone: AppIcons.attente,
                  libelle: s.dureePrevue,
                  legende: LibellesGroupe.insecable(
                    s.dureesEtape(
                      prevue: '${suivi.dureePrevueSemaines}',
                      limite: '${suivi.dateLimiteSemaines}',
                    ),
                  ),
                ),
              if (date != null && suivi != null)
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
              // Le reglage de la direction : rien tant qu'elle n'a rien rempli.
              if (reglage?.heuresRevisionSemaine case final double heures)
                LigneRubrique(
                  cle: const ValueKey<String>('suivi-pedagogique-revision'),
                  icone: AppIcons.horloge,
                  libelle: s.revision,
                  legende: LibellesGroupe.insecable(
                    s.revisionHeures(heures: _decimal(heures)),
                  ),
                ),
              if (reglage?.repetitionsEstimees case final int n)
                LigneRubrique(
                  cle: const ValueKey<String>('suivi-pedagogique-repetitions'),
                  icone: AppIcons.marqueur,
                  libelle: s.repetitions,
                  legende: s.repetitionsNombre(n: n),
                ),
            ],
          ),
          // Ou il etait, ou il est, ou il va : les etapes du niveau dans l'ordre,
          // chacune avec ses objectifs et, si l'eleve voit ses dates, sa duree.
          if (progression.cycle.isNotEmpty && !attente) ...<Widget>[
            Ecart.vXl,
            SectionHeader(
              key: const ValueKey<String>('suivi-pedagogique-chemin'),
              titre: niveau.isEmpty ? s.etapesTitre : s.chemin(niveau: niveau),
            ),
            Ecart.vMd,
            GroupeReglages(
              lignes: <LigneRubrique>[
                for (final EtapeDuCycle e in progression.cycle)
                  LigneRubrique(
                    cle: ValueKey<String>('suivi-pedagogique-etape-${e.ordre}'),
                    icone: switch (e.statut) {
                      StatutEtape.franchie => AppIcons.succes,
                      StatutEtape.enCours => AppIcons.pointeur,
                      StatutEtape.aVenir => AppIcons.attente,
                    },
                    libelle: e.nom,
                    legende: <String>[
                      libelleStatutEtape(e, avecDate: dates),
                      if (dates &&
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

/// Le statut d'une etape du cycle, en une phrase ; la date d'entree n'est
/// dite que pour une etape franchie dont le serveur la donne. Pure.
String libelleStatutEtape(EtapeDuCycle e, {bool avecDate = true}) {
  final s = t.suiviPedagogique;
  final DateTime? le = e.atteinteLe?.toLocal();
  return switch (e.statut) {
    StatutEtape.franchie =>
      le == null || !avecDate
          ? s.etapeFranchie
          : s.etapeFranchieLe(
              numero: '${le.day}',
              mois: t.commun.dates.mois[le.month - 1],
              annee: '${le.year}',
            ),
    StatutEtape.enCours => s.etapeEnCours,
    StatutEtape.aVenir => s.etapeAVenir,
  };
}

/// Un jour ecrit en toutes lettres : « 7 septembre 2026 ». Pur.
String _jour(DateTime d) =>
    '${d.day} ${t.commun.dates.mois[d.month - 1]} ${d.year}';

/// Un nombre d'heures ecrit comme on le lit : « 2 » ou « 2,5 » (virgule en
/// francais). Pur.
String _decimal(double v) {
  final String brut = v == v.roundToDouble()
      ? '${v.toInt()}'
      : v.toStringAsFixed(1);
  return LocaleSettings.currentLocale == AppLocale.ar
      ? brut.replaceAll('.', '\u066B')
      : brut.replaceAll('.', ',');
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
