import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/foyer/selection_eleve.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/planning/service_planning.dart';
import '../../core/presence/service_presence.dart';
import '../../core/router/routes.dart';
import '../../core/suivi/service_suivi.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../compte/carte_rubriques.dart';
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
/// interruption). Aucun resume famille (DB-CRS-12 : `lesson_reports` porte les
/// decisions de tous les eleves), aucun reseau (non mesure), aucune action.
///
/// La ligne vient de la meme lecture que la liste (`mes_seances_v`, bornee au
/// foyer par la base) : un identifiant qui n'y figure pas est « introuvable »,
/// jamais une autre seance.
class DetailSeancePage extends ConsumerWidget {
  /// Cree la page.
  const DetailSeancePage({required this.seanceId, super.key});

  /// La seance affichee.
  final String seanceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Toujours vers la liste : les filtres y vivent en memoire de session.
    void retour() => GoRouter.of(context).go(Routes.tuteurSuivi);

    return PageShell(
      titre: seance == null
          ? t.historique.detailSeance
          : classe?.libelle ??
                t.historique.seance.titreSansClasse(
                  date: dateCourte(seance.debut),
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
              : _Contenu(seance: seance, classe: classe),
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
  const _Contenu({required this.seance, required this.classe});

  final Seance seance;
  final GroupSummaryVM? classe;

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
      maintenant: seance.fin,
    ).lignes.single;
    final StatutHistorique statut = statutDe(ligne);
    final DateTime? arrivee = ligne.montrePresence
        ? _entree(presences, seance)
        : null;
    final String? phrase = switch (statut) {
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
            valeur: plageHoraire(seance.debut, seance.fin),
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
            valeur: classe?.libelle ?? t.historique.classeInconnue,
          ),
          LigneCleValeur(
            cle: t.historique.seance.enseignant,
            valeur: enseignantAffiche(seance, classe),
          ),
        ], annulee: statut == StatutHistorique.annule),
        Ecart.vXl,
        titreBloc(t.historique.seance.blocPresence(prenom: seance.elevePrenom)),
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
              valeur: heureMinute(arrivee),
              chiffres: true,
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
        Ecart.vMd,
        NoteHistorique(
          t.historique.fuseauDetail(decalage: decalageUtc(seance.debut)),
        ),
      ],
    );
  }

  static DateTime? _entree(List<PresenceParticipant>? lignes, Seance seance) {
    for (final PresenceParticipant p
        in lignes ?? const <PresenceParticipant>[]) {
      if (p.seanceId == seance.id && p.profilId == seance.eleveId) {
        return p.entreLe;
      }
    }
    return null;
  }
}
