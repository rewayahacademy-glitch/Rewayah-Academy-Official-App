// La feuille d'un geste (`ADM-21`, fiche : « Feuilles d'ADM-21 »,
// `AppBottomSheet` : feuille sur mobile, boite de dialogue sur tablette et
// bureau ; un seul bouton plein chacune).
//
// **Chaque geste passe par une confirmation** : la feuille dit ce qui arrivera
// (K-58, la consequence avant le choix), recueille ce que le geste exige (un
// motif interne, un modele de message, des elements, un moyen, un canal, un
// jour), puis le verbe du geste fait l'envoi. Le geste part avec la **version
// attendue** lue avec le dossier et une **cle d'idempotence** neuve.
//
// - Le succes ne se dit qu'apres la reponse du serveur : la feuille se ferme
//   alors, et la page relit la candidature.
// - Un refus nomme du serveur reste dans la feuille, en mots (K-59) : rien n'a
//   ete fait, et on voit pourquoi. Aucun refus ne se perd en fermant la feuille.
// - Un geste **non confirme** (pas de reponse) garde sa cle : « Reessayer » la
//   rejoue, et le serveur ne le fait pas deux fois. Changer un champ prend une
//   cle neuve : c'est une autre demande.
// - Une candidature qui a change (`ConflitGeste`), un geste interdit depuis
//   l'etat courant (`GesteInterdit`) ou un complement deja clos
//   (`AucunComplement`) n'ont plus de bouton qui puisse aboutir : la feuille ne
//   propose que d'actualiser la candidature.
// - Chaque liste fermee est celle du serveur (`capacites_candidatures().listes`).
//   Une liste que le serveur ne sert pas se dit « Disponible au branchement
//   serveur » a la place du choix, sans bouton.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/candidature/gestes_candidature.dart';
import '../../core/candidature/modeles_candidature.dart';
import '../../core/candidature/modeles_candidature_detail.dart';
import '../../core/candidature/modeles_candidatures_direction.dart';
import '../../core/candidature/port_candidatures_direction.dart';
import '../../core/candidature/port_ma_candidature.dart'
    show nouvelleCleIdempotence;
import '../../core/capacites/capacite_indisponible.dart';
import '../../core/capacites/permission_insuffisante.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/bandeau_attention.dart';
import '../../core/widgets/champ_date.dart';
import '../../core/widgets/choice_card_group.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/zone_saisie.dart';
import 'libelles_candidature.dart';
import 'reponses_candidature.dart';

/// Ce que la feuille rend en se fermant.
enum IssueFeuille {
  /// Le serveur a fait le geste : la page relit la candidature.
  fait,

  /// La candidature a change, ou le geste n'est plus permis : la page la
  /// relit avant tout autre geste.
  relire,
}

/// Ce que le geste a rendu, pour le retour local de la page.
class SortieFeuille {
  /// Cree la sortie.
  const SortieFeuille(this.issue, this.geste, {this.rejoue = false});

  /// L'issue.
  final IssueFeuille issue;

  /// Le geste.
  final GesteCandidature geste;

  /// Vrai quand le serveur a rejoue un geste deja fait.
  final bool rejoue;
}

/// Ouvre la feuille de [geste] et rend ce qu'elle a fait, ou `null` si la
/// personne y a renonce.
Future<SortieFeuille?> ouvrirFeuilleGeste(
  BuildContext context, {
  required GesteCandidature geste,
  required DetailCandidature detail,
  required CapacitesCandidatures capacites,
}) => AppBottomSheet.ouvrir<SortieFeuille>(
  context,
  titre: libelleGeste(geste),
  constructeur: (BuildContext contexte) => FeuilleGeste(
    geste: geste,
    detail: detail,
    capacites: capacites,
    onFini: (SortieFeuille sortie) => Navigator.of(contexte).pop(sortie),
    onAnnuler: () => Navigator.of(contexte).pop(),
  ),
);

/// Le corps de la feuille d'un geste.
class FeuilleGeste extends ConsumerStatefulWidget {
  /// Cree la feuille.
  const FeuilleGeste({
    required this.geste,
    required this.detail,
    required this.capacites,
    required this.onFini,
    required this.onAnnuler,
    super.key,
  });

  /// Le geste.
  final GesteCandidature geste;

  /// Le dossier lu : sa version est la version attendue du geste.
  final DetailCandidature detail;

  /// Les capacites lues au serveur : les listes fermees des gestes.
  final CapacitesCandidatures capacites;

  /// Le geste est fait (ou la candidature doit etre relue).
  final ValueChanged<SortieFeuille> onFini;

  /// La personne renonce.
  final VoidCallback onAnnuler;

  /// La cle de la feuille.
  static const Key cle = ValueKey<String>('feuille-geste');

  /// La cle du bouton qui fait le geste.
  static const Key cleValider = ValueKey<String>('feuille-valider');

  /// La cle du bouton qui renonce.
  static const Key cleAnnuler = ValueKey<String>('feuille-annuler');

  /// La cle du bouton qui relit la candidature.
  static const Key cleRelire = ValueKey<String>('feuille-relire');

  /// La cle du bandeau du refus.
  static const Key cleRefus = ValueKey<String>('feuille-refus');

  /// La cle du champ du motif interne.
  static const Key cleMotif = ValueKey<String>('feuille-motif');

  @override
  ConsumerState<FeuilleGeste> createState() => _EtatFeuille();
}

class _EtatFeuille extends ConsumerState<FeuilleGeste> {
  final TextEditingController _motif = TextEditingController();
  final Set<String> _elements = <String>{};
  String? _modele;
  DateTime? _reprise;
  CanalRetrait? _canal;
  DateTime? _jourDemande;
  String? _moyen;
  String? _responsable;
  bool _responsableChoisi = false;

  bool _enCours = false;
  bool _tente = false;
  RefusGeste? _refus;
  Object? _autre;

  /// La cle d'idempotence du geste en cours : neuve a chaque demande, gardee
  /// seulement pour rejouer un essai non confirme.
  String? _cle;

  GesteCandidature get _geste => widget.geste;

  @override
  void initState() {
    super.initState();
    _responsable = widget.detail.ligne.responsableId;
  }

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  /// Un champ change : c'est une autre demande, avec une autre cle.
  void _modifie(VoidCallback changement) => setState(() {
    changement();
    _cle = null;
    if (_refus is GesteNonConfirme) {
      _refus = null;
    }
  });

  // --- Les entrees du serveur --------------------------------------------

  List<String> get _elementsPermis {
    final ListesGestes l = widget.capacites.listes;
    final List<String> codes =
        widget.detail.ligne.etape == EtapeCandidature.verifications
        ? l.complementSalleVerification
        : l.complementSalleExamen;
    return <String>[
      for (final String c in codes)
        if (libelleElementComplement(c) != null) c,
    ];
  }

  List<String> get _modelesPermis => _geste == GesteCandidature.refuser
      ? widget.capacites.listes.modelesRefus
      : widget.capacites.listes.modelesPause;

  List<CanalRetrait> get _canauxPermis => <CanalRetrait>[
    for (final String c in widget.capacites.listes.canauxRetrait)
      if (CanalRetrait.depuisSql(c) case final CanalRetrait canal) canal,
  ];

  String get _codeCloture =>
      widget.capacites.listes.codesClotureComplement.isEmpty
      ? 'complement_clos'
      : widget.capacites.listes.codesClotureComplement.first;

  /// Le motif interne se saisit, sauf pour le complement : la liste nommee des
  /// elements choisis EST son motif (fiche `ADM-21`, « Aucun motif interne, aucun
  /// texte libre » ; contrat des ports, « Motif exige pour `demanderComplement` :
  /// liste nommee des elements manquants »). Le serveur exige pourtant un motif
  /// non vide (`motif_requis`, transitions 7 et 23) : il part, deduit de la
  /// liste, sans que la direction ait a l'ecrire (K-57 : deduit > choisi > saisi).
  bool get _exigeMotif =>
      _geste.exigeMotif && _geste != GesteCandidature.demanderComplement;

  /// Le motif d'une demande de complement : les elements choisis, nommes, dans
  /// l'ordre de la liste du serveur.
  String get _motifComplement => <String>[
    for (final String code in _elementsPermis)
      if (_elements.contains(code)) libelleElementComplement(code)!,
  ].join(t.recrutement.parcours.creneaux.separateurListe);

  // --- Validation et envoi -----------------------------------------------

  /// Ce qui manque, dans l'ordre de la feuille. Vide : la demande est prete.
  bool get _complet {
    if (_exigeMotif && _motif.text.trim().isEmpty) return false;
    switch (_geste) {
      case GesteCandidature.demanderComplement:
        return _elements.isNotEmpty;
      case GesteCandidature.mettreEnPause:
      case GesteCandidature.refuser:
        return _modele != null;
      case GesteCandidature.consignerRetrait:
        return _canal != null && _jourDemande != null;
      case GesteCandidature.confirmerMoyenPaiement:
      case GesteCandidature.infirmerMoyenPaiement:
        return _moyen != null;
      case GesteCandidature.definirResponsable:
        return _responsableChoisi;
      default:
        return true;
    }
  }

  MoyenVersement? _moyenChoisi() {
    final String? m = _moyen;
    if (m == null) return null;
    return m == _valeurVirement
        ? const MoyenVersement.virement()
        : MoyenVersement.mobile(m.substring(_prefixeMobile.length));
  }

  DemandeGeste _demande() {
    final String id = widget.detail.ligne.id;
    final int version = widget.detail.version;
    final String cle = _cle ??= nouvelleCleIdempotence();
    final String motif = _motif.text.trim();
    switch (_geste) {
      case GesteCandidature.demanderComplement:
        return DemandeGeste.demanderComplement(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          elements: _elementsPermis.where(_elements.contains).toList(),
          motif: _motifComplement,
        );
      case GesteCandidature.cloreComplement:
        return DemandeGeste.cloreComplement(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          motif: motif,
          codeCloture: _codeCloture,
        );
      case GesteCandidature.admettreVerifications:
        return DemandeGeste.admettreVerifications(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
        );
      case GesteCandidature.confirmerMoyenPaiement:
        return DemandeGeste.confirmerMoyenPaiement(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          moyen: _moyenChoisi()!,
        );
      case GesteCandidature.infirmerMoyenPaiement:
        return DemandeGeste.infirmerMoyenPaiement(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          moyen: _moyenChoisi()!,
          motif: motif,
        );
      case GesteCandidature.mettreEnPause:
        return DemandeGeste.mettreEnPause(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          motif: motif,
          modele: _modele!,
          repriseLe: _reprise,
        );
      case GesteCandidature.leverPause:
        return DemandeGeste.leverPause(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
        );
      case GesteCandidature.refuser:
        return DemandeGeste.refuser(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          motif: motif,
          modele: _modele!,
        );
      case GesteCandidature.consignerRetrait:
        return DemandeGeste.consignerRetrait(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          canal: _canal!,
          demandeRecueLe: _jourDemande!,
          motif: motif,
        );
      case GesteCandidature.rouvrir:
        return DemandeGeste.rouvrir(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          motif: motif,
        );
      case GesteCandidature.definirResponsable:
        return DemandeGeste.definirResponsable(
          candidatureId: id,
          versionAttendue: version,
          cleIdempotence: cle,
          responsableId: _responsable,
        );
    }
  }

  Future<void> _envoyer() async {
    if (_enCours) return;
    if (!_complet) {
      // Rien n'est envoye : chaque champ qui manque le dit, nomme.
      setState(() => _tente = true);
      return;
    }
    final PortCandidaturesDirection? port = ref.read(
      portCandidaturesDirectionProvider,
    );
    setState(() {
      _enCours = true;
      _refus = null;
      _autre = null;
    });
    try {
      if (port == null) {
        throw const CapaciteIndisponible(dependanceGestesCandidature);
      }
      final ResultatGeste resultat = await port.geste(_demande());
      if (!mounted) return;
      widget.onFini(
        SortieFeuille(IssueFeuille.fait, _geste, rejoue: resultat.rejoue),
      );
    } on GesteNonConfirme catch (e) {
      // La cle est gardee : « Reessayer » rejoue le meme geste.
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _refus = e;
      });
    } on RefusGeste catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _refus = e;
        // Un refus nomme n'a rien ecrit : un nouvel essai est une autre demande.
        _cle = null;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _autre = e;
        // Une panne que l'on ne sait pas dire : le geste a pu partir. La meme
        // cle est gardee pour que l'essai suivant le rejoue au lieu de le
        // refaire : si le premier est passe, le serveur le dit (`rejoue`).
        // Les deux refus rendus (hors portee, absente) n'ont rien ecrit, et la
        // feuille ne propose alors que d'actualiser.
      });
    }
  }

  // --- Rendu -------------------------------------------------------------

  static const String _valeurVirement = 'virement';
  static const String _prefixeMobile = 'mobile:';

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final RefusGeste? refus = _refus;
    final bool aRelire =
        refus is ConflitGeste ||
        refus is GesteInterdit ||
        refus is AucunComplement ||
        _autre is CandidatureIntrouvable ||
        _autre is CandidatureHorsPortee;

    final List<Widget> champs = _champs(context);
    final bool servi = _servi;

    return Column(
      key: FeuilleGeste.cle,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          libelleConsequence(_geste),
          style: palette.surfaceRaised.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        ...champs,
        if (refus != null || _autre != null) ...<Widget>[
          Ecart.vLg,
          _bandeauRefus(),
        ],
        Ecart.vXxl,
        if (aRelire || servi)
          ActionPrincipale(
            key: aRelire ? FeuilleGeste.cleRelire : FeuilleGeste.cleValider,
            libelle: aRelire
                ? t.admin.candidatures.feuille.actualiser
                : refus is GesteNonConfirme
                ? t.commun.reessayer
                : _libelleBouton,
            onPress: aRelire
                ? () =>
                      widget.onFini(SortieFeuille(IssueFeuille.relire, _geste))
                : _envoyer,
            enCours: !aRelire && _enCours,
            niveau: !aRelire && _geste.destructif
                ? NiveauAction.destructive
                : NiveauAction.principale,
          ),
        Ecart.vMd,
        ActionPrincipale(
          key: FeuilleGeste.cleAnnuler,
          libelle: t.commun.annuler,
          onPress: widget.onAnnuler,
          niveau: NiveauAction.secondaire,
        ),
      ],
    );
  }

  /// Vrai quand tout ce que le geste choisit est servi : sinon la feuille le
  /// dit et n'offre aucun bouton qui ne puisse pas aboutir.
  bool get _servi {
    switch (_geste) {
      case GesteCandidature.demanderComplement:
        return _elementsPermis.isNotEmpty;
      case GesteCandidature.mettreEnPause:
      case GesteCandidature.refuser:
        return _modelesPermis.isNotEmpty;
      case GesteCandidature.consignerRetrait:
        return _canauxPermis.isNotEmpty;
      case GesteCandidature.confirmerMoyenPaiement:
      case GesteCandidature.infirmerMoyenPaiement:
        return _moyensDeclares().isNotEmpty;
      case GesteCandidature.definirResponsable:
        return ref
            .watch(responsablesPossiblesProvider(widget.detail.ligne.id))
            .hasValue;
      default:
        return true;
    }
  }

  String get _libelleBouton => _geste == GesteCandidature.definirResponsable
      ? t.com.socle.lexique.enregistrer
      : libelleGeste(_geste);

  List<Widget> _champs(BuildContext context) {
    final f = t.admin.candidatures.feuille;
    final bool modele = _geste.exigeModele;
    return <Widget>[
      if (_geste == GesteCandidature.demanderComplement)
        ..._champElements(context),
      if (_geste == GesteCandidature.mettreEnPause ||
          _geste == GesteCandidature.refuser)
        ..._champModele(context),
      if (_geste == GesteCandidature.mettreEnPause) ..._champReprise(context),
      if (_geste == GesteCandidature.consignerRetrait)
        ..._champsRetrait(context),
      if (_geste == GesteCandidature.confirmerMoyenPaiement ||
          _geste == GesteCandidature.infirmerMoyenPaiement)
        ..._champMoyen(context),
      if (_geste == GesteCandidature.definirResponsable)
        ..._champResponsable(context),
      if (_exigeMotif) ...<Widget>[
        Ecart.vLg,
        ZoneSaisie(
          cleChamp: FeuilleGeste.cleMotif,
          controleur: _motif,
          libelle: f.motif,
          explication: modele ? f.motifAide : f.motifSeul,
          erreur: _tente && _motif.text.trim().isEmpty ? f.motifManquant : null,
          minLignes: 3,
          onChanged: (String _) => _modifie(() {}),
        ),
      ],
    ];
  }

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

  Widget _indisponible() => EtatSysteme(
    nature: NatureEtat.indisponible,
    titre: t.commun.etats.branchementServeur,
    phrase: '',
  );

  List<Widget> _champElements(BuildContext context) {
    final c = t.admin.candidatures.complement;
    final List<String> permis = _elementsPermis;
    return <Widget>[
      Ecart.vLg,
      _titreChamp(c.elements),
      Ecart.vSm,
      if (permis.isEmpty)
        _indisponible()
      else ...<Widget>[
        ChoiceCardGroup(
          selectionMultiple: true,
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final String code in permis)
              OptionChoix(
                cle: ValueKey<String>('element-$code'),
                valeur: code,
                libelle: libelleElementComplement(code)!,
              ),
          ],
          valeurInitiale: ReponseChoix(valeurs: Set<String>.of(_elements)),
          onChange: (ReponseChoix r) => _modifie(() {
            _elements
              ..clear()
              ..addAll(r.valeurs);
          }),
        ),
        Ecart.vSm,
        TexteSansCoupure(
          c.aide,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        if (_tente && _elements.isEmpty) _erreurChamp(c.manquant),
      ],
    ];
  }

  List<Widget> _champModele(BuildContext context) {
    final f = t.admin.candidatures.feuille;
    final List<String> permis = _modelesPermis;
    return <Widget>[
      Ecart.vLg,
      _titreChamp(f.modele),
      Ecart.vSm,
      if (permis.isEmpty)
        _indisponible()
      else ...<Widget>[
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final String code in permis)
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
        TexteSansCoupure(
          f.modeleLu,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        if (_tente && _modele == null) _erreurChamp(f.modeleManquant),
      ],
    ];
  }

  /// Le jour d'aujourd'hui **tel que le serveur le compte** : le jour UTC
  /// (`reprise_le` posterieure au jour UTC courant, `demande_recue_le` ni
  /// future ni anterieure a la reception, en jours UTC). Lu dans l'heure UTC,
  /// jamais dans celle de l'appareil : de quelques heures par jour, le jour
  /// local differe du jour UTC, et un jour permis ici serait refuse la-bas.
  DateTime get _aujourdhuiUtc {
    final DateTime u = ref.read(horlogeFormulairesProvider)().toUtc();
    return DateTime(u.year, u.month, u.day);
  }

  /// Le lendemain, en jour UTC : la premiere reprise permise.
  DateTime get _demain {
    final DateTime a = _aujourdhuiUtc;
    return DateTime(a.year, a.month, a.day + 1);
  }

  List<Widget> _champReprise(BuildContext context) {
    final p = t.admin.candidatures.pause;
    return <Widget>[
      Ecart.vLg,
      ChampDate(
        libelle: p.reprise,
        valeur: _reprise,
        aujourdhui: _demain,
        aide: p.repriseAide,
        onChoix: (DateTime jour) => _modifie(() => _reprise = jour),
      ),
      if (_reprise != null) ...<Widget>[
        Ecart.vSm,
        LienFleche(
          libelle: p.effacerReprise,
          fleche: false,
          alignerEnDebut: true,
          onPress: () => _modifie(() => _reprise = null),
        ),
      ],
    ];
  }

  List<Widget> _champsRetrait(BuildContext context) {
    final r = t.admin.candidatures.retrait;
    final List<CanalRetrait> canaux = _canauxPermis;
    final DateTime aujourdhui = _aujourdhuiUtc;
    final DateTime? recueUtc = widget.detail.ligne.recueLe?.toUtc();
    final DateTime? recue = recueUtc == null
        ? null
        : DateTime(recueUtc.year, recueUtc.month, recueUtc.day);
    return <Widget>[
      Ecart.vLg,
      _titreChamp(r.canal),
      Ecart.vSm,
      if (canaux.isEmpty)
        _indisponible()
      else ...<Widget>[
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final CanalRetrait c in canaux)
              OptionChoix(
                cle: ValueKey<String>('canal-${c.valeurSql}'),
                valeur: c.valeurSql,
                libelle: switch (c) {
                  CanalRetrait.conversation => r.canaux.conversation,
                  CanalRetrait.courriel => r.canaux.courriel,
                },
              ),
          ],
          valeurInitiale: _canal == null
              ? null
              : ReponseChoix(valeurs: <String>{_canal!.valeurSql}),
          onChange: (ReponseChoix choix) => _modifie(() {
            _canal = choix.valeurs.isEmpty
                ? null
                : CanalRetrait.depuisSql(choix.valeurs.first);
          }),
        ),
        if (_tente && _canal == null) _erreurChamp(r.canalManquant),
        Ecart.vLg,
        ChampDate(
          libelle: r.date,
          valeur: _jourDemande,
          aujourdhui: recue ?? aujourdhui,
          dernier: aujourdhui,
          aide: r.aide,
          onChoix: (DateTime jour) => _modifie(() => _jourDemande = jour),
        ),
        if (_tente && _jourDemande == null) _erreurChamp(r.dateManquante),
      ],
    ];
  }

  /// Les moyens que la personne a declares : le virement bancaire si elle a un
  /// compte, et chaque operateur de monnaie mobile. Jamais un moyen invente.
  List<({String valeur, String libelle})> _moyensDeclares() {
    final DeclarationVersement d = declarationVersement(widget.detail);
    final Map<String, String> noms = d.pays == null
        ? const <String, String>{}
        : <String, String>{
            for (final OperateurPaiement o
                in ref
                        .watch(moyensConfirmesDirectionProvider(d.pays!))
                        .value
                        ?.operateurs ??
                    const <OperateurPaiement>[])
              o.code: o.nom,
          };
    final m = t.admin.candidatures.moyens;
    return <({String valeur, String libelle})>[
      if (d.virement) (valeur: _valeurVirement, libelle: m.virement),
      for (final String code in d.operateurs)
        (
          valeur: '$_prefixeMobile$code',
          libelle: noms[code] == null
              ? m.mobileSansNom
              : m.mobile(nom: noms[code]!),
        ),
    ];
  }

  List<Widget> _champMoyen(BuildContext context) {
    final m = t.admin.candidatures.moyens;
    final List<({String valeur, String libelle})> moyens = _moyensDeclares();
    return <Widget>[
      Ecart.vLg,
      _titreChamp(m.titre),
      Ecart.vSm,
      if (moyens.isEmpty)
        TexteSansCoupure(
          m.aucunDeclare,
          key: const ValueKey<String>('feuille-aucun-moyen'),
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        )
      else ...<Widget>[
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            for (final ({String valeur, String libelle}) x in moyens)
              OptionChoix(
                cle: ValueKey<String>('moyen-${x.valeur}'),
                valeur: x.valeur,
                libelle: x.libelle,
              ),
          ],
          valeurInitiale: _moyen == null
              ? null
              : ReponseChoix(valeurs: <String>{_moyen!}),
          onChange: (ReponseChoix r) => _modifie(() {
            _moyen = r.valeurs.isEmpty ? null : r.valeurs.first;
          }),
        ),
        if (_tente && _moyen == null) _erreurChamp(m.manquant),
      ],
    ];
  }

  List<Widget> _champResponsable(BuildContext context) {
    final r = t.admin.candidatures.responsables;
    final AsyncValue<List<ResponsablePossible>> liste = ref.watch(
      responsablesPossiblesProvider(widget.detail.ligne.id),
    );
    return <Widget>[
      Ecart.vLg,
      _titreChamp(t.admin.candidatures.detail.responsable),
      Ecart.vSm,
      if (liste.hasValue) ...<Widget>[
        TexteSansCoupure(
          r.choisir,
          style: AppPalette.of(context).inkMuted.applyTo(
            Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        ChoiceCardGroup(
          autoriserSaisieLibre: false,
          options: <OptionChoix>[
            OptionChoix(
              cle: const ValueKey<String>('responsable-aucun'),
              valeur: '',
              libelle: r.aucun,
            ),
            for (final ResponsablePossible p in liste.requireValue)
              OptionChoix(
                cle: ValueKey<String>('responsable-${p.id}'),
                valeur: p.id,
                libelle: p.nom,
              ),
          ],
          valeurInitiale: ReponseChoix(valeurs: <String>{_responsable ?? ''}),
          onChange: (ReponseChoix choix) => _modifie(() {
            _responsableChoisi = true;
            final String v = choix.valeurs.isEmpty ? '' : choix.valeurs.first;
            _responsable = v.isEmpty ? null : v;
          }),
        ),
        if (_tente && !_responsableChoisi) _erreurChamp(r.choisir),
      ] else if (liste.hasError)
        liste.error is CapaciteIndisponible
            ? _indisponible()
            : EtatSysteme(
                nature: NatureEtat.echecServeur,
                titre: t.admin.candidatures.responsables.lectureEchec,
                phrase: '',
                onAction: () => ref.invalidate(
                  responsablesPossiblesProvider(widget.detail.ligne.id),
                ),
              )
      else
        const Skeleton.texte(lignes: 2),
    ];
  }

  Widget _bandeauRefus() {
    final e = t.admin.candidatures.erreurs;
    final RefusGeste? refus = _refus;
    final Object? autre = _autre;
    final String message;
    final String titre;
    if (refus != null) {
      message = messageRefus(refus);
      titre = refus is GesteNonConfirme ? e.nonConfirmeTitre : e.titre;
    } else if (autre is CandidatureHorsPortee) {
      message = e.horsPortee;
      titre = e.titre;
    } else if (autre is CandidatureIntrouvable) {
      message = e.absente;
      titre = e.titre;
    } else if (autre is PermissionInsuffisante) {
      message = e.permission;
      titre = e.titre;
    } else {
      message = e.generique;
      titre = e.nonConfirmeTitre;
    }
    return BandeauAttention(
      key: FeuilleGeste.cleRefus,
      titre: titre,
      message: message,
      ton: refus is GesteNonConfirme || (refus == null && autre != null)
          ? TonEtat.avertissement
          : TonEtat.alerte,
    );
  }
}
