import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/elision.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/router/routes.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/pays_enseignant.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../compte/carte_rubriques.dart';
import '../journal_sorties/section_sorties_seance.dart';
import 'bloc_compte_rendu.dart';
import 'composants_historique.dart';
import 'donnees_historique.dart';
import 'filtres_historique.dart';
import 'vue_suivi_foyer.dart';

/// Le detail d'une seance passee (`/tuteur/seances/:seanceId?eleve=`, lot E
/// sous-paquet 2). Page de niveau 2 : l'Historique reste actif dans la barre,
/// le disque retour ramene a la liste.
///
/// Derive de la maquette V8 D4 (manifeste : « lien retour, titre, carte
/// d'infos, rangees ») : titre = la classe, sous-titre = l'eleve et la date,
/// puis deux cartes groupees : la seance (date, horaire, duree prevue, classe,
/// enseignant) et la presence de l'eleve (etat apres la seance, arrivee,
/// interruption), puis le compte rendu pedagogique partageable (PED-APRES-1,
/// `BlocCompteRendu`, par le port de partage : jamais `lesson_reports`, qui
/// porte les decisions de tous les eleves, DB-CRS-12). Aucun reseau (non
/// mesure), aucune action de modification.
///
/// La ligne vient de la meme lecture que la liste (`mes_seances_v`, bornee au
/// foyer par la base) : un identifiant qui n'y figure pas est « introuvable »,
/// jamais une autre seance.
class DetailSeancePage extends ConsumerWidget {
  /// Cree la page.
  const DetailSeancePage({
    required this.seanceId,
    super.key,
    this.horloge = DateTime.now,
  });

  /// La seance affichee.
  final String seanceId;

  /// L'horloge : la presence d'une seance terminee se dit « En cours de
  /// verification » les premieres heures seulement, puis mesuree.
  final DateTime Function() horloge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // HEURES-PROFIL H4 : la page se redessine quand le fuseau du profil arrive.
    ref.watch(monHorlogeProvider);
    final String? eleveDemande = parametreRequete(context, 'eleve');
    final AsyncValue<List<Seance>> seances = ref.watch(seancesDuSuiviProvider);
    final Seance? seance = seances.hasValue && !seances.hasError
        ? _trouver(
            seances.requireValue,
            eleveDemande ?? ref.watch(eleveSelectionneProvider).value?.eleveId,
          )
        : null;
    final Map<String, GroupSummaryVM> classes = ref.watch(
      classesCourantesProvider,
    );
    final GroupSummaryVM? classe = seance == null
        ? null
        : classes[ref.watch(classeDesSeancesProvider)[seance.id]];
    // Point 4 (07/11/2026) : le nom lu avec la seance, Classe quittee ou
    // close comprise.
    final String? nomClasseLu = seance == null
        ? null
        : nomClasseDeSeance(
            seance.id,
            classe,
            ref.watch(nomsClassesDesSeancesProvider),
          );

    // Toujours vers la liste : les filtres y vivent en memoire de session.
    void retour() => GoRouter.of(context).go(Routes.tuteurSuivi);

    return PageShell(
      titre: seance == null
          ? t.historique.detailSeance
          : nomClasseLu ??
                t.historique.seance.titreSansClasse(
                  date: dateCourte(chezMoi(seance.debut)),
                ),
      sousTitre: seance == null
          ? null
          : '${seance.elevePrenom} · ${dateMoyenne(seance.debut)}',
      onRetour: retour,
      child: ColonneHistorique(
        child: BlocAsynchrone<List<Seance>>(
          valeur: seances,
          squelette: const Skeleton.liste(lignes: 5),
          onReessayer: () => ref
            ..invalidate(seancesDuSuiviProvider)
            ..invalidate(presenceDuSuiviProvider),
          construire: (List<Seance> _) => seance == null
              ? EtatSysteme(
                  nature: NatureEtat.introuvable,
                  titre: t.historique.seance.introuvableTitre,
                  phrase: t.historique.seance.introuvablePhrase,
                  libelleAction: t.historique.retour,
                  onAction: () => GoRouter.of(context).go(Routes.tuteurSuivi),
                )
              : _Contenu(
                  seance: seance,
                  classe: classe,
                  nomClasse: nomClasseLu,
                  maintenant: horloge(),
                ),
        ),
      ),
    );
  }

  /// La ligne de la seance pour l'eleve demande, sinon la premiere ligne de
  /// cette seance (un eleve seul), sinon rien.
  Seance? _trouver(List<Seance> seances, String? eleveId) {
    Seance? premiere;
    for (final Seance s in seances) {
      if (s.id != seanceId) {
        continue;
      }
      if (s.eleveId == eleveId) {
        return s;
      }
      premiere ??= s;
    }
    return premiere;
  }
}

class _Contenu extends ConsumerWidget {
  const _Contenu({
    required this.seance,
    required this.classe,
    required this.nomClasse,
    required this.maintenant,
  });

  final Seance seance;
  final GroupSummaryVM? classe;
  final String? nomClasse;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final AsyncValue<List<PresenceParticipant>?> presence = ref.watch(
      presenceDuSuiviProvider,
    );
    final List<PresenceParticipant>? presences = presence.value;
    final bool presenceIllisible =
        !presence.isLoading && (presence.hasError || presences == null);
    final LigneSuivi ligne = VueSuiviFoyer.depuis(
      seances: <Seance>[seance],
      presences: presences,
      maintenant: maintenant,
    ).lignes.single;
    final StatutHistorique statut = statutDe(ligne);
    final PresenceParticipant? mienne = ligne.montrePresence
        ? _ligneEleve(presences, seance)
        : null;
    final DateTime? arrivee = mienne?.entreLe;
    final DateTime? sortie = mienne?.sortieLe;
    final int? minutes = mienne?.minutesConnectees;
    final int? prevues = mienne?.minutesPrevues;
    final String? phrase = switch (statut) {
      // La presence est automatique (directeur, 07/11/2026) : on dit d'ou
      // elle vient, en une ligne.
      _ when presenceMesuree(ligne) => t.historique.seance.mesureAutomatique,
      StatutHistorique.verification => t.historique.seance.verificationPhrase,
      StatutHistorique.nonTenu => t.historique.seance.nonTenuPhrase,
      StatutHistorique.annule => t.historique.seance.annulePhrase,
      _ => null,
    };

    Widget titreBloc(String texte) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(
          texte,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
      ),
    );

    Widget carte(List<Widget> lignes, {bool annulee = false}) => SurfaceCarte(
      surface: annulee ? surfaceCarteSeance(palette, annulee: true) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: lignes,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        titreBloc(t.historique.seance.blocSeance),
        carte(<Widget>[
          LigneCleValeur(
            cle: t.historique.seance.horaire,
            valeur: plageHoraire(chezMoi(seance.debut), chezMoi(seance.fin)),
            chiffres: true,
            annulee: statut == StatutHistorique.annule,
          ),
          LigneCleValeur(
            cle: t.historique.seance.dureePrevue,
            valeur: dureeSeule(seance.duree),
            chiffres: true,
          ),
          LigneCleValeur(
            cle: t.historique.seance.classe,
            valeur: nomClasse ?? t.historique.classeInconnue,
          ),
          LigneCleValeur(
            cle: t.historique.seance.enseignant,
            valeur: enseignantAffiche(seance, classe),
            complement: PaysEnseignant.siDeclare(
              paysEnseignantAffiche(seance, classe),
            ),
          ),
        ], annulee: statut == StatutHistorique.annule),
        Ecart.vXl,
        titreBloc(
          t.historique.seance.blocPresence(
            dePrenom: deDevant(seance.elevePrenom),
          ),
        ),
        carte(<Widget>[
          LigneCleValeur(
            cle: t.historique.seance.presence,
            valeur: '',
            complement: statut == StatutHistorique.annule
                ? PastilleEtatSeance(
                    etat: EtatPastilleSeance.annulee,
                    libelle: libelleStatut(ligne),
                  )
                : StatusPill(libelle: libelleStatut(ligne), ton: statut.ton),
          ),
          if (arrivee != null)
            LigneCleValeur(
              cle: t.historique.seance.arrivee,
              valeur: heureMinute(chezMoi(arrivee)),
              chiffres: true,
            ),
          // PRESENCE-MINUTES (31/10/2026) : sortie et minutes reellement
          // connectees, calculees par le serveur. Une presence partielle se
          // dit en mots, jamais par la seule couleur.
          if (arrivee != null && sortie != null)
            LigneCleValeur(
              cle: t.historique.seance.sortie,
              valeur: heureMinute(chezMoi(sortie)),
              chiffres: true,
            ),
          if (minutes != null && prevues != null && arrivee != null)
            LigneCleValeur(
              cle: t.historique.seance.tempsPresence,
              valeur: LibellesGroupe.valeurSeule(
                t.historique.seance.minutesSur(
                  minutes: minutes,
                  prevues: prevues,
                ),
              ),
              chiffres: true,
              // Une seule pastille de presence (garde-cap, 07/11/2026) : celle
              // de la ligne « Presence » dit deja « Presence partielle ».
            ),
          if (seance.minutesInterruption > 0)
            LigneCleValeur(
              cle: t.historique.seance.interruption,
              valeur: dureeSeule(Duration(minutes: seance.minutesInterruption)),
              chiffres: true,
            ),
          if (phrase != null || presenceIllisible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: NoteHistorique(
                presenceIllisible && ligne.montrePresence
                    ? t.historique.presenceIllisible
                    : phrase ?? '',
              ),
            ),
        ]),
        // HORS-SALLE-2 (directeur, 12/11/2026 au soir) : les sorties de
        // l'application de l'eleve, sous le temps de presence. Rien, pas meme
        // un titre, sans ligne lisible (aucun accord, journal eteint).
        SectionSortiesSeance(
          seanceId: seance.id,
          eleveId: seance.eleveId,
          titre: titreBloc,
          carte: carte,
        ),
        // PED-APRES-1 (TUT-PED-APR-01) : le compte rendu pedagogique partageable
        // de CET eleve. Absent d'une seance annulee ou non tenue : aucun bloc
        // trompeur, ni appreciation, ni faux constat d'absence.
        if (statut != StatutHistorique.annule &&
            statut != StatutHistorique.nonTenu) ...<Widget>[
          Ecart.vXl,
          BlocCompteRendu(
            seanceId: seance.id,
            eleveId: seance.eleveId,
            classeId: classe?.groupeId,
          ),
        ],
        // HEURES-PROFIL H4 (garde-cap, 12/11/2026) : la mention ne dit
        // l'appareil, et son decalage, que s'il sert.
        if (estHeureDeLAppareil(seance.debut)) ...<Widget>[
          Ecart.vMd,
          NoteHistorique(
            t.historique.fuseauDetail(
              decalage: decalageUtc(chezMoi(seance.debut)),
            ),
          ),
        ],
      ],
    );
  }

  static PresenceParticipant? _ligneEleve(
    List<PresenceParticipant>? lignes,
    Seance seance,
  ) {
    for (final PresenceParticipant p
        in lignes ?? const <PresenceParticipant>[]) {
      if (p.seanceId == seance.id && p.profilId == seance.eleveId) {
        return p;
      }
    }
    return null;
  }
}
