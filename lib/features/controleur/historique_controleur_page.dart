// Historique (CTR-05) et Detail d'un controle (CTR-06), CT-7 : la deuxieme
// destination de la coquille controleur (C13).
//
// La liste reutilise TELS QUELS les composants de l'Historique du tuteur
// (`ColonneHistorique`, `CarteLignes`, `LigneHistorique`, modele
// `Historique.png`, C18) et ses filtres (`FiltresHistorique`,
// `PeriodeHistorique`, `MenuFiltre`) : Periode, Classe, Etat, jamais
// Enseignant (doc 08 CTR-05). Plus recent d'abord, statut ecrit en mots.
//
// Le detail est en lecture seule (C10) : Mission, Faits automatiques,
// Observation du Controleur, Complements, Echanges Admin. « Ajouter un
// complement » est le seul bouton principal (parcours CT-8, `ComplementRapportPage`) ;
// « Ecrire a l'administration » est un lien vers le fil de la mission. Un
// rapport « A terminer » n'a pas de detail : la ligne reprend le compte rendu.
//
// Aucun serveur (K-28) : le port par defaut echoue, la demonstration le
// remplace.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_famille/bloc_seance.dart'
    show dateDeLAppareil, heureDeLAppareil;
import '../suivi_foyer/composants_historique.dart'
    show CarteLignes, ColonneHistorique, LigneHistorique;
import '../suivi_foyer/filtres_historique.dart'
    show FiltresHistorique, PeriodeHistorique;
import 'complement_rapport_page.dart';
import 'compte_rendu_controle.dart';
import 'compte_rendu_controle_page.dart' show LignesFaitsVisite;
import 'historique_controleur.dart';
import 'observation_controle.dart';
import 'observation_controle_page.dart';

/// Le libelle d'un statut (doc 08 CTR-05).
String libelleStatutRapport(StatutRapport s) => switch (s) {
  StatutRapport.envoye => t.controleur.historique.envoye,
  StatutRapport.complementAjoute => t.controleur.historique.complementAjoute,
  StatutRapport.aTerminer => t.controleur.historique.aTerminer,
};

/// Le ton d'un statut : discret (doc 08 « statuts discrets »), l'accent
/// seulement pour ce qui reste a faire.
TonEtat tonStatutRapport(StatutRapport s) => switch (s) {
  StatutRapport.aTerminer => TonEtat.accent,
  StatutRapport.envoye || StatutRapport.complementAjoute => TonEtat.neutre,
};

/// La page Historique du controleur : la liste, ou le detail ouvert.
class HistoriqueControleurPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const HistoriqueControleurPage({
    super.key,
    this.maintenant,
    this.onReprendreCompteRendu,
    this.onEcrireAdmin,
  });

  /// L'instant de reference du filtre Periode (maintenant par defaut).
  final DateTime? maintenant;

  /// Reprendre le compte rendu « A terminer » de la seance donnee ; par
  /// defaut, la route CTR-03 avec `?seance=` (revue CT-R B1).
  final ValueChanged<String>? onReprendreCompteRendu;

  /// Ouvrir le fil de la mission ; par defaut, ce fil dans Echanges
  /// (`?mission=`, C17, revue CT-R M2), jamais la liste seule.
  final ValueChanged<String>? onEcrireAdmin;

  /// La ligne d'un rapport.
  static Key ligneKey(String id) => ValueKey<String>('ctr05-$id');

  /// « Ajouter un complement ».
  static const Key complementKey = ValueKey<String>('ctr06-complement');

  /// « Ecrire a l'administration ».
  static const Key ecrireAdminKey = ValueKey<String>('ctr06-ecrire-admin');

  @override
  ConsumerState<HistoriqueControleurPage> createState() =>
      _HistoriqueControleurPageState();
}

class _HistoriqueControleurPageState
    extends ConsumerState<HistoriqueControleurPage> {
  AsyncValue<List<RapportControle>> _liste =
      const AsyncValue<List<RapportControle>>.loading();
  RapportControle? _ouvert;
  bool _enComplement = false;
  FiltresHistorique<StatutRapport> _filtres =
      const FiltresHistorique<StatutRapport>();

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _liste = const AsyncValue<List<RapportControle>>.loading());
    final AsyncValue<List<RapportControle>> v = await AsyncValue.guard(
      () async =>
          <RapportControle>[
            ...await ref.read(portHistoriqueProvider).rapports(),
          ]..sort(
            (RapportControle a, RapportControle b) =>
                b.debut.compareTo(a.debut),
          ),
    );
    if (mounted) setState(() => _liste = v);
  }

  void _ouvrir(RapportControle r) {
    if (r.statut == StatutRapport.aTerminer) {
      // La reprise ouvre CETTE visite (revue CT-R B1) : le rapport, deja
      // transmis par le serveur, la decrit.
      final String? seance = r.seanceId;
      if (seance != null) {
        ref
            .read(compteRenduATerminerProvider.notifier)
            .ouvrir(
              CompteRenduEnSuspens(
                seanceId: seance,
                classe: r.classe,
                debut: r.debut,
                missionId: r.missionId,
                transmission: TransmissionVisite.transmise,
              ),
            );
      }
      final ValueChanged<String>? f = widget.onReprendreCompteRendu;
      if (f != null && seance != null) {
        f(seance);
      } else {
        GoRouter.of(context)
            .go(adresseCompteRendu(Routes.controleurCompteRendu, seance));
      }
      return;
    }
    setState(() => _ouvert = r);
  }

  // La nouvelle vue remplace l'ancienne a l'ecran ; le rapport d'origine
  // n'est pas modifie (C10).
  void _complementAjoute(RapportControle maj) => setState(() {
    _ouvert = maj;
    _enComplement = false;
    _liste = _liste.whenData(
      (List<RapportControle> l) => <RapportControle>[
        for (final RapportControle x in l) x.id == maj.id ? maj : x,
      ],
    );
  });

  // Revue CT-R m3 : le Detail et le Complement sont des etats internes ; le
  // retour systeme (Android, navigateur) ferme d'abord le complement, puis le
  // detail, au lieu de quitter l'Historique.
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _ouvert == null,
    onPopInvokedWithResult: (bool fait, Object? _) {
      if (fait) return;
      setState(() {
        if (_enComplement) {
          _enComplement = false;
        } else {
          _ouvert = null;
        }
      });
    },
    child: _corps(context),
  );

  Widget _corps(BuildContext context) {
    final RapportControle? r = _ouvert;
    if (r != null && _enComplement) {
      return ComplementRapportPage(
        rapport: r,
        onRetour: () => setState(() => _enComplement = false),
        onTermine: _complementAjoute,
      );
    }
    if (r != null) {
      return _DetailRapport(
        rapport: r,
        onRetour: () => setState(() => _ouvert = null),
        onComplement: () => setState(() => _enComplement = true),
        onEcrireAdmin:
            widget.onEcrireAdmin ??
            (String mission) =>
                GoRouter.of(context).go(Routes.controleurEcrireAdmin(mission)),
      );
    }
    final h = t.controleur.historique;
    return PageShell(
      titre: h.titre,
      child: ColonneHistorique(
        child: BlocAsynchrone<List<RapportControle>>(
          valeur: _liste,
          squelette: const Skeleton.liste(),
          onReessayer: _charger,
          estVide: (List<RapportControle> l) => l.isEmpty,
          vide: EmptyState(
            message: h.vide,
            icone: AppIcons.historique,
            registre: RegistreVide.subi,
          ),
          construire: _contenu,
        ),
      ),
    );
  }

  Widget _contenu(List<RapportControle> tous) {
    final h = t.controleur.historique;
    final DateTime maintenant = widget.maintenant ?? DateTime.now();
    final List<String> classes = <String>{
      for (final RapportControle r in tous) r.classe,
    }.toList()..sort();
    final List<RapportControle> retenus = <RapportControle>[
      for (final RapportControle r in tous)
        if ((_filtres.classeId == null || r.classe == _filtres.classeId) &&
            _filtres.periode.contient(r.debut, maintenant) &&
            (_filtres.statut == null || r.statut == _filtres.statut))
          r,
    ];
    final TextStyle doux = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodySmall ?? const TextStyle());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            MenuFiltre<PeriodeHistorique>(
              libelle: t.historique.filtres.periode,
              valeur: _filtres.periode == PeriodeHistorique.toute
                  ? null
                  : _filtres.periode,
              entrees: <EntreeFiltre<PeriodeHistorique>>[
                for (final PeriodeHistorique p in PeriodeHistorique.values)
                  EntreeFiltre<PeriodeHistorique>(
                    valeur: p == PeriodeHistorique.toute ? null : p,
                    libelle: p.libelle,
                  ),
              ],
              onChoix: (PeriodeHistorique? p) => setState(
                () => _filtres = _filtres.avecPeriode(
                  p ?? PeriodeHistorique.toute,
                ),
              ),
            ),
            MenuFiltre<String>(
              libelle: t.historique.filtres.classe,
              valeur: _filtres.classeId,
              entrees: <EntreeFiltre<String>>[
                EntreeFiltre<String>(
                  valeur: null,
                  libelle: t.historique.filtres.toutesClasses,
                ),
                for (final String c in classes)
                  EntreeFiltre<String>(valeur: c, libelle: c),
              ],
              onChoix: (String? c) =>
                  setState(() => _filtres = _filtres.avecClasse(c)),
            ),
            MenuFiltre<StatutRapport>(
              libelle: h.filtreEtat,
              valeur: _filtres.statut,
              entrees: <EntreeFiltre<StatutRapport>>[
                EntreeFiltre<StatutRapport>(valeur: null, libelle: h.tousEtats),
                for (final StatutRapport s in StatutRapport.values)
                  EntreeFiltre<StatutRapport>(
                    valeur: s,
                    libelle: libelleStatutRapport(s),
                    compteur: tous
                        .where((RapportControle r) => r.statut == s)
                        .length,
                  ),
              ],
              onChoix: (StatutRapport? s) =>
                  setState(() => _filtres = _filtres.avecStatut(s)),
            ),
          ],
        ),
        Ecart.vSm,
        // Le nombre de resultats, annonce une fois par changement de filtre.
        Semantics(
          liveRegion: true,
          child: Text(h.resultats(n: retenus.length), style: doux),
        ),
        Ecart.vSm,
        if (retenus.isEmpty)
          EmptyState(
            message: h.videFiltres,
            icone: AppIcons.historique,
            registre: RegistreVide.subi,
          )
        else
          CarteLignes(
            lignes: <Widget>[
              for (final RapportControle r in retenus) _ligne(r),
            ],
          ),
      ],
    );
  }

  Widget _ligne(RapportControle r) {
    final h = t.controleur.historique;
    final String date = dateDeLAppareil(r.debut);
    // DUREE-INSECABLE-4 : la duree ne s'affiche jamais seule ici, elle suit
    // l'heure (« 18:00 · 12 min observees ») et la date de la phrase lue :
    // insecable, sans ancre de sens au milieu du libelle.
    final String duree = LibellesGroupe.insecable(
      h.duree(minutes: r.dureeObservee.inMinutes),
    );
    final String statut = libelleStatutRapport(r.statut);
    return LigneHistorique(
      key: HistoriqueControleurPage.ligneKey(r.id),
      date: date,
      meta: h.meta(heure: heureDeLAppareil(r.debut), duree: duree),
      titre: r.classe,
      sousTitre: r.enseignant,
      statut: statut,
      ton: tonStatutRapport(r.statut),
      semantique: h.ligne(
        date: date,
        classe: r.classe,
        enseignant: r.enseignant,
        duree: duree,
        statut: statut,
      ),
      onPress: () => _ouvrir(r),
    );
  }
}

/// Le detail d'un controle (CTR-06), en lecture seule (C10).
class _DetailRapport extends StatelessWidget {
  const _DetailRapport({
    required this.rapport,
    required this.onRetour,
    required this.onComplement,
    required this.onEcrireAdmin,
  });

  final RapportControle rapport;
  final VoidCallback onRetour;
  final VoidCallback onComplement;
  final ValueChanged<String> onEcrireAdmin;

  @override
  Widget build(BuildContext context) {
    final h = t.controleur.historique;
    final RapportControle r = rapport;
    final ObservationControle? o = r.observation;
    final FaitsVisite? faits = r.faits;
    final bool large = MediaQuery.sizeOf(context).width >= 840;
    final Widget entre = SizedBox(
      height: large ? AppSpacing.xxxl : AppSpacing.xxl,
    );
    final TextStyle doux = AppPalette.of(context).inkMuted
        .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle());

    return PageShell(
      titre: h.titreDetail(classe: r.classe, date: dateDeLAppareil(r.debut)),
      onRetour: onRetour,
      child: ColonneHistorique(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: StatusPill(
                libelle: libelleStatutRapport(r.statut),
                ton: tonStatutRapport(r.statut),
              ),
            ),
            entre,
            _Section(
              titre: h.sectionMission,
              enfants: <Widget>[
                LigneCleValeur(cle: h.cleClasse, valeur: r.classe),
                LigneCleValeur(cle: h.cleEnseignant, valeur: r.enseignant),
                LigneCleValeur(
                  cle: h.cleDate,
                  // Ordre et virgule traduisibles (revue CT-R m9).
                  valeur: h.dateHeure(
                    date: dateDeLAppareil(r.debut),
                    heure: heureDeLAppareil(r.debut),
                  ),
                  chiffres: true,
                ),
                LigneCleValeur(
                  cle: h.cleDuree,
                  valeur: LibellesGroupe.valeurSeule(
                    h.duree(minutes: r.dureeObservee.inMinutes),
                  ),
                  chiffres: true,
                ),
              ],
            ),
            entre,
            _Section(
              titre: t.controleur.compteRendu.faits,
              enfants: <Widget>[
                if (faits == null)
                  Text(h.faitsIndisponibles, style: doux)
                else
                  LignesFaitsVisite(faits: faits),
                if (r.presents.isNotEmpty)
                  LigneCleValeur(
                    cle: h.cleElevesPresents,
                    // Chaque nom dans son isolat : la virgule et le point
                    // de l'initiale restent a leur place, nom arabe ou
                    // latin (CTRL-ROSTER-C7-1b).
                    valeur: r.presents.map(isolerSens).join(', '),
                  ),
              ],
            ),
            entre,
            _Section(
              titre: h.sectionObservation,
              enfants: <Widget>[
                if (o == null)
                  LigneCleValeur(
                    cle: h.cleReponse,
                    valeur: t.controleur.compteRendu.rienASignaler,
                  )
                else ...<Widget>[
                  LigneCleValeur(
                    cle: t.controleur.observation.cleNature,
                    valeur: ObservationControlePage.libelleNature(o.nature),
                  ),
                  LigneCleValeur(
                    cle: t.controleur.observation.cleDomaine,
                    valeur: ObservationControlePage.libelleDomaine(o.domaine),
                  ),
                  LigneCleValeur(
                    cle: t.controleur.observation.clePersonne,
                    valeur: ObservationControlePage.libellePersonne(o.personne),
                    complement: r.eleve == null ? null : Text(r.eleve!),
                  ),
                  LigneCleValeur(
                    cle: t.controleur.observation.cleTexte,
                    valeur: o.texte.trim().isEmpty
                        ? t.controleur.observation.sansTexte
                        : o.texte,
                  ),
                ],
              ],
            ),
            entre,
            _Section(
              titre: h.sectionComplements,
              enfants: <Widget>[
                if (r.complements.isEmpty)
                  Text(h.sansComplement, style: doux)
                else
                  for (final ComplementRapport c in r.complements)
                    LigneCleValeur(
                      // Revue CT-R m4 : qui l'a ecrit, a cote de la date.
                      cle: h.dateHeureAuteur(
                        date: dateDeLAppareil(c.date),
                        heure: heureDeLAppareil(c.date),
                        auteur: c.auteur ?? t.controleur.echanges.auteurVous,
                      ),
                      valeur: c.texte,
                      complement: c.motif == null
                          ? null
                          : Text(h.motif(motif: c.motif!)),
                    ),
              ],
            ),
            Ecart.vLg,
            // Le seul bouton principal, trailing, sous ce qu'il enrichit.
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ActionPrincipale(
                key: HistoriqueControleurPage.complementKey,
                libelle: h.ajouterComplement,
                pleineLargeur: false,
                onPress: onComplement,
              ),
            ),
            entre,
            _Section(
              titre: h.sectionEchanges,
              enfants: <Widget>[
                LienFleche(
                  key: HistoriqueControleurPage.ecrireAdminKey,
                  libelle: t.controleur.compteRendu.ecrireAdmin,
                  icone: AppIcons.discussion,
                  onPress: () => onEcrireAdmin(r.missionId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Une section du detail : titre, puis une carte de lignes cle-valeur.
class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.enfants});

  final String titre;
  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SectionHeader(titre: titre),
      Ecart.vSm,
      AppCard(
        surface: AppPalette.of(context).surfaceRaised,
        marge: AppSpacing.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: enfants,
        ),
      ),
    ],
  );
}
