// MA-6 : apres la seance, pour l'eleve en Mode Accessibilite (doc 06 §6,
// MA21, planche 2 rectifiee).
//
// Dans l'ordre (UX_REVIEW ligne 9) : le resultat (« La seance est
// terminee. ») et la prochaine action, seul bouton dominant (« Retour a la
// Classe ») ; le travail pour la prochaine fois (3 au plus) ; « Revoir le
// support du cours » ; la prochaine seance ; « Besoin d'aide ? » en dernier
// (MA14). Retires : « Tres bien ! », confettis, « Message de votre
// enseignante » (Q8, BR-1). Aucune couleur nouvelle (K-37), aucun serveur.
//
// MA-APRES-1 (decision A7 = a) : UN SEUL ecran de fin en Mode Accessibilite.
// La vraie salle le monte aussi ([ApresSeanceSalle]), avec ses cinq etats
// ([EtatApresSeance]) ; la prochaine seance porte son heure.
//
// MA-APRES-1b (revue C1-MA-R, majeur M1) : « pas encore programmee » n'est
// dit que si l'on SAIT qu'aucune occurrence n'est prevue. Aucune source ne le
// dit aujourd'hui (seance quittee en direct : l'horloge porte celle qu'on
// quitte ; en production : aucune horloge de groupe). La salle passe donc
// [ApresSeanceAccessibilite.prochaineInconnue] et l'ecran dit la phrase
// neutre « Ta prochaine seance s'affichera dans ta Classe. ». Le travail non
// relie (`null`) n'est plus confondu avec « aucun travail » (liste vide).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_groupe/port_groupes.dart';
import '../../core/tc_horloge/port_horloge_seance.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/tc_parcours/port_travail_a_venir.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../accueil_famille/bloc_seance.dart'
    show dateDeLAppareil, heureDeLAppareil;

/// Les cinq etats de ce qui suit le resultat (travail, prochaine seance).
/// Le resultat, « Retour a la Classe », le support et l'aide restent
/// toujours a l'ecran : la sortie ne depend jamais d'une lecture.
enum EtatApresSeance {
  /// La Classe est en cours de lecture.
  chargement,

  /// Le travail et/ou la prochaine seance sont connus.
  contenu,

  /// Rien a montrer : ni travail, ni prochaine seance programmee.
  vide,

  /// La lecture a echoue.
  erreur,

  /// L'appareil est hors ligne.
  horsLigne,
}

/// L'ecran « apres la seance » de l'eleve en Mode Accessibilite.
class ApresSeanceAccessibilite extends StatelessWidget {
  /// Cree l'ecran.
  const ApresSeanceAccessibilite({
    required this.espace,
    required this.prochaineSeance,
    required this.tutoiement,
    required this.onRetourClasse,
    required this.onSupport,
    required this.onAide,
    super.key,
    this.onTache,
    this.etat = EtatApresSeance.contenu,
    this.quittee = false,
    this.onReessayer,
    this.prochaineInconnue = false,
    this.travailRelie = true,
  });

  /// La Classe et le travail pour la prochaine fois (3 au plus), ou `null`
  /// quand la Classe n'est pas (encore) lue.
  final GroupHomeVM? espace;

  /// Le debut de la prochaine seance (UTC), ou `null`.
  final DateTime? prochaineSeance;

  /// Vrai pour l'eleve mineur (MA4) ; un adulte est vouvoye.
  final bool tutoiement;

  /// La prochaine action, seul bouton dominant.
  final VoidCallback onRetourClasse;

  /// « Revoir le support du cours ».
  final VoidCallback onSupport;

  /// Une ligne du travail.
  final VoidCallback? onTache;

  /// « Besoin d'aide ? ».
  final VoidCallback onAide;

  /// L'etat de ce qui suit le resultat.
  final EtatApresSeance etat;

  /// Vrai quand l'eleve est sorti avant la fin (« Quitter ») : le resultat
  /// le dit, il ne pretend jamais que la seance est terminee.
  final bool quittee;

  /// Relit la Classe (etat [EtatApresSeance.erreur]).
  final VoidCallback? onReessayer;

  /// Vrai quand [prochaineSeance] vaut `null` parce que l'occurrence
  /// suivante n'est PAS CONNUE (aucune source ne la donne), et non parce
  /// qu'aucune n'est programmee : l'ecran dit alors la phrase neutre, jamais
  /// « pas encore programmee ».
  final bool prochaineInconnue;

  /// Faux quand le travail a venir n'est pas relie (port `null`) : l'ecran
  /// le dit, il ne pretend jamais qu'il n'y a rien a preparer.
  final bool travailRelie;

  /// Cle de la phrase neutre de la prochaine seance inconnue.
  static const Key cleProchaineInconnue = ValueKey<String>(
    'ma-apres-prochaine-inconnue',
  );

  /// Cle de la ligne « travail non relie ».
  static const Key cleTravailNonRelie = ValueKey<String>(
    'ma-apres-travail-non-relie',
  );

  /// Cle du bouton dominant.
  static const Key cleRetourClasse = ValueKey<String>('ma6-retour-classe');

  /// Cles des etats autres que le contenu.
  static const Key cleChargement = ValueKey<String>('ma6-chargement');

  /// Etat vide.
  static const Key cleVide = ValueKey<String>('ma6-vide');

  /// Etat d'erreur.
  static const Key cleErreur = ValueKey<String>('ma6-erreur');

  /// Etat hors ligne.
  static const Key cleHorsLigne = ValueKey<String>('ma6-hors-ligne');

  /// La prochaine seance, date ET heure de l'appareil (« Lundi 5 octobre a
  /// 18:00 »), meme format que le reste de l'application.
  static String libelleProchaine(DateTime debutUtc) {
    final DateTime local = debutUtc.toLocal();
    return t.accessibilite.apres.prochaineDateHeure(
      date: dateDeLAppareil(local),
      heure: heureDeLAppareil(local),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final TextStyle corps = palette.inkMuted.applyTo(
      textes.bodyLarge ?? const TextStyle(),
    );

    final Widget retour = ActionPrincipale(
      key: cleRetourClasse,
      libelle: t.salle.fin.retourClasse,
      onPress: onRetourClasse,
      fleche: true,
      pleineLargeur: mobile,
    );

    final String titre = !quittee
        ? t.salle.fin.titreGuidee
        : tutoiement
        ? t.accessibilite.apres.quitteTitre
        : t.salle.fin.quitteTitre;
    final String phrase = quittee
        ? (tutoiement
              ? t.accessibilite.apres.quittePhrase
              : t.salle.fin.quittePhrase)
        : (tutoiement
              ? t.accessibilite.tutoiement.finPhrase
              : t.salle.fin.phrase);

    // Contrat B : le rectangle de resultat, 16 au-dessus du bouton, bouton
    // au bord de fin hors telephone.
    final Widget resultat = DecoratedBox(
      key: const ValueKey<String>('ma6-resultat'),
      decoration: palette.surfaceRaised.decoration(
        borderRadius: AppRadius.arrondiLg,
        side: palette.borderHairline.asBorderSide(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                titre,
                style: palette.inkStrong.applyTo(
                  textes.headlineSmall ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vSm,
            Text(phrase, style: corps),
            const SizedBox(height: AppSpacing.lg),
            if (mobile)
              retour
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[retour],
              ),
          ],
        ),
      ),
    );

    final GroupHomeVM? lu = espace;
    final bool montreContenu =
        lu != null &&
        (etat == EtatApresSeance.contenu || etat == EtatApresSeance.horsLigne);
    final List<SlotAction> travail = montreContenu
        ? lu.avantProchainCours.take(3).toList()
        : const <SlotAction>[];
    final DateTime? suivante = montreContenu ? prochaineSeance : null;
    final bool montreInconnue =
        montreContenu &&
        etat == EtatApresSeance.contenu &&
        suivante == null &&
        prochaineInconnue;
    final bool montreNonRelie =
        montreContenu && etat == EtatApresSeance.contenu && !travailRelie;
    final String phraseInconnue = tutoiement
        ? t.accessibilite.apres.prochaineInconnue
        : t.accessibilite.apres.prochaineInconnueVous;
    final VoidCallback? reessayer = onReessayer;

    // Ce qui remplace le travail et la prochaine seance hors contenu.
    final Widget? message = switch (etat) {
      EtatApresSeance.contenu => null,
      EtatApresSeance.chargement => Semantics(
        key: cleChargement,
        container: true,
        child: const Skeleton.liste(lignes: 2),
      ),
      EtatApresSeance.vide => Text(
        prochaineInconnue
            ? phraseInconnue
            : tutoiement
            ? t.accessibilite.apres.vide
            : t.accessibilite.apres.videVous,
        key: cleVide,
        style: corps,
      ),
      EtatApresSeance.horsLigne => Text(
        tutoiement
            ? t.accessibilite.apres.horsLigne
            : t.accessibilite.apres.horsLigneVous,
        key: cleHorsLigne,
        style: corps,
      ),
      EtatApresSeance.erreur => Column(
        key: cleErreur,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            tutoiement
                ? t.accessibilite.apres.erreur
                : t.accessibilite.apres.erreurVous,
            style: palette.inkStrong.applyTo(
              textes.bodyLarge ?? const TextStyle(),
            ),
          ),
          if (reessayer != null) ...<Widget>[
            Ecart.vMd,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                libelle: t.commun.reessayer,
                onPress: reessayer,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
              ),
            ),
          ],
        ],
      ),
    };

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          resultat,
          if (message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.section),
            message,
          ],
          if (montreNonRelie) ...<Widget>[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(titre: LibellesGroupe.avantProchainCours),
            Ecart.vMd,
            Text(
              t.tc.parcours.avant.nonBranche,
              key: cleTravailNonRelie,
              style: corps,
            ),
          ] else if (travail.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(titre: LibellesGroupe.avantProchainCours),
            Ecart.vMd,
            GroupeReglages(
              lignes: <LigneRubrique>[
                for (final SlotAction action in travail)
                  LigneRubrique(
                    libelle: action.libelle,
                    icone: AppIcons.cours,
                    onPress: onTache,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                libelle: t.accessibilite.apres.revoirSupport,
                legende: tutoiement
                    ? t.accessibilite.apres.revoirSupportDetail
                    : t.accessibilite.apres.revoirSupportDetailVous,
                icone: AppIcons.supports,
                onPress: onSupport,
              ),
            ],
          ),
          if (suivante != null && lu != null) ...<Widget>[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(titre: t.accessibilite.accueil.prochaineSeance),
            Ecart.vMd,
            GroupeReglages(
              lignes: <LigneRubrique>[
                LigneRubrique(
                  libelle: libelleProchaine(suivante),
                  legende: t.accessibilite.accueil.avec(
                    nomme: LibellesGroupe.enseignantNomme(
                      lu.identite.enseignant,
                    ),
                  ),
                  icone: AppIcons.journee,
                ),
              ],
            ),
          ] else if (montreInconnue) ...<Widget>[
            const SizedBox(height: AppSpacing.section),
            SectionHeader(titre: t.accessibilite.accueil.prochaineSeance),
            Ecart.vMd,
            Text(phraseInconnue, key: cleProchaineInconnue, style: corps),
          ],
          const SizedBox(height: AppSpacing.section),
          // L'aide, dernier bloc du contenu (MA14).
          GroupeReglages(
            lignes: <LigneRubrique>[
              LigneRubrique(
                libelle: t.accessibilite.accueil.aide,
                icone: AppIcons.info,
                onPress: onAide,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// MA-APRES-1 : l'ecran unique de fin, monte par la VRAIE salle en Mode
/// Accessibilite. Il lit la Classe par les memes fournisseurs que l'Espace
/// Groupe (aucun appel serveur nouveau) et en tire l'un des cinq etats.
class ApresSeanceSalle extends ConsumerWidget {
  /// Cree l'ecran branche.
  const ApresSeanceSalle({
    required this.groupeId,
    required this.quittee,
    required this.tutoiement,
    required this.onRetourClasse,
    required this.onClasse,
    required this.onAide,
    super.key,
    this.seanceQuitteeId,
  });

  /// La seance que l'eleve vient de quitter, si la salle la connait : elle
  /// n'est jamais « la prochaine ».
  final String? seanceQuitteeId;

  /// La Classe de la seance, ou `null` quand la salle ne la connait pas.
  final String? groupeId;

  /// Vrai apres « Quitter ».
  final bool quittee;

  /// Vrai pour l'eleve tutoye.
  final bool tutoiement;

  /// « Retour a la Classe ».
  final VoidCallback onRetourClasse;

  /// Le support et le travail vivent dans la Classe.
  final VoidCallback onClasse;

  /// « Besoin d'aide ? ».
  final VoidCallback onAide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String? id = groupeId;

    ApresSeanceAccessibilite ecran(
      EtatApresSeance etat, {
      GroupHomeVM? espace,
      DateTime? prochaine,
      VoidCallback? onReessayer,
      bool travailRelie = true,
    }) => ApresSeanceAccessibilite(
      espace: espace,
      prochaineSeance: prochaine,
      // Aucune source ne dit qu'aucune occurrence n'est prevue : une
      // prochaine seance absente est toujours inconnue (M1).
      prochaineInconnue: prochaine == null,
      travailRelie: travailRelie,
      tutoiement: tutoiement,
      quittee: quittee,
      etat: etat,
      onRetourClasse: onRetourClasse,
      onSupport: onClasse,
      onTache: onClasse,
      onAide: onAide,
      onReessayer: onReessayer,
    );

    if (id == null) {
      return ecran(
        horsLigne ? EtatApresSeance.horsLigne : EtatApresSeance.vide,
      );
    }

    final AsyncValue<GroupSummaryVM?> lecture = ref.watch(groupeProvider(id));
    if (lecture.hasError && !lecture.hasValue) {
      return horsLigne
          ? ecran(EtatApresSeance.horsLigne)
          : ecran(
              EtatApresSeance.erreur,
              onReessayer: () => ref.invalidate(groupeProvider(id)),
            );
    }
    if (!lecture.hasValue) {
      return ecran(EtatApresSeance.chargement);
    }
    final GroupSummaryVM? trouve = lecture.requireValue;
    if (trouve == null) {
      return ecran(
        horsLigne ? EtatApresSeance.horsLigne : EtatApresSeance.vide,
      );
    }

    final SessionClockVM? tic = ref.watch(horlogeGroupeProvider(id)).value;
    final GroupSummaryVM identite = tic == null
        ? trouve
        : trouve.avecHorloge(tic);
    // `null` = travail non relie (port non branche), liste vide = aucun
    // travail : la difference du port va jusqu'a l'ecran (M1).
    final ContexteTravailAVenir contexte = (groupeId: id, studentId: null);
    final AsyncValue<List<SlotAction>?> lectureTravail = ref.watch(
      travailAVenirProvider(contexte),
    );
    if (lectureTravail.hasError && !lectureTravail.hasValue) {
      return horsLigne
          ? ecran(EtatApresSeance.horsLigne)
          : ecran(
              EtatApresSeance.erreur,
              onReessayer: () =>
                  ref.invalidate(travailAVenirProvider(contexte)),
            );
    }
    if (!lectureTravail.hasValue) {
      return ecran(EtatApresSeance.chargement);
    }
    final List<SlotAction>? lus = lectureTravail.requireValue;
    final List<SlotAction> actions = lus ?? const <SlotAction>[];
    final GroupHomeVM espace = GroupHomeVM.pourRole(
      identite: identite,
      role: RoleEspaceGroupe.eleve,
      actions: actions.take(3).toList(),
    );
    final DateTime? prochaine = prochaineApres(
      espace.horloge,
      seanceQuitteeId: seanceQuitteeId,
    );

    // Jamais « vide » ici : sans prochaine seance connue, l'ecran dit la
    // phrase neutre dans le contenu (M1).
    return ecran(
      horsLigne ? EtatApresSeance.horsLigne : EtatApresSeance.contenu,
      espace: espace,
      prochaine: prochaine,
      travailRelie: lus != null,
    );
  }

  /// La prochaine seance a annoncer apres la sortie, ou `null` si elle n'est
  /// pas connue. Seule une occurrence dont la salle n'est pas encore ouverte
  /// (phase [PhaseSeance.avantFenetre]) et qui n'est pas la seance quittee
  /// l'est : celle que l'eleve vient de quitter, ouverte, en direct ou
  /// prolongee, ne l'est jamais. L'occurrence suivante d'une Classe
  /// hebdomadaire n'a aucune source cote client (ni recurrence, ni horloge de
  /// groupe en production) : elle n'est pas devinee.
  static DateTime? prochaineApres(
    SessionClockVM? horloge, {
    String? seanceQuitteeId,
  }) {
    if (horloge == null) return null;
    if (horloge.phase != PhaseSeance.avantFenetre) return null;
    if (!horloge.debutUtc.isAfter(horloge.calculeeAUtc)) return null;
    final String? id = horloge.sessionId;
    if (id != null && id == seanceQuitteeId) return null;
    return horloge.debutUtc;
  }
}
