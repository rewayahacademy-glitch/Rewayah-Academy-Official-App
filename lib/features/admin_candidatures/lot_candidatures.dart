// Le traitement groupe des candidatures (LISTES-1, ex `ADM-22`) : la feuille qui
// mene la direction de la selection au rapport, sur les deux RPC de lot de
// CAND-L2A2 (`apercu_lot_candidats`, `executer_lot_candidats`).
//
// **Quatre temps, dans une seule feuille** (`AppBottomSheet`, un seul bouton
// plein) :
//
//   1. **L'apercu**, lu au serveur : les candidatures que le geste fera, celles
//      qu'il exclut avec leur raison en mots, et le nombre a confirmer. Rien
//      n'est ecrit.
//   2. **Ce que le geste exige**, une fois pour tout le lot : un motif interne,
//      un modele de message, une reprise (pause) ; puis **la saisie du nombre**
//      de candidatures concernees. Le nombre est une saisie de la direction, pas
//      un calcul du client : la feuille ne l'ecrit pas a sa place.
//   3. **L'execution**, avec une cle d'idempotence : elle est **gardee** quand le
//      serveur n'a pas repondu (« Reessayer » rejoue le meme lot, le serveur
//      rend le premier rapport, rien n'est ecrit deux fois) et **remise a
//      neuf** quand un champ change, apres un refus nomme ou un nouvel apercu.
//   4. **Le rapport ligne par ligne** : reussies, exclues, refusees par le
//      serveur. **Rien n'est dit reussi avant la reponse du serveur.**
//
// Le serveur ne sait grouper que trois gestes (mettre en pause, lever la pause,
// refuser) et plafonne a 200 candidatures. Les huit autres se font un par un : la
// barre de la page le dit, la feuille n'en offre aucun. Un lot dont l'apercu a
// change (`jeton_perime`) ne part pas : il faut un nouvel apercu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/modeles_lot_candidatures.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/candidature/port_ma_candidature.dart'
    show nouvelleCleIdempotence;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/champ_etiquete.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import '../admin_candidature/libelles_candidature.dart';

/// Le mot du bouton d'un geste groupe : « Mettre en pause », « Lever la pause »,
/// « Refuser ».
String libelleGesteLot(GesteLot geste) => switch (geste) {
  GesteLot.mettreEnPause => libelleGeste(GesteCandidature.mettreEnPause),
  GesteLot.leverPause => libelleGeste(GesteCandidature.leverPause),
  GesteLot.refuser => t.admin.candidatures.lot.refuser,
};

/// Ce que dit la direction d'une candidature exclue d'un apercu, en mots.
String raisonExclusion(ExclusLot e, GesteLot geste) {
  final r = t.admin.candidatures.lot.feuille.raisons;
  switch (e.raison) {
    case RaisonExclusion.absente:
      return r.absente;
    case RaisonExclusion.horsPortee:
      return r.horsPortee;
    case RaisonExclusion.transitionInterdite:
      if (e.parLaPause) {
        return switch (geste) {
          GesteLot.mettreEnPause => r.dejaEnPause,
          GesteLot.leverPause => r.pasEnPause,
          GesteLot.refuser => r.pause,
        };
      }
      return r.etat(
        etat: libelleEtatCourant(
          issue: e.issue,
          enPause: e.enPause,
          etape: e.etape,
          etat: e.etat,
        ),
      );
    case RaisonExclusion.inconnue:
      return r.inconnue;
  }
}

/// Ce que dit la direction d'une ligne exclue ou refusee d'un rapport, en mots.
/// [exclus] : les exclus de l'apercu, pour dire l'etat de la candidature.
String raisonLigneRapport(
  LigneRapportLot ligne,
  GesteLot geste,
  Map<String, ExclusLot> exclus,
) {
  final r = t.admin.candidatures.lot.feuille.raisons;
  final ExclusLot? e = exclus[ligne.id];
  switch (ligne.raison) {
    case 'absente':
      return r.absente;
    case 'hors_portee':
      return r.horsPortee;
    case 'transition_interdite':
      return e != null
          ? raisonExclusion(e, geste)
          : ligne.parLaPause
          ? raisonExclusion(
              ExclusLot(
                id: ligne.id,
                raison: RaisonExclusion.transitionInterdite,
                parLaPause: true,
              ),
              geste,
            )
          : r.inconnue;
    case 'conflit_candidature':
      return r.conflit;
    case 'erreur_serveur':
      return r.erreurServeur;
    default:
      return r.inconnue;
  }
}

/// Ouvre la feuille du traitement groupe de [ids] pour [geste].
///
/// [onRapport] est appele **des que le serveur a rendu son rapport**, que la
/// feuille soit encore ouverte ou non : la page relit sa liste et vide sa
/// selection, sans attendre la fermeture. La feuille rend le rapport, ou `null`
/// quand la personne y a renonce.
Future<RapportLot?> ouvrirFeuilleLot(
  BuildContext context, {
  required GesteLot geste,
  required List<String> ids,
  required CapacitesCandidatures capacites,
  required ValueChanged<RapportLot> onRapport,
}) => AppBottomSheet.ouvrir<RapportLot>(
  context,
  titre: libelleGesteLot(geste),
  constructeur: (BuildContext contexte) => FeuilleLot(
    geste: geste,
    ids: ids,
    capacites: capacites,
    onRapport: onRapport,
    onFermer: (RapportLot? r) => Navigator.of(contexte).pop(r),
  ),
);

/// Le corps de la feuille du traitement groupe.
class FeuilleLot extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleLot({
    required this.geste,
    required this.ids,
    required this.capacites,
    required this.onRapport,
    required this.onFermer,
    super.key,
  });

  /// Le geste du lot.
  final GesteLot geste;

  /// Les identifiants retenus (1 a [plafondLotCandidatures]).
  final List<String> ids;

  /// Les capacites lues au serveur : les listes fermees des modeles.
  final CapacitesCandidatures capacites;

  /// Le rapport est rendu par le serveur.
  final ValueChanged<RapportLot> onRapport;

  /// La feuille se ferme, avec le rapport ou `null`.
  final ValueChanged<RapportLot?> onFermer;

  /// La cle de la feuille.
  static const Key cle = ValueKey<String>('feuille-lot');

  /// La cle du bouton qui lance le traitement.
  static const Key cleValider = ValueKey<String>('feuille-lot-valider');

  /// La cle du bouton qui renonce.
  static const Key cleAnnuler = ValueKey<String>('feuille-lot-annuler');

  /// La cle du bouton qui relit l'apercu.
  static const Key cleActualiser = ValueKey<String>('feuille-lot-actualiser');

  /// La cle du bouton qui termine.
  static const Key cleTerminer = ValueKey<String>('feuille-lot-terminer');

  /// La cle du champ du nombre a confirmer.
  static const Key cleNombre = ValueKey<String>('feuille-lot-nombre');

  /// La cle du champ du motif interne.
  static const Key cleMotif = ValueKey<String>('feuille-lot-motif');

  /// La cle du bandeau du refus.
  static const Key cleRefus = ValueKey<String>('feuille-lot-refus');

  /// La cle du rapport.
  static const Key cleRapport = ValueKey<String>('feuille-lot-rapport');

  /// La cle de la liste des exclus de l'apercu.
  static const Key cleExclus = ValueKey<String>('feuille-lot-exclus');

  @override
  ConsumerState<FeuilleLot> createState() => _EtatFeuilleLot();
}

class _EtatFeuilleLot extends ConsumerState<FeuilleLot> {
  final TextEditingController _motif = TextEditingController();
  final TextEditingController _nombre = TextEditingController();
  String? _modele;
  DateTime? _reprise;

  ApercuLot? _apercu;
  Object? _erreurApercu;
  RapportLot? _rapport;

  bool _enCours = false;
  bool _tente = false;
  RefusGeste? _refusGeste;
  RefusLot? _refusLot;
  Object? _autre;

  /// La cle d'idempotence du lot en cours : neuve a chaque demande, gardee
  /// seulement pour rejouer un essai non confirme.
  String? _cle;

  GesteLot get _geste => widget.geste;

  @override
  void initState() {
    super.initState();
    _lire();
  }

  @override
  void dispose() {
    _motif.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _lire() async {
    setState(() {
      _apercu = null;
      _erreurApercu = null;
      _refusGeste = null;
      _refusLot = null;
      _autre = null;
      _cle = null;
    });
    final PortCandidaturesDirection? port = ref.read(
      portCandidaturesDirectionProvider,
    );
    try {
      if (port == null) {
        throw const CapaciteIndisponible(dependanceGestesCandidature);
      }
      final ApercuLot apercu = await port.preparerLot(
        geste: _geste,
        ids: widget.ids,
      );
      if (!mounted) return;
      setState(() => _apercu = apercu);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _erreurApercu = e);
    }
  }

  /// Un champ change : c'est une autre demande, avec une autre cle.
  void _modifie(VoidCallback changement) => setState(() {
    changement();
    _cle = null;
    if (_refusGeste is GesteNonConfirme) {
      _refusGeste = null;
    }
  });

  // --- Les entrees du serveur --------------------------------------------

  List<String> get _modelesPermis => _geste == GesteLot.refuser
      ? widget.capacites.listes.modelesRefus
      : widget.capacites.listes.modelesPause;

  int? get _nombreSaisi => int.tryParse(_nombre.text.trim());

  bool get _nombreJuste => _nombreSaisi == _apercu?.nombre;

  bool get _complet {
    final ApercuLot? a = _apercu;
    if (a == null || a.nombre == 0) return false;
    if (a.motifRequis && _motif.text.trim().isEmpty) return false;
    if (a.modeleRequis && _modele == null) return false;
    return _nombreJuste;
  }

  /// Vrai quand tout ce que le geste choisit est servi : sinon la feuille le
  /// dit et n'offre aucun bouton qui ne puisse pas aboutir.
  bool get _servi => _apercu == null
      ? false
      : !(_apercu!.modeleRequis && _modelesPermis.isEmpty);

  // --- Envoi --------------------------------------------------------------

  Future<void> _envoyer() async {
    if (_enCours) return;
    if (!_complet) {
      // Rien n'est envoye : chaque champ qui manque le dit, nomme.
      setState(() => _tente = true);
      return;
    }
    final ApercuLot apercu = _apercu!;
    final PortCandidaturesDirection? port = ref.read(
      portCandidaturesDirectionProvider,
    );
    setState(() {
      _enCours = true;
      _refusGeste = null;
      _refusLot = null;
      _autre = null;
    });
    final String cle = _cle ??= nouvelleCleIdempotence();
    try {
      if (port == null) {
        throw const CapaciteIndisponible(dependanceGestesCandidature);
      }
      final RapportLot rapport = await port.executerLot(
        DemandeLot(
          geste: _geste,
          ids: widget.ids,
          jeton: apercu.jeton,
          nombreConfirme: _nombreSaisi!,
          cleIdempotence: cle,
          motif: apercu.motifRequis ? _motif.text.trim() : null,
          modele: apercu.modeleRequis ? _modele : null,
          repriseLe: _geste == GesteLot.mettreEnPause ? _reprise : null,
        ),
      );
      // La page relit sa liste, que la feuille soit encore la ou non.
      widget.onRapport(rapport);
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _rapport = rapport;
      });
    } on GesteNonConfirme catch (e) {
      // La cle est gardee : « Reessayer » rejoue le meme lot.
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _refusGeste = e;
      });
    } on RefusLot catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _refusLot = e;
        // Un refus nomme n'a rien ecrit : un nouvel essai est une autre demande.
        _cle = null;
      });
    } on RefusGeste catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _refusGeste = e;
        _cle = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _autre = e;
        // Une panne que l'on ne sait pas dire : le lot a pu partir. La meme cle
        // est gardee : si le premier est passe, le serveur rend son rapport.
      });
    }
  }

  // --- Rendu --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final RapportLot? rapport = _rapport;
    return Column(
      key: FeuilleLot.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rapport != null
          ? _rendreRapport(context, rapport)
          : _rendreAvant(context),
    );
  }

  Widget _texte(String texte, {bool fort = false}) => TexteSansCoupure(
    texte,
    style:
        (fort
                ? AppPalette.of(context).inkStrong
                : AppPalette.of(context).inkMuted)
            .applyTo(
              (fort
                      ? Theme.of(context).textTheme.titleSmall
                      : Theme.of(context).textTheme.bodyMedium) ??
                  const TextStyle(),
            ),
  );

  Widget _titreChamp(String texte) => Semantics(
    header: true,
    child: TexteSansCoupure(
      texte,
      style: Theme.of(context).textTheme.titleMedium,
    ),
  );

  Widget _erreurChamp(String texte) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: TexteSansCoupure(
      texte,
      style: AppPalette.of(context).inkAlert
          .applyTo(Theme.of(context).textTheme.bodyMedium ?? const TextStyle()),
    ),
  );

  /// **L'action pleine de la feuille** : une seule a l'ecran (K-56), qu'elle
  /// lance le traitement, relise l'apercu ou termine. Les trois ne se
  /// montrent jamais ensemble.
  Widget _pleine({
    required Key cle,
    required String libelle,
    required VoidCallback onPress,
    bool enCours = false,
    NiveauAction niveau = NiveauAction.principale,
  }) => ActionPrincipale(
    key: cle,
    libelle: libelle,
    onPress: onPress,
    enCours: enCours,
    niveau: niveau,
  );

  Widget _annuler() => ActionPrincipale(
    key: FeuilleLot.cleAnnuler,
    libelle: t.commun.annuler,
    onPress: () => widget.onFermer(null),
    niveau: NiveauAction.secondaire,
  );

  List<Widget> _rendreAvant(BuildContext context) {
    final f = t.admin.candidatures.lot.feuille;
    final ApercuLot? apercu = _apercu;
    final Object? erreur = _erreurApercu;
    if (erreur != null) {
      return <Widget>[
        _texte(f.sousTitre(n: widget.ids.length), fort: true),
        Ecart.vLg,
        _etatErreurApercu(erreur),
        Ecart.vXxl,
        _annuler(),
      ];
    }
    if (apercu == null) {
      return <Widget>[
        _texte(f.sousTitre(n: widget.ids.length), fort: true),
        Ecart.vSm,
        _texte(f.lecture),
        Ecart.vLg,
        const Skeleton.texte(lignes: 3),
        Ecart.vXxl,
        _annuler(),
      ];
    }

    final bool aRelire =
        _refusLot is JetonPerime ||
        _refusLot is AucunEligible ||
        _autre is CandidatureHorsPortee;
    final bool servi = _servi;
    return <Widget>[
      _texte(f.sousTitre(n: widget.ids.length), fort: true),
      Ecart.vSm,
      _texte(_effet()),
      Ecart.vLg,
      ..._rendreApercu(context, apercu),
      if (apercu.nombre > 0 && !aRelire) ...<Widget>[
        ..._champs(context, apercu),
      ],
      if (_refusGeste != null ||
          _refusLot != null ||
          _autre != null) ...<Widget>[Ecart.vLg, _bandeauRefus()],
      Ecart.vXxl,
      if (aRelire)
        _pleine(
          cle: FeuilleLot.cleActualiser,
          libelle: f.actualiserApercu,
          onPress: _lire,
        )
      else if (apercu.nombre > 0 && servi)
        _pleine(
          cle: FeuilleLot.cleValider,
          libelle: _refusGeste is GesteNonConfirme
              ? t.commun.reessayer
              : libelleGesteLot(_geste),
          onPress: _envoyer,
          enCours: _enCours,
          niveau: _geste == GesteLot.refuser
              ? NiveauAction.destructive
              : NiveauAction.principale,
        ),
      Ecart.vMd,
      _annuler(),
    ];
  }

  String _effet() {
    final f = t.admin.candidatures.lot.feuille;
    return switch (_geste) {
      GesteLot.mettreEnPause => f.effetPause,
      GesteLot.leverPause => f.effetLever,
      GesteLot.refuser => f.effetRefuser,
    };
  }

  Widget _etatErreurApercu(Object erreur) {
    final e = t.admin.candidatures.lot.erreurs;
    final String message;
    if (erreur is GesteNonGroupable) {
      message = e.nonGroupable;
    } else if (erreur is PermissionInsuffisante) {
      message = t.admin.candidatures.erreurs.permission;
    } else if (erreur is CapaciteIndisponible) {
      return EtatSysteme(
        nature: NatureEtat.indisponible,
        titre: t.commun.etats.branchementServeur,
        phrase: '',
      );
    } else {
      message = e.lectureApercu;
    }
    return BandeauAttention(
      key: FeuilleLot.cleRefus,
      titre: e.titre,
      message: message,
      ton: erreur is GesteNonGroupable || erreur is PermissionInsuffisante
          ? TonEtat.alerte
          : TonEtat.avertissement,
    );
  }

  /// Les candidatures que le geste fera, puis celles qu'il exclut avec leur
  /// raison : le recapitulatif avant la confirmation.
  List<Widget> _rendreApercu(BuildContext context, ApercuLot a) {
    final f = t.admin.candidatures.lot.feuille;
    const int montreesEligibles = 8;
    const int montreesExclues = 20;
    final List<Widget> sortie = <Widget>[
      Semantics(
        header: true,
        child: _texte(f.seront(n: a.eligibles.length), fort: true),
      ),
      Ecart.vSm,
      for (final EligibleLot e in a.eligibles.take(montreesEligibles))
        _LigneLot(
          nom: _nomDe(e.nomComplet, e.reference),
          reference: e.reference,
        ),
      if (a.eligibles.length > montreesEligibles)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: _texte(f.etAutres(n: a.eligibles.length - montreesEligibles)),
        ),
    ];
    if (a.exclus.isNotEmpty) {
      sortie
        ..add(Ecart.vLg)
        ..add(
          Semantics(
            header: true,
            child: _texte(f.neSeront(n: a.exclus.length), fort: true),
          ),
        )
        ..add(Ecart.vSm)
        ..add(
          Column(
            key: FeuilleLot.cleExclus,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final ExclusLot e in a.exclus.take(montreesExclues))
                _LigneLot(
                  nom: _nomDe(e.nomComplet, e.reference),
                  reference: e.reference,
                  detail: raisonExclusion(e, _geste),
                  icone: AppIcons.avertissement,
                ),
              if (a.exclus.length > montreesExclues)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: _texte(
                    f.etAutres(n: a.exclus.length - montreesExclues),
                  ),
                ),
            ],
          ),
        );
    }
    return sortie;
  }

  String _nomDe(String nom, String reference) => nom.trim().isNotEmpty
      ? nom.trim()
      : reference.isNotEmpty
      ? reference
      : t.admin.candidatures.lot.feuille.rapport.sansNom;

  /// Ce que le geste exige, une fois pour tout le lot, puis le nombre a saisir.
  List<Widget> _champs(BuildContext context, ApercuLot a) {
    final f = t.admin.candidatures.feuille;
    final l = t.admin.candidatures.lot.feuille;
    final List<String> modeles = _modelesPermis;
    return <Widget>[
      if (a.motifRequis || a.modeleRequis) ...<Widget>[
        Ecart.vLg,
        _texte(l.motifCommun),
      ],
      if (a.modeleRequis) ...<Widget>[
        Ecart.vLg,
        _titreChamp(f.modele),
        Ecart.vSm,
        if (modeles.isEmpty)
          EtatSysteme(
            nature: NatureEtat.indisponible,
            titre: t.commun.etats.branchementServeur,
            phrase: '',
          )
        else ...<Widget>[
          ChoiceCardGroup(
            autoriserSaisieLibre: false,
            options: <OptionChoix>[
              for (final String code in modeles)
                OptionChoix(
                  cle: ValueKey<String>('modele-$code'),
                  valeur: code,
                  libelle: libelleModele(code),
                ),
            ],
            valeurInitiale: _modele == null
                ? null
                : ReponseChoix(valeurs: <String>{_modele!}),
            onChange: (ReponseChoix r) => _modifie(() {
              _modele = r.valeurs.isEmpty ? null : r.valeurs.first;
            }),
          ),
          Ecart.vSm,
          _texte(f.modeleLu),
          if (_tente && _modele == null) _erreurChamp(f.modeleManquant),
        ],
      ],
      if (a.motifRequis) ...<Widget>[
        Ecart.vLg,
        ZoneSaisie(
          cleChamp: FeuilleLot.cleMotif,
          controleur: _motif,
          libelle: f.motif,
          explication: a.modeleRequis ? f.motifAide : f.motifSeul,
          erreur: _tente && _motif.text.trim().isEmpty ? f.motifManquant : null,
          minLignes: 3,
          onChanged: (String _) => _modifie(() {}),
        ),
      ],
      if (_geste == GesteLot.mettreEnPause) ...<Widget>[
        Ecart.vLg,
        ChampDate(
          libelle: t.admin.candidatures.pause.reprise,
          valeur: _reprise,
          aujourdhui: _demain,
          aide: t.admin.candidatures.pause.repriseAide,
          onChoix: (DateTime jour) => _modifie(() => _reprise = jour),
        ),
        if (_reprise != null) ...<Widget>[
          Ecart.vSm,
          LienFleche(
            libelle: t.admin.candidatures.pause.effacerReprise,
            fleche: false,
            alignerEnDebut: true,
            onPress: () => _modifie(() => _reprise = null),
          ),
        ],
      ],
      Ecart.vLg,
      ChampEtiquete(
        key: FeuilleLot.cleNombre,
        libelle: l.nombre,
        controller: _nombre,
        keyboardType: TextInputType.number,
        aide: l.nombreAide(n: a.nombre),
        onChanged: (String _) => _modifie(() {}),
      ),
      if (_tente && !_nombreJuste) _erreurChamp(l.nombreFaux(n: a.nombre)),
    ];
  }

  /// Le jour d'aujourd'hui **tel que le serveur le compte** : le jour UTC
  /// (la reprise doit etre posterieure au jour UTC courant).
  DateTime get _demain {
    final DateTime u = ref.read(horlogeFormulairesProvider)().toUtc();
    return DateTime(u.year, u.month, u.day + 1);
  }

  Widget _bandeauRefus() {
    final e = t.admin.candidatures.lot.erreurs;
    final RefusGeste? geste = _refusGeste;
    final RefusLot? lot = _refusLot;
    final Object? autre = _autre;
    final String message;
    final String titre;
    if (geste != null) {
      message = messageRefus(geste);
      titre = geste is GesteNonConfirme
          ? t.admin.candidatures.erreurs.nonConfirmeTitre
          : e.titre;
    } else if (lot != null) {
      titre = e.titre;
      message = switch (lot) {
        JetonPerime() => e.jetonPerime,
        AucunEligible() => e.aucunEligible,
        NombreDiscordant(:final int? nombre) =>
          nombre == null
              ? t.admin.candidatures.lot.feuille.nombreFaux(n: 0)
              : t.admin.candidatures.lot.feuille.nombreFaux(n: nombre),
        GesteNonGroupable() => e.nonGroupable,
        CleLotReutilisee() => e.cleReutilisee,
      };
    } else if (autre is CandidatureHorsPortee) {
      titre = e.titre;
      message = e.horsPortee;
    } else if (autre is PermissionInsuffisante) {
      titre = e.titre;
      message = t.admin.candidatures.erreurs.permission;
    } else {
      titre = t.admin.candidatures.erreurs.nonConfirmeTitre;
      message = t.admin.candidatures.erreurs.generique;
    }
    return BandeauAttention(
      key: FeuilleLot.cleRefus,
      titre: titre,
      message: message,
      ton: geste is GesteNonConfirme || (geste == null && lot == null)
          ? TonEtat.avertissement
          : TonEtat.alerte,
    );
  }

  // --- Le rapport ---------------------------------------------------------

  List<Widget> _rendreRapport(BuildContext context, RapportLot r) {
    final f = t.admin.candidatures.lot.feuille;
    final p = f.rapport;
    final ApercuLot? apercu = _apercu;
    final Map<String, String> noms = <String, String>{
      for (final EligibleLot e in apercu?.eligibles ?? const <EligibleLot>[])
        e.id: _nomDe(e.nomComplet, e.reference),
      for (final ExclusLot e in apercu?.exclus ?? const <ExclusLot>[])
        e.id: _nomDe(e.nomComplet, e.reference),
    };
    final Map<String, ExclusLot> exclus = <String, ExclusLot>{
      for (final ExclusLot e in apercu?.exclus ?? const <ExclusLot>[]) e.id: e,
    };
    String nomLigne(LigneRapportLot l) => noms[l.id] ?? _nomDe('', l.reference);

    final List<LigneRapportLot> reussies = <LigneRapportLot>[
      for (final LigneRapportLot l in r.lignes)
        if (l.issue == IssueLigneLot.reussie) l,
    ];
    final List<LigneRapportLot> autres = <LigneRapportLot>[
      for (final LigneRapportLot l in r.lignes)
        if (l.issue != IssueLigneLot.reussie) l,
    ];
    const int montrees = 8;
    return <Widget>[
      Semantics(header: true, child: _texte(p.titre, fort: true)),
      Ecart.vSm,
      Column(
        key: FeuilleLot.cleRapport,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _texte(p.reussies(n: r.reussies), fort: true),
          if (r.exclues > 0) _texte(p.exclues(n: r.exclues)),
          if (r.refusees > 0) _texte(p.refusees(n: r.refusees)),
          if (r.rejoue) ...<Widget>[Ecart.vSm, _texte(p.rejoue)],
        ],
      ),
      if (autres.isNotEmpty) ...<Widget>[
        Ecart.vLg,
        for (final LigneRapportLot l in autres)
          _LigneLot(
            nom: nomLigne(l),
            reference: l.reference,
            detail: p.ligneEtRaison(
              statut: l.issue == IssueLigneLot.refusee
                  ? p.ligneRefusee
                  : p.ligneExclue,
              raison: raisonLigneRapport(l, r.geste, exclus),
            ),
            icone: AppIcons.avertissement,
          ),
      ],
      if (reussies.isNotEmpty) ...<Widget>[
        Ecart.vLg,
        for (final LigneRapportLot l in reussies.take(montrees))
          _LigneLot(
            nom: nomLigne(l),
            reference: l.reference,
            detail: p.ligneReussie,
            icone: AppIcons.succes,
          ),
        if (reussies.length > montrees)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: _texte(f.etAutres(n: reussies.length - montrees)),
          ),
      ],
      Ecart.vXxl,
      _pleine(
        cle: FeuilleLot.cleTerminer,
        libelle: f.terminer,
        onPress: () => widget.onFermer(r),
      ),
    ];
  }
}

/// Une ligne de la feuille : un nom, sa reference, et ce qui lui arrive.
class _LigneLot extends StatelessWidget {
  const _LigneLot({
    required this.nom,
    required this.reference,
    this.detail,
    this.icone,
  });

  final String nom;
  final String reference;
  final String? detail;
  final AppIcon? icone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icone != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Icon(
                icone!.actif,
                size: AppSpacing.lg,
                color:
                    (icone == AppIcons.succes
                            ? palette.inkSuccess
                            : palette.inkWarning)
                        .asIconTheme()
                        .color,
              ),
            ),
            Ecart.hSm,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TexteSansCoupure(
                  isolerSens(nom),
                  style: palette.inkStrong.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
                if (reference.isNotEmpty)
                  TexteSansCoupure(
                    identifiantInsecable(reference),
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
                if (detail != null)
                  TexteSansCoupure(
                    detail!,
                    style: palette.inkMuted.applyTo(
                      textes.bodySmall ?? const TextStyle(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
