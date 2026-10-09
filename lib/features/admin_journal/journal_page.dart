import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/admin/admin_domaine.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/journal/service_journal.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/menu_filtre.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/sous_navigation_domaine.dart';
import '../../core/widgets/status_pill.dart';

/// Les trois profondeurs proposees par le filtre de periode.
///
/// Trois, et pas un selecteur de dates : un journal se consulte pour repondre a
/// « que s'est-il passe recemment », pas pour decouper un intervalle au jour
/// pres. Le jour ou la question changera, elle changera pour de vrai.
enum PeriodeJournal {
  /// Les sept derniers jours.
  semaine,

  /// Les trente derniers jours.
  mois,

  /// Depuis la premiere entree.
  tout;

  /// La borne basse a envoyer a la base, ou `null` pour tout.
  DateTime? depuis(DateTime maintenant) => switch (this) {
    PeriodeJournal.semaine => maintenant.subtract(const Duration(days: 7)),
    PeriodeJournal.mois => maintenant.subtract(const Duration(days: 30)),
    PeriodeJournal.tout => null,
  };
}

/// `ADM-04` : le journal d'audit.
///
/// **Le seul ecran du produit sans action principale**, et ce n'est pas un
/// manque : `parcours-utilisateurs.md` section 5 dit « lecture seule, aucun
/// bouton d'action, aucune exception ». La seule chose qu'on puisse faire d'un
/// journal immuable, c'est le lire. Les deux boutons presents ne touchent pas
/// aux donnees : ils relachent un filtre et demandent la page suivante.
///
/// Trois choix de rendu, tous tenus par un test :
///
///   * **l'etat de la chaine est en tete, pas en bas.** `audit_logs` porte
///     `prev_hash` et `hash` depuis l'etape 1, et chaque ecriture paie un
///     verrou de table pour les tenir. Cet ecran est le premier a les relire :
///     sans ce bandeau, la garantie serait payee et jamais constatee ;
///   * **le tableau dense n'apparait qu'au desktop** (`05-regles-responsive.md`
///     section 3). Ailleurs, une carte par entree : un tableau retreci est
///     precisement ce que la regle interdit ;
///   * **un evenement inconnu s'affiche tel quel** plutot que d'etre masque.
///     Le vocabulaire des types vient de la base, et il grandira : un ecran qui
///     n'affiche que ce qu'il sait nommer finirait par cacher les evenements
///     les plus recents, c'est-a-dire les plus interessants.
class JournalPage extends ConsumerStatefulWidget {
  /// Cree l'ecran du journal.
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageEtat();
}

class _JournalPageEtat extends ConsumerState<JournalPage> {
  /// Le nombre d'entrees par page.
  ///
  /// La base refuse au dela de 200 : la borne est ecrite des deux cotes, parce
  /// qu'un ecran qui demanderait 500 recevrait une erreur plutot qu'une page.
  static const int parPage = 50;

  final List<EntreeJournal> _entrees = <EntreeJournal>[];
  String? _acteur;
  String? _type;

  /// La periode ouverte par defaut : tout le journal.
  ///
  /// **Et non « 30 derniers jours »**, qui etait le premier reflexe : un
  /// journal vide se serait alors annonce « aucun evenement ne correspond,
  /// elargissez la periode », c'est-a-dire comme une impasse de filtre, alors
  /// qu'il n'y a simplement rien eu. La pagination borne deja le cout, la
  /// periode n'a pas a le faire une seconde fois.
  PeriodeJournal _periode = PeriodeJournal.tout;
  bool _chargement = true;
  bool _fin = false;
  Object? _erreur;

  bool get _filtre =>
      _acteur != null || _type != null || _periode != PeriodeJournal.tout;

  @override
  void initState() {
    super.initState();
    unawaited(_recharger());
  }

  /// Relit depuis le debut. Tout changement de filtre passe par ici : garder
  /// les entrees deja lues melangerait deux filtres dans une meme liste.
  Future<void> _recharger() async {
    setState(() {
      _entrees.clear();
      _fin = false;
      _erreur = null;
      _chargement = true;
    });
    await _lire(null);
  }

  Future<void> _suite() async {
    if (_chargement || _fin || _entrees.isEmpty) {
      return;
    }
    setState(() => _chargement = true);
    await _lire(CurseurJournal.apres(_entrees.last));
  }

  Future<void> _lire(CurseurJournal? curseur) async {
    try {
      final List<EntreeJournal> page = await ref
          .read(serviceJournalProvider)
          .entrees(
            acteur: _acteur,
            typeEvenement: _type,
            depuis: _periode.depuis(DateTime.now()),
            limite: parPage,
            curseur: curseur,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _entrees.addAll(page);
        // Une page incomplete est la derniere. Une page pleine ne prouve rien :
        // c'est le prochain appel qui dira si le journal continue.
        _fin = page.length < parPage;
        _chargement = false;
      });
    } on Object catch (erreur) {
      if (mounted) {
        setState(() {
          _erreur = erreur;
          _chargement = false;
        });
      }
    }
  }

  void _changerType(String? type) {
    setState(() => _type = type);
    unawaited(_recharger());
  }

  void _changerActeur(String? acteur) {
    setState(() => _acteur = acteur);
    unawaited(_recharger());
  }

  void _changerPeriode(PeriodeJournal periode) {
    setState(() => _periode = periode);
    unawaited(_recharger());
  }

  void _toutEffacer() {
    setState(() {
      _acteur = null;
      _type = null;
      _periode = PeriodeJournal.tout;
    });
    unawaited(_recharger());
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.journal.titre,
      // La collection defile elle-meme : c'est ce qui laisse l'en-tete de
      // colonnes collee en haut du tableau, et les filtres accessibles sans
      // remonter la page.
      defilante: false,
      // PAGESHELL-200-1e : les onglets restent fixes sous le titre ; la
      // chaine et les filtres aussi tant que la place le permet, sinon ils
      // defilent avec le journal (vue basse, alerte urgente ouverte,
      // Interface guidee), decide par delegation le 09/10.
      // Journal et historique des observations : les deux fonctions pairs de
      // Securite et audit (`ongletsSecurite()`), une route chacune.
      entete: SousNavigationDomaine(onglets: ongletsSecurite(), indexActif: 0),
      enteteSecondaire: _Entete(
        acteur: _acteur,
        type: _type,
        periode: _periode,
        onType: _changerType,
        onActeur: _changerActeur,
        onPeriode: _changerPeriode,
      ),
      // Plus d'`Expanded` ici : `PageShell` en mode `defilante: false` borne
      // desormais la hauteur de son contenu lui-meme. L'`Expanded` d'avant
      // n'avait de parent `Flex` que par accident, parce que `PageShell`
      // enveloppait le contenu dans son propre `Column` -- le meme `Column` qui
      // de-bornait la hauteur et faisait disparaitre le corps des ecrans qui,
      // eux, geraient correctement leur defilement.
      child: _Corps(
        entrees: _entrees,
        chargement: _chargement,
        fin: _fin,
        erreur: _erreur,
        filtre: _filtre,
        onSuite: _suite,
        onReessayer: _recharger,
        onEffacerFiltres: _toutEffacer,
      ),
    );
  }
}

/// L'etat de la chaine, puis les trois filtres (sous les onglets, que
/// `PageShell` tient fixes).
class _Entete extends ConsumerWidget {
  const _Entete({
    required this.acteur,
    required this.type,
    required this.periode,
    required this.onType,
    required this.onActeur,
    required this.onPeriode,
  });

  final String? acteur;
  final String? type;
  final PeriodeJournal periode;
  final void Function(String?) onType;
  final void Function(String?) onActeur;
  final void Function(PeriodeJournal) onPeriode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FiltresJournal> filtres = ref.watch(
      filtresJournalProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const BandeauChaineJournal(),
        Ecart.vLg,
        // FILTRES-1 : la periode et les deux menus sur UNE rangee qui defile
        // (`RangeeFiltres`). La periode ne depend d'aucune lecture : elle
        // s'affiche meme quand les filtres de la base n'ont pas pu etre lus.
        //
        // **Deux menus, et non deux rangees de pastilles.** Le vocabulaire
        // d'evenements et la liste des acteurs vivent en base et grandissent
        // a chaque migration : les rendre en pastilles produisait une
        // vingtaine de boutons qui repoussaient le journal sous le pli, et
        // l'accent y decorait un inventaire au lieu de porter la selection.
        // La periode, elle, a trois valeurs fixes : c'est un vrai selecteur,
        // elle reste en pastilles.
        RangeeFiltres(
          filtres: <Widget>[
            for (final PeriodeJournal p in PeriodeJournal.values)
              FilterPill(
                libelle: switch (p) {
                  PeriodeJournal.semaine => t.admin.journal.periodeSemaine,
                  PeriodeJournal.mois => t.admin.journal.periodeMois,
                  PeriodeJournal.tout => t.admin.journal.periodeTout,
                },
                retenue: periode == p,
                onPress: () => onPeriode(p),
              ),
            // Les getters, jamais le type d'execution : Riverpod 3 relance un
            // provider en echec tout seul, et l'etat repasse par
            // `AsyncLoading` en conservant `hasError`.
            if (filtres case AsyncValue<FiltresJournal>(
              hasValue: true,
            )) ...<Widget>[
              MenuFiltre<String>(
                libelle: t.admin.journal.filtreEvenement,
                valeur: type,
                onChoix: onType,
                entrees: <EntreeFiltre<String>>[
                  EntreeFiltre<String>(
                    valeur: null,
                    libelle: t.admin.journal.tousTypes,
                    compteur: filtres.requireValue.total,
                  ),
                  for (final ValeurFiltre v in filtres.requireValue.actions)
                    EntreeFiltre<String>(
                      valeur: v.valeur,
                      libelle: libelleEvenement(v.valeur),
                      compteur: v.nombre,
                    ),
                ],
              ),
              MenuFiltre<String>(
                libelle: t.admin.journal.filtreActeur,
                valeur: acteur,
                onChoix: onActeur,
                entrees: <EntreeFiltre<String>>[
                  EntreeFiltre<String>(
                    valeur: null,
                    libelle: t.admin.journal.tousActeurs,
                    compteur: filtres.requireValue.total,
                  ),
                  for (final ValeurFiltre v in filtres.requireValue.acteurs)
                    EntreeFiltre<String>(
                      valeur: v.valeur,
                      libelle: v.libelle.isEmpty
                          ? t.admin.journal.acteurInconnu
                          : v.libelle,
                      compteur: v.nombre,
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Ce que la chaine de hachage dit de l'integrite du journal.
class BandeauChaineJournal extends ConsumerWidget {
  /// Cree le bandeau.
  const BandeauChaineJournal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<EtatChaine> chaine = ref.watch(chaineJournalProvider);
    final TextTheme textes = Theme.of(context).textTheme;

    final (String libelle, TonEtat ton, String phrase) contenu =
        switch (chaine) {
          AsyncValue<EtatChaine>(hasValue: true) => _lire(chaine.requireValue),
          AsyncValue<EtatChaine>(hasError: true) => (
            t.admin.journal.chaineInconnue,
            TonEtat.neutre,
            t.admin.journal.chaineInconnueDetail,
          ),
          _ => (
            t.admin.journal.chaineEnCours,
            TonEtat.neutre,
            t.admin.journal.chaineEnCoursDetail,
          ),
        };

    final TextStyle stylePhrase = textes.bodySmall ?? const TextStyle();
    return AppCard(
      // PAGESHELL-200-1e : a 320 px en texte x2, la pastille (« Integrite
      // inconnue ») et la phrase cote a cote debordaient de 17 px. Quand la
      // pastille, mesuree telle qu'elle se rend, et le mot le plus long de
      // la phrase ne tiennent pas cote a cote, la pastille passe au-dessus
      // de la phrase, au debut de la ligne (decide par delegation le 09/10).
      child: _PastilleEtPhrase(
        motLePlusLong: largeurMotLePlusLong(
          context,
          contenu.$3,
          stylePhrase,
          MediaQuery.textScalerOf(context),
        ),
        children: <Widget>[
          StatusPill(libelle: contenu.$1, ton: contenu.$2),
          // COUPE-MOTS-1 : la phrase passe a la ligne entre ses mots, jamais
          // dans un mot, ni au trait d'union de « ci-dessous ».
          TexteSansCoupure(
            contenu.$3,
            style: stylePhrase,
            nomsComposesEntiers: true,
          ),
        ],
      ),
    );
  }

  (String, TonEtat, String) _lire(EtatChaine etat) => etat.intacte
      ? (
          t.admin.journal.chaineIntacte,
          TonEtat.succes,
          t.admin.journal.chaineIntacteDetail(nombre: etat.verifiees),
        )
      : (
          t.admin.journal.chaineRompue,
          TonEtat.alerte,
          etat.rompues == 1
              ? t.admin.journal.chaineRompueUne(
                  entree: etat.premiereRompue ?? 0,
                )
              : t.admin.journal.chaineRompueDetail(
                  entree: etat.premiereRompue ?? 0,
                  nombre: etat.rompues,
                ),
        );
}

/// Un etat qui defile si la hauteur manque : la tete du Journal est haute et,
/// sur telephone, l'etat n'y dispose parfois que de quelques pixels (meme
/// choix que `_Defilant` de l'historique des observations).
Widget _defilant(Widget etat) => SingleChildScrollView(child: etat);

/// La liste, et ses cinq etats.
class _Corps extends StatelessWidget {
  const _Corps({
    required this.entrees,
    required this.chargement,
    required this.fin,
    required this.erreur,
    required this.filtre,
    required this.onSuite,
    required this.onReessayer,
    required this.onEffacerFiltres,
  });

  final List<EntreeJournal> entrees;
  final bool chargement;
  final bool fin;
  final Object? erreur;
  final bool filtre;
  final Future<void> Function() onSuite;
  final Future<void> Function() onReessayer;
  final VoidCallback onEffacerFiltres;

  @override
  Widget build(BuildContext context) {
    // L'erreur ne remplace la liste que si rien n'a encore ete lu : une page
    // suivante qui echoue ne doit pas effacer ce que l'administration a deja
    // sous les yeux.
    if (erreur != null && entrees.isEmpty) {
      return _defilant(
        EmptyState(
          message: t.admin.journal.erreur,
          icone: AppIcons.avertissement,
          libelleAction: t.commun.reessayer,
          onAction: () => unawaited(onReessayer()),
        ),
      );
    }

    if (entrees.isEmpty && chargement) {
      // Pas le mot « Chargement » : la forme de ce qui arrive.
      return const Skeleton.liste(lignes: 6);
    }

    if (entrees.isEmpty) {
      // Un journal vide sous filtre est une impasse dont on peut sortir ; un
      // journal vide tout court est une bonne nouvelle, pas une panne
      // (`02-regles-ux.md` section 6).
      return _defilant(
        filtre
            ? EmptyState(
                message: t.admin.journal.videFiltre,
                invitation: t.admin.journal.videFiltreDetail,
                libelleAction: t.admin.journal.effacerFiltres,
                onAction: onEffacerFiltres,
              )
            : EmptyState(
                message: t.admin.journal.vide,
                invitation: t.admin.journal.videDetail,
                registre: RegistreVide.bonneNouvelle,
              ),
      );
    }

    return DataCollection<EntreeJournal>(
      lignes: entrees,
      cle: (EntreeJournal e) => ValueKey<int>(e.id),
      colonnes: colonnesJournal(),
      piedDePage: _PiedDePage(
        chargement: chargement,
        fin: fin,
        erreur: erreur,
        onSuite: onSuite,
      ),
    );
  }
}

/// Ce qui suit la derniere entree lue.
class _PiedDePage extends StatelessWidget {
  const _PiedDePage({
    required this.chargement,
    required this.fin,
    required this.erreur,
    required this.onSuite,
  });

  final bool chargement;
  final bool fin;
  final Object? erreur;
  final Future<void> Function() onSuite;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;

    if (fin) {
      return Center(
        child: Text(
          t.admin.journal.fin,
          style: textes.bodySmall ?? const TextStyle(),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: <Widget>[
        if (erreur != null) ...<Widget>[
          Text(
            t.admin.journal.erreurSuite,
            style: textes.bodySmall ?? const TextStyle(),
            textAlign: TextAlign.center,
          ),
          Ecart.vSm,
        ],
        ActionPrincipale(
          libelle: t.admin.journal.chargerSuite,
          niveau: NiveauAction.secondaire,
          enCours: chargement,
          pleineLargeur: false,
          onPress: chargement ? null : () => unawaited(onSuite()),
        ),
      ],
    );
  }
}

/// Les six colonnes du journal, valables pour le tableau comme pour la carte.
///
/// Exposee plutot que privee : c'est elle que le test de `ADM-04` interroge
/// pour verifier que la colonne identifiante est bien le type d'evenement, sans
/// avoir a deduire la regle du pixel rendu.
List<ColonneDonnees<EntreeJournal>> colonnesJournal() =>
    <ColonneDonnees<EntreeJournal>>[
      ColonneDonnees<EntreeJournal>(
        titre: t.admin.journal.colonneQuand,
        texte: (EntreeJournal e) => t.admin.journal.horodatage(
          date: _date(e.survenuLe),
          heure: _heure(e.survenuLe),
        ),
        tabulaire: true,
        flex: 3,
      ),
      ColonneDonnees<EntreeJournal>(
        titre: t.admin.journal.colonneQui,
        texte: _nomActeur,
        flex: 3,
      ),
      ColonneDonnees<EntreeJournal>(
        titre: t.admin.journal.colonneRole,
        texte: (EntreeJournal e) => libelleRole(e.roleActeur),
        flex: 2,
      ),
      // Le type d'evenement est la colonne identifiante : c'est le titre de la
      // carte en repli. « Qui » ne peut pas l'etre, un journal filtre par
      // acteur repeterait alors le meme titre sur toutes ses cartes.
      ColonneDonnees<EntreeJournal>(
        titre: t.admin.journal.colonneQuoi,
        texte: (EntreeJournal e) => libelleEvenement(e.typeEvenement),
        role: RoleColonne.identifiante,
        flex: 4,
      ),
      ColonneDonnees<EntreeJournal>(
        titre: t.admin.journal.colonneCible,
        texte: (EntreeJournal e) => e.tableVisee,
        flex: 3,
      ),
      ColonneDonnees<EntreeJournal>(
        titre: t.admin.journal.colonneDetail,
        texte: (EntreeJournal e) => resumeDetails(e.details),
        role: RoleColonne.aPart,
        tabulaire: true,
        flex: 5,
      ),
    ];

/// Le nom a afficher pour l'acteur d'une entree.
///
/// Trois cas, et aucun ne doit produire une case vide : une ligne de journal
/// sans auteur lisible est une ligne qu'on ne peut pas opposer a quiconque.
String _nomActeur(EntreeJournal entree) {
  if (entree.parLeSysteme) {
    return t.admin.journal.acteurSysteme;
  }
  final String? nom = entree.nomActeur;
  return nom == null || nom.isEmpty ? t.admin.journal.acteurInconnu : nom;
}

/// Le libelle humain d'un type d'evenement.
///
/// **La valeur brute quand le type est inconnu**, jamais rien : le vocabulaire
/// vit en base et grandira a chaque migration. Un ecran qui n'affiche que ce
/// qu'il sait nommer cacherait les evenements les plus recents, c'est-a-dire
/// ceux qu'on vient justement chercher.
String libelleEvenement(String type) => switch (type) {
  'kyc_read' => t.admin.journal.evtKycLu,
  'kyc_decision' => t.admin.journal.evtKycTranche,
  'profil_cree' => t.admin.journal.evtProfilCree,
  'profil_enfant_cree' => t.admin.journal.evtProfilEnfantCree,
  'appairage_code_cree' => t.admin.journal.evtCodeCree,
  'appairage_consomme' => t.admin.journal.evtAppareilAppaire,
  'appareil_revoque' => t.admin.journal.evtAppareilRevoque,
  'maj_pedagogie' => t.admin.journal.evtPedagogie,
  'affectation_creee' => t.admin.journal.evtAffectationPrise,
  'affectation_attribuee' => t.admin.journal.evtAffectationAttribuee,
  'demande_creee' => t.admin.journal.evtDemandeCreee,
  'demande_tranchee' => t.admin.journal.evtDemandeTranchee,
  'regle_posee' => t.admin.journal.evtReglePosee,
  'regle_close' => t.admin.journal.evtRegleClose,
  // Les cinq ci-dessous manquaient : les lots `AGT-01`, `CTR-01` et `N2` ont
  // ajoute leurs evenements en base sans ajouter leur libelle ici. Le repli
  // faisait alors exactement son travail, et l'ecran affichait
  // `agent_session_opened` a cote de « Dossier d'identite consulte ». La
  // liste de reference est la base elle-meme : les chaines litterales passees
  // a `log_sensitive_access()`.
  'agent_token_issued' => t.admin.journal.evtAgentJetonEmis,
  'agent_token_revoked' => t.admin.journal.evtAgentJetonRevoque,
  'agent_session_opened' => t.admin.journal.evtAgentSessionOuverte,
  'controller_observation_started' => t.admin.journal.evtObservationControleur,
  'video_token_issued' => t.admin.journal.evtJetonVideo,
  // Les trois evenements de l'observation tuteur (`0033`, `0036`, `0037`).
  'observation_entree' => t.admin.journal.evenements.observationEntree,
  'observation_sortie' => t.admin.journal.evenements.observationSortie,
  'observation_politique_groupe_modifiee' =>
    t.admin.journal.evenements.observationPolitiqueGroupeModifiee,
  _ => type,
};

/// Le libelle court d'un role, tel qu'il etait au moment du geste.
String libelleRole(String? role) => switch (role) {
  'admin' => t.admin.journal.roleAdmin,
  'teacher' => t.admin.journal.roleEnseignant,
  'guardian' => t.admin.journal.roleTuteur,
  'student' => t.admin.journal.roleEleve,
  'controller' => t.admin.journal.roleControleur,
  'accountant' => t.admin.journal.roleComptable,
  _ => t.admin.journal.roleAucun,
};

/// Le contenu libre d'une entree, en une ligne.
///
/// Borne a trois couples : le detail complet d'une entree n'a pas sa place dans
/// une ligne de tableau dense, et une ligne qui double de hauteur selon son
/// contenu n'est plus un tableau.
String resumeDetails(Map<String, dynamic> details) {
  if (details.isEmpty) {
    return '';
  }
  final List<String> couples = <String>[];
  for (final MapEntry<String, dynamic> couple in details.entries) {
    if (couples.length == 3) {
      break;
    }
    couples.add('${couple.key} ${couple.value}');
  }
  return couples.join(' · ');
}

String _date(DateTime quand) =>
    '${quand.day.toString().padLeft(2, '0')}/'
    '${quand.month.toString().padLeft(2, '0')}/${quand.year}';

String _heure(DateTime quand) =>
    '${quand.hour.toString().padLeft(2, '0')}:'
    '${quand.minute.toString().padLeft(2, '0')}';

/// La pastille puis la phrase du bandeau de la chaine : cote a cote quand la
/// pastille et le mot le plus long de la phrase y tiennent, sinon la
/// pastille au-dessus de la phrase, au debut de la ligne (PAGESHELL-200-1e).
///
/// La pastille est mesuree par sa propre largeur intrinseque : son style
/// reel (`StatusPill` et son fond), et non une copie de sa geometrie.
class _PastilleEtPhrase extends MultiChildRenderObjectWidget {
  const _PastilleEtPhrase({
    required this.motLePlusLong,
    required super.children,
  }) : assert(children.length == 2, 'une pastille et une phrase');

  /// La largeur du mot le plus long de la phrase, a l'echelle du texte.
  final double motLePlusLong;

  @override
  _RenduPastilleEtPhrase createRenderObject(BuildContext context) =>
      _RenduPastilleEtPhrase(motLePlusLong, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenduPastilleEtPhrase renderObject,
  ) {
    renderObject
      ..motLePlusLong = motLePlusLong
      ..sens = Directionality.of(context);
  }
}

class _DonneesPastilleEtPhrase extends ContainerBoxParentData<RenderBox> {}

class _RenduPastilleEtPhrase extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DonneesPastilleEtPhrase>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DonneesPastilleEtPhrase> {
  _RenduPastilleEtPhrase(this._motLePlusLong, this._sens);

  double _motLePlusLong;
  set motLePlusLong(double valeur) {
    if (valeur != _motLePlusLong) {
      _motLePlusLong = valeur;
      markNeedsLayout();
    }
  }

  TextDirection _sens;
  set sens(TextDirection valeur) {
    if (valeur != _sens) {
      _sens = valeur;
      markNeedsLayout();
    }
  }

  RenderBox get _pastille => firstChild!;
  RenderBox get _phrase => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DonneesPastilleEtPhrase) {
      child.parentData = _DonneesPastilleEtPhrase();
    }
  }

  /// Vrai quand pastille et phrase tiennent cote a cote dans [largeur].
  bool _enRangee(double largeur) =>
      _pastille.getMaxIntrinsicWidth(double.infinity) +
          AppSpacing.md +
          _motLePlusLong <=
      largeur;

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_pastille.getMinIntrinsicWidth(double.infinity), _motLePlusLong);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _pastille.getMaxIntrinsicWidth(double.infinity) +
      AppSpacing.md +
      _phrase.getMaxIntrinsicWidth(double.infinity);

  @override
  double computeMinIntrinsicHeight(double width) => _hauteurPour(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _hauteurPour(width);

  double _hauteurPour(double largeur) {
    if (_enRangee(largeur)) {
      final double pastille = _pastille.getMaxIntrinsicWidth(double.infinity);
      return math.max(
        _pastille.getMinIntrinsicHeight(pastille),
        _phrase.getMinIntrinsicHeight(largeur - pastille - AppSpacing.md),
      );
    }
    return _pastille.getMinIntrinsicHeight(largeur) +
        AppSpacing.sm +
        _phrase.getMinIntrinsicHeight(largeur);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      constraints.constrain(
        Size(constraints.maxWidth, _hauteurPour(constraints.maxWidth)),
      );

  @override
  void performLayout() {
    final double largeur = constraints.maxWidth;
    final _DonneesPastilleEtPhrase donneesPastille =
        _pastille.parentData! as _DonneesPastilleEtPhrase;
    final _DonneesPastilleEtPhrase donneesPhrase =
        _phrase.parentData! as _DonneesPastilleEtPhrase;
    final bool versLaDroite = _sens == TextDirection.ltr;
    if (_enRangee(largeur)) {
      final double pastille = _pastille.getMaxIntrinsicWidth(double.infinity);
      _pastille.layout(
        BoxConstraints(maxWidth: pastille),
        parentUsesSize: true,
      );
      _phrase.layout(
        BoxConstraints.tightFor(
          width: largeur - _pastille.size.width - AppSpacing.md,
        ),
        parentUsesSize: true,
      );
      final double hauteur = math.max(
        _pastille.size.height,
        _phrase.size.height,
      );
      donneesPastille.offset = Offset(
        versLaDroite ? 0 : largeur - _pastille.size.width,
        (hauteur - _pastille.size.height) / 2,
      );
      donneesPhrase.offset = Offset(
        versLaDroite ? _pastille.size.width + AppSpacing.md : 0,
        (hauteur - _phrase.size.height) / 2,
      );
      size = constraints.constrain(Size(largeur, hauteur));
      return;
    }
    _pastille.layout(BoxConstraints(maxWidth: largeur), parentUsesSize: true);
    _phrase.layout(
      BoxConstraints.tightFor(width: largeur),
      parentUsesSize: true,
    );
    donneesPastille.offset = Offset(
      versLaDroite ? 0 : largeur - _pastille.size.width,
      0,
    );
    donneesPhrase.offset = Offset(0, _pastille.size.height + AppSpacing.sm);
    size = constraints.constrain(
      Size(
        largeur,
        _pastille.size.height + AppSpacing.sm + _phrase.size.height,
      ),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
