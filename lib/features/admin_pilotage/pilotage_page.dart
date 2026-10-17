/// ECHELLE-ADM-PILOTAGE-1 : le tableau de pilotage de la direction, par
/// horaire et par categorie (R7, R9, R17, R19,
/// `DECISION-CLASSES-SIMULTANEES-2026-10-10.md`).
///
/// De haut en bas : la vue d'ensemble (les totaux du jeu filtre), les
/// classes qui attendent leur enseignant (mises en avant, avec l'action
/// « Choisir l'enseignant »), puis la liste des horaires, paginee par le
/// port (25 par page) et filtrable par signal (penurie, sous le minimum, en
/// attente d'enseignant), public, jour, heure et fuseau.
///
/// L'ecran additionne ce que le port rend, il ne compare ni classe ni
/// disponibilite. Il lit des capacites, jamais un role : le bouton
/// « Choisir l'enseignant » n'existe que sur une classe que le serveur dit
/// affectable par la personne connectee. Un seul bouton plein (K-56).
///
/// Etats : chargement (`Skeleton`), contenu, vide (`EmptyState`), erreur
/// (`EtatSysteme`, « Reessayer »), hors ligne (le bandeau de `PageShell` ;
/// `EtatSansDonnees` seulement si rien n'a pu etre lu), et port absent
/// (« disponible au branchement serveur »).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/port_classes_admin.dart';
import '../../core/admin/port_pilotage.dart';
import '../../core/admin/service_groupes.dart' show TypePublicGroupe;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/i18n/villes_fuseau.dart';
import '../../core/icons/app_icons.dart';
import '../../core/offres/port_regroupements_admin.dart'
    show RegroupementDemandes;
import '../../core/reseau/etat_sans_donnees.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/carte_lignes.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_regroupements/feuille_classe_regroupement.dart';
import '../admin_regroupements/regroupements_libelles.dart'
    show libelleHeureMinute;
import '../creneaux/plages.dart' show jourCapitalise;
import 'pilotage_libelles.dart';

/// Combien de classes en attente l'ecran met en avant : les premieres, le
/// reste est une page de la liste des classes.
const int classesEnAvant = 5;

/// L'ecran « Pilotage des horaires ».
class PilotagePage extends ConsumerStatefulWidget {
  /// Cree l'ecran.
  const PilotagePage({super.key});

  @override
  ConsumerState<PilotagePage> createState() => _PilotagePageEtat();
}

class _PilotagePageEtat extends ConsumerState<PilotagePage> {
  /// Le filtre courant : public, jour, heure, fuseau, signal.
  FiltrePilotage _filtre = const FiltrePilotage();

  /// La page courante, a partir de 1. Revient a 1 a chaque changement de
  /// filtre.
  int _page = 1;

  /// La derniere page lue : ses compteurs et ses valeurs de filtre restent
  /// affiches pendant qu'une autre page se charge.
  PagePilotage? _derniere;

  void _filtrer(FiltrePilotage filtre) => setState(() {
    _filtre = filtre;
    _page = 1;
  });

  void _relire() => ref
    ..invalidate(pagePilotageProvider)
    ..invalidate(pageClassesAdminProvider);

  Widget _filtres(PagePilotage? reference) {
    final l = t.admin.pilotage;
    final lg = t.admin.groupes.liste;
    int? compte(SignalPilotage s) => reference?.compteurs[s];
    FilterPill pastille(
      SignalPilotage? signal,
      String libelle,
      int? compteur,
      String cle,
    ) => FilterPill(
      key: ValueKey<String>(cle),
      libelle: libelle,
      compteur: compteur,
      retenue: _filtre.signal == signal,
      onPress: () => _filtrer(_filtre.avec(signal: () => signal)),
    );
    return RangeeFiltres(
      filtres: <Widget>[
        pastille(
          null,
          l.filtreTous,
          reference?.totalSansFiltre,
          'pilotage-filtre-tous',
        ),
        pastille(
          SignalPilotage.penurie,
          l.filtrePenurie,
          compte(SignalPilotage.penurie),
          'pilotage-filtre-penurie',
        ),
        pastille(
          SignalPilotage.sousMinimum,
          l.filtreSousMinimum,
          compte(SignalPilotage.sousMinimum),
          'pilotage-filtre-sous-minimum',
        ),
        pastille(
          SignalPilotage.attenteEnseignant,
          l.filtreAttente,
          compte(SignalPilotage.attenteEnseignant),
          'pilotage-filtre-attente',
        ),
        MenuFiltre<TypePublicGroupe>(
          key: const ValueKey<String>('pilotage-filtre-public'),
          libelle: l.filtrePublic,
          valeur: _filtre.type,
          entrees: <EntreeFiltre<TypePublicGroupe>>[
            EntreeFiltre<TypePublicGroupe>(
              valeur: null,
              libelle: l.filtreTousPublics,
            ),
            for (final TypePublicGroupe type in TypePublicGroupe.values)
              EntreeFiltre<TypePublicGroupe>(
                valeur: type,
                libelle: libelleCategorie(type),
              ),
          ],
          onChoix: (TypePublicGroupe? type) =>
              _filtrer(_filtre.avec(type: () => type)),
        ),
        MenuFiltre<int>(
          key: const ValueKey<String>('pilotage-filtre-jour'),
          libelle: lg.filtreJour,
          valeur: _filtre.jour,
          entrees: <EntreeFiltre<int>>[
            EntreeFiltre<int>(valeur: null, libelle: lg.filtreTousJours),
            for (final int jour in reference?.jours ?? const <int>[])
              EntreeFiltre<int>(valeur: jour, libelle: jourCapitalise(jour)),
          ],
          onChoix: (int? jour) => _filtrer(_filtre.avec(jour: () => jour)),
        ),
        MenuFiltre<int>(
          key: const ValueKey<String>('pilotage-filtre-heure'),
          libelle: lg.filtreHeure,
          valeur: _filtre.heure,
          entrees: <EntreeFiltre<int>>[
            EntreeFiltre<int>(valeur: null, libelle: lg.filtreToutesHeures),
            for (final int heure in reference?.heures ?? const <int>[])
              EntreeFiltre<int>(
                valeur: heure,
                libelle: libelleHeureMinute(heure, 0),
              ),
          ],
          onChoix: (int? heure) => _filtrer(_filtre.avec(heure: () => heure)),
        ),
        MenuFiltre<String>(
          key: const ValueKey<String>('pilotage-filtre-fuseau'),
          libelle: lg.filtreFuseau,
          valeur: _filtre.fuseau,
          entrees: <EntreeFiltre<String>>[
            EntreeFiltre<String>(valeur: null, libelle: lg.filtreTousFuseaux),
            for (final String fuseau in reference?.fuseaux ?? const <String>[])
              EntreeFiltre<String>(
                valeur: fuseau,
                libelle: villeDuFuseauLibelle(fuseau),
              ),
          ],
          onChoix: (String? fuseau) =>
              _filtrer(_filtre.avec(fuseau: () => fuseau)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final RequetePilotage requete = RequetePilotage(
      filtre: _filtre,
      page: _page,
    );
    final AsyncValue<PagePilotage> lecture = ref.watch(
      pagePilotageProvider(requete),
    );
    if (lecture.hasValue) _derniere = lecture.requireValue;
    final PagePilotage? reference = lecture.value ?? _derniere;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final l = t.admin.pilotage;
    final bool commandes = reference != null && reference.totalSansFiltre > 0;

    return PageShell(
      titre: l.titre,
      sousTitre: l.sousTitre,
      // ONGLETS-COUPE-1 : en cartes, tout defile avec la page ; en tableau,
      // la liste defile seule sous son en-tete colle.
      defilante: !DataCollection.enTableau(context),
      child: ColonneCorps(
        minimumEtire: DataCollection.minimumLisible(context),
        children: <Widget>[
          if (commandes) ...<Widget>[
            _VueEnsemble(resume: reference.resume),
            Ecart.vXl,
          ],
          _ClassesEnAttente(onRelire: _relire),
          if (commandes) ...<Widget>[
            SectionHeader(titre: l.horairesTitre),
            Ecart.vMd,
            _filtres(reference),
            Ecart.vXl,
          ],
          PlaceCollection(
            child: BlocAsynchrone<PagePilotage>(
              key: const ValueKey<String>('pilotage-bloc'),
              valeur: lecture,
              squelette: const Skeleton.liste(lignes: 4),
              onReessayer: _relire,
              estVide: (PagePilotage p) => p.totalSansFiltre == 0,
              vide: EmptyState(
                key: const ValueKey<String>('pilotage-vide'),
                message: l.vide,
                invitation: l.videDetail,
                icone: AppIcons.tableauDeBord,
              ),
              erreurVersEtat: (Object erreur, VoidCallback? reessayer) {
                // Port absent : ni un echec, ni un vide. Rien ne se
                // reessaie.
                if (erreur is CapaciteIndisponible) {
                  return EtatSysteme(
                    key: const ValueKey<String>('pilotage-indisponible'),
                    nature: NatureEtat.indisponible,
                    titre: l.indisponibleTitre,
                    phrase: l.indisponiblePhrase,
                    dependance: erreur.dependance,
                  );
                }
                return horsLigne
                    ? EtatSansDonnees(
                        key: const ValueKey<String>('pilotage-sans-donnees'),
                        quoi: l.sansDonnees,
                        onAction: reessayer,
                      )
                    : EtatSysteme(
                        key: const ValueKey<String>('pilotage-erreur'),
                        nature: NatureEtat.echecServeur,
                        phrase: l.erreur,
                        onAction: reessayer,
                      );
              },
              construire: (PagePilotage page) => _Tableau(
                page: page,
                onPage: (int numero) => setState(() => _page = numero),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Les totaux du jeu filtre : ce que la direction lit d'abord.
class _VueEnsemble extends StatelessWidget {
  const _VueEnsemble({required this.resume});

  final ResumePilotage resume;

  @override
  Widget build(BuildContext context) {
    final l = t.admin.pilotage;
    return Column(
      key: const ValueKey<String>('pilotage-ensemble'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SectionHeader(titre: l.vueEnsemble),
        Ecart.vMd,
        CarteLignes(
          lignes: <Widget>[
            LigneCleValeur(
              cle: l.cleClasses,
              valeur: '${resume.classes}',
              chiffres: true,
            ),
            LigneCleValeur(
              cle: l.cleAttente,
              valeur: '${resume.classesAttenteEnseignant}',
              chiffres: true,
            ),
            LigneCleValeur(
              cle: l.cleSousMinimum,
              valeur: '${resume.classesSousMinimum}',
              chiffres: true,
            ),
            LigneCleValeur(
              cle: l.cleDemandes,
              valeur: '${resume.demandesEnAttente}',
              chiffres: true,
            ),
            LigneCleValeur(
              cle: l.cleLibres,
              valeur: '${resume.enseignantsLibres}',
              chiffres: true,
            ),
            LigneCleValeur(
              cle: l.cleManquants,
              valeur: '${resume.enseignantsManquants}',
              chiffres: true,
            ),
          ],
        ),
      ],
    );
  }
}

/// Les classes qui attendent leur enseignant (R7), mises en avant : les
/// premieres, chacune avec « Choisir l'enseignant » quand le serveur l'ouvre
/// a la personne connectee. Rien n'est rendu quand aucune classe n'attend.
class _ClassesEnAttente extends ConsumerWidget {
  const _ClassesEnAttente({required this.onRelire});

  final VoidCallback onRelire;

  static const RequeteClasses _requete = RequeteClasses(
    filtre: FiltreClasses(etat: EtatClasseListee.attenteEnseignant),
    taille: classesEnAvant,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PageClasses> lecture = ref.watch(
      pageClassesAdminProvider(_requete),
    );
    return BlocAsynchrone<PageClasses>(
      key: const ValueKey<String>('pilotage-attente-bloc'),
      valeur: lecture,
      squelette: const Skeleton.liste(lignes: 2),
      onReessayer: onRelire,
      estVide: (PageClasses p) => p.total == 0,
      vide: const SizedBox.shrink(),
      construire: (PageClasses page) => _SectionAttente(page: page),
    );
  }
}

class _SectionAttente extends StatelessWidget {
  const _SectionAttente({required this.page});

  final PageClasses page;

  @override
  Widget build(BuildContext context) {
    final l = t.admin.pilotage;
    final TextTheme textes = Theme.of(context).textTheme;
    // K-56 : un seul bouton plein, sur la premiere carte qui en porte un.
    final String? principal = page.lignes
        .where((ClasseListee c) => c.peutAffecterEnseignant)
        .firstOrNull
        ?.id;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
      child: Column(
        key: const ValueKey<String>('pilotage-attente'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SectionHeader(titre: l.attenteTitre, compteur: page.total),
          Ecart.vXs,
          TexteSansCoupure(l.attenteDetail, style: textes.bodySmall),
          Ecart.vMd,
          PileCartes(
            children: <Widget>[
              for (final ClasseListee c in page.lignes)
                _CarteAttente(classe: c, principal: c.id == principal),
            ],
          ),
          if (page.total > page.lignes.length) ...<Widget>[
            Ecart.vMd,
            LienFleche(
              key: const ValueKey<String>('pilotage-voir-toutes'),
              libelle: l.voirToutes,
              alignerEnDebut: true,
              onPress: () =>
                  GoRouter.of(context)
                      .go('${Routes.adminOperationsGroupes}?etat=attente'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteAttente extends StatelessWidget {
  const _CarteAttente({required this.classe, required this.principal});

  final ClasseListee classe;

  /// Vrai pour la seule carte dont le bouton est plein (K-56).
  final bool principal;

  Future<void> _ouvrir(BuildContext context, RegroupementDemandes r) {
    final FeuilleClasseRegroupement feuille = FeuilleClasseRegroupement(
      regroupement: r,
    );
    return AppBottomSheet.ouvrir<void>(
      context,
      titre: feuille.titre,
      constructeur: (BuildContext _) => feuille,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final RegroupementDemandes? regroupement = regroupementDeClasse(classe);
    final bool peutAgir = classe.peutAffecterEnseignant && regroupement != null;
    return AppCard(
      key: ValueKey<String>('pilotage-classe-${classe.id}'),
      entete: Semantics(
        header: true,
        child: TexteSansCoupure(classe.nom, style: textes.titleMedium),
      ),
      actions: peutAgir
          ? ActionPrincipale(
              key: ValueKey<String>('pilotage-affecter-${classe.id}'),
              libelle: t.admin.regroupements.choisirEnseignant,
              niveau: principal
                  ? NiveauAction.principale
                  : NiveauAction.secondaire,
              onPress: () => unawaited(_ouvrir(context, regroupement)),
            )
          : null,
      child: TexteSansCoupure(
        t.admin.pilotage.attenteHoraire(
          horaire: libelleHoraire(classe.groupe.creneau),
        ),
        style: textes.bodyMedium,
      ),
    );
  }
}

/// La liste des horaires, une page, avec sa position et sa navigation.
class _Tableau extends StatelessWidget {
  const _Tableau({required this.page, required this.onPage});

  final PagePilotage page;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final l = t.admin.pilotage;
    if (page.lignes.isEmpty) {
      return EmptyState(
        key: const ValueKey<String>('pilotage-aucun-filtre'),
        message: l.aucunAvecCeFiltre,
        invitation: l.aucunAvecCeFiltreDetail,
        registre: RegistreVide.subi,
        icone: AppIcons.rienAAfficher,
      );
    }
    return DataCollection<LignePilotage>(
      key: const ValueKey<String>('pilotage-liste'),
      defileAvecLaPage: !DataCollection.enTableau(context),
      lignes: page.lignes,
      cle: (LignePilotage ligne) => ValueKey<String>(ligne.id),
      piedDePage: Column(
        key: const ValueKey<String>('pilotage-pagination'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Ecart.vLg,
          TexteSansCoupure(
            l.resume(
              debut: '${page.debut}',
              fin: '${page.fin}',
              total: '${page.total}',
            ),
            key: const ValueKey<String>('pilotage-resume'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (page.pages > 1) ...<Widget>[
            Ecart.vSm,
            BarrePrecedentSuivant(
              position: t.commun.formats.pageSur(
                page: '${page.page}',
                total: '${page.pages}',
              ),
              positionSemantique: l.positionSemantique(
                page: '${page.page}',
                total: '${page.pages}',
              ),
              libellePrecedent: l.precedente,
              libelleSuivant: l.suivante,
              onPrecedent: page.page > 1 ? () => onPage(page.page - 1) : null,
              onSuivant: page.page < page.pages
                  ? () => onPage(page.page + 1)
                  : null,
            ),
          ],
        ],
      ),
      colonnes: <ColonneDonnees<LignePilotage>>[
        ColonneDonnees<LignePilotage>(
          titre: l.colonneHoraire,
          role: RoleColonne.identifiante,
          flex: 3,
          texte: (LignePilotage x) => libelleHoraire(x.creneau),
        ),
        ColonneDonnees<LignePilotage>(
          titre: l.colonnePublic,
          flex: 2,
          texte: (LignePilotage x) => libelleCategorie(x.type),
        ),
        ColonneDonnees<LignePilotage>(
          titre: l.colonneClasses,
          flex: 2,
          tabulaire: true,
          texte: (LignePilotage x) => '${x.classes}',
        ),
        ColonneDonnees<LignePilotage>(
          titre: l.colonneRemplissage,
          flex: 3,
          tabulaire: true,
          texte: libelleRemplissage,
        ),
        ColonneDonnees<LignePilotage>(
          titre: l.colonneDemandes,
          flex: 2,
          tabulaire: true,
          texte: (LignePilotage x) => '${x.demandesEnAttente}',
        ),
        ColonneDonnees<LignePilotage>(
          titre: l.colonneLibres,
          flex: 3,
          texte: (LignePilotage x) => libelleCompteParGenre(
            x.parGenre,
            (EnseignantsGenre g) => g.libres,
          ),
        ),
        ColonneDonnees<LignePilotage>(
          titre: l.colonneManquants,
          flex: 3,
          texte: (LignePilotage x) => libelleCompteParGenre(
            x.parGenre,
            (EnseignantsGenre g) => g.manquants,
          ),
        ),
        ColonneDonnees<LignePilotage>(
          titre: l.colonneEtat,
          role: RoleColonne.aPart,
          flex: 3,
          texte: (LignePilotage x) => _libelleSignaux(x).join(', '),
          rendu: (BuildContext _, LignePilotage x) =>
              _Signaux(ligne: x, signaux: _libelleSignaux(x)),
        ),
      ],
    );
  }
}

/// Les mots des signaux d'une ligne, dans l'ordre de leur gravite. Une ligne
/// sans signal est « Couvert ».
List<String> _libelleSignaux(LignePilotage x) {
  final l = t.admin.pilotage;
  return <String>[
    if (x.penurie) l.etatPenurie,
    if (x.classesAttenteEnseignant > 0)
      l.etatAttente(n: x.classesAttenteEnseignant),
    if (x.classesSousMinimum > 0) l.etatSousMinimum(n: x.classesSousMinimum),
    if (!x.aSignaler) l.etatCouvert,
  ];
}

/// Les pastilles d'une ligne : le mot et le ton, jamais la couleur seule.
class _Signaux extends StatelessWidget {
  const _Signaux({required this.ligne, required this.signaux});

  final LignePilotage ligne;
  final List<String> signaux;

  TonEtat _ton(int i) {
    if (!ligne.aSignaler) return TonEtat.succes;
    return i == 0 && ligne.penurie ? TonEtat.alerte : TonEtat.avertissement;
  }

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey<String>('pilotage-signaux-${ligne.id}'),
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.xs,
    children: <Widget>[
      for (final (int i, String mot) in signaux.indexed)
        StatusPill(libelle: mot, ton: _ton(i)),
    ],
  );
}
