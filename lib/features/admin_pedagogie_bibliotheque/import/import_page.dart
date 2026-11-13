/// DEPOT-SIMPLE (directeur, 13/11/2026 : « ça doit rester le strict
/// nécessaire ») : ajouter un document avec le moins de travail possible.
///
/// Ce que la personne fait, et rien d'autre :
/// 1. choisir UN fichier : l'application lit seule son type dans le contenu
///    (`lireFichier`), le nom est prérempli, et l'envoi part aussitôt ; un lien
///    reste possible par un geste discret ;
/// 2. corriger le nom s'il le faut, ajouter une description (facultative) ;
/// 3. dire si le fichier se lit seulement dans l'application ou se télécharge ;
/// 4. dire où le ranger (les rayons viennent du serveur) ;
/// 5. un seul bouton, « Ajouter le document », qui n'est rendu que fichier
///    vérifié (jamais grisé) et mène à la vérification avant publication.
///
/// Tout le reste (âges, étapes, lecture, droits, preuve) a une valeur par
/// défaut sûre ou vit dans « Plus de réglages », replié. La vignette ne se
/// demande plus ici : couverture selon le type, vignette depuis la fiche.
///
/// Le dépôt passe par le port (intention, envoi, confirmation du serveur) ; le
/// client ne choisit jamais la clé de stockage. Chaque échec a sa phrase vraie
/// (`_phraseErreur`) : « connexion » seulement quand rien n'a répondu.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/admin/admin_domaine.dart';
import '../../../core/admin/modeles_bibliotheque_admin.dart';
import '../../../core/admin/port_bibliotheque_admin.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/router/routes.dart';
import '../../../core/tc_bibliotheque/contenu_arabe.dart';
import '../../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../../core/tc_bibliotheque/library_resource.dart';
import '../../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../../../core/widgets/zone_saisie.dart';
import '../catalogue/catalogue_page.dart' show rangBibliotheque;
import '../classement_document.dart';
import '../libelles_bibliotheque.dart';
import '../porte_bibliotheque.dart';
import 'detection_fichier.dart';
import 'selecteur_support.dart';

/// L'ecran « Ajouter un document ». [supportId] : le brouillon que l'on
/// complete, ou `null` pour un nouveau document.
class ImportPage extends StatelessWidget {
  /// Cree l'ecran.
  const ImportPage({this.supportId, super.key});

  /// Le brouillon existant.
  final String? supportId;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: supportId == null
          ? t.admin.bibliotheque.ajouter
          : t.admin.bibliotheque.import.completer,
      entete: SousNavigationDomaine(
        onglets: ongletsPedagogie(),
        indexActif: rangBibliotheque,
      ),
      onRetour: () =>
          GoRouter.of(context).go(Routes.adminPedagogieBibliotheque),
      child: PorteBibliotheque(
        construire:
            (
              BuildContext context,
              PortBibliothequeAdmin port,
              CapacitesBibliotheque capacites,
            ) => capacites.peutImporter
            ? _Import(port: port, supportId: supportId)
            : EtatSysteme(
                key: const ValueKey<String>('import-non-autorise'),
                nature: NatureEtat.accesRefuse,
                titre: t.admin.bibliotheque.titre,
                phrase: t.admin.bibliotheque.catalogue.pasDeAcces,
              ),
      ),
    );
  }
}

/// La phrase vraie d'un echec de depot : une cause, une phrase. « La connexion
/// a coupe » ne se dit que pour `reseau`, quand rien n'a repondu.
String phraseErreurDepot(ErreurUpload? erreur) {
  final e = t.admin.bibliotheque.import.erreurs;
  return switch (erreur) {
    ErreurUpload.taille => e.taille,
    ErreurUpload.type => e.type,
    ErreurUpload.reseau => e.reseau,
    ErreurUpload.refuse => e.refuse,
    ErreurUpload.empreinte => e.empreinte,
    ErreurUpload.nonActive => e.nonActive,
    ErreurUpload.session => e.session,
    ErreurUpload.stockage => e.stockage,
    ErreurUpload.envoi => e.envoi,
    ErreurUpload.reglage => e.reglage,
    ErreurUpload.delai => e.delai,
    // Une cause que l'on ne connait pas n'est pas « la connexion ».
    ErreurUpload.service || null => e.service,
  };
}

/// La cause a afficher quand la demande de depot leve une exception.
ErreurUpload causeDeLaDemande(Object erreur) => switch (erreur) {
  DepotImpossible(:final ErreurUpload cause) => cause,
  BibliothequeNonAutorisee() => ErreurUpload.refuse,
  BibliothequeIntrouvable() => ErreurUpload.refuse,
  BibliothequeHorsLigne() => ErreurUpload.reseau,
  _ => ErreurUpload.service,
};

/// Un depot : le fichier, son intention, sa progression.
class _Depot {
  FichierChoisi? fichier;
  IntentionUpload? intention;
  ProgressionUpload? progression;
  StreamSubscription<ProgressionUpload>? abonnement;

  bool get enCours =>
      progression != null &&
          !progression!.termine &&
          progression!.phase != PhaseUpload.attente
      ? true
      : progression?.phase == PhaseUpload.attente;

  bool get pret => progression?.phase == PhaseUpload.pret;

  void annulerAbonnement() {
    unawaited(abonnement?.cancel());
    abonnement = null;
  }
}

class _Import extends ConsumerStatefulWidget {
  const _Import({required this.port, this.supportId});

  final PortBibliothequeAdmin port;
  final String? supportId;

  @override
  ConsumerState<_Import> createState() => _ImportEtat();
}

const String _accesLecture = 'lecture';
const String _accesTelechargement = 'telechargement';

class _ImportEtat extends ConsumerState<_Import> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _lien = TextEditingController();
  final TextEditingController _source = TextEditingController();
  final TextEditingController _titulaire = TextEditingController();
  final TextEditingController _attribution = TextEditingController();
  final TextEditingController _ecole = TextEditingController();

  /// Le type lu dans le fichier (ou celui du brouillon repris).
  TypeRessource? _type;

  /// La phrase d'un fichier qui n'est pas pris (vide, video, inconnu, lourd).
  String? _refus;

  /// Vrai quand la personne donne un lien a la place d'un fichier.
  bool _parLien = false;

  String _acces = _accesLecture;
  String _rayon = codeRayonCours;
  List<RayonBibliotheque> _rayons = const <RayonBibliotheque>[];
  String? _langue;
  bool _plus = false;

  /// Les tranches cochees ; `null` : le defaut du serveur (les quatre, ou
  /// trois sans les 6 a 9 ans pour un lien, D1).
  Set<String>? _tranches;
  final Set<String> _etapes = <String>{};
  String? _lecture;

  /// Vrai seulement quand le serveur a dit que le depot de fichiers est active.
  /// `null` : pas de reponse ; sans reponse, aucun bouton de fichier.
  bool? _depotActif;
  bool _depotInconnu = false;

  String? _supportId;
  FicheSupport? _existante;
  final _Depot _support = _Depot();
  final _Depot _preuve = _Depot();

  bool _incomplet = false;
  String? _erreur;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _supportId = widget.supportId;
    // L'ecole trop longue retire le bouton d'ajout (D2) : l'ecran la suit.
    _ecole.addListener(_rafraichir);
    unawaited(_initialiser());
  }

  void _rafraichir() {
    if (mounted) setState(() {});
  }

  Future<void> _initialiser() async {
    try {
      // Les rayons viennent du serveur (donnee), jamais d'un ecran.
      final List<RayonBibliotheque> r = await ref
          .read(portCatalogueProvider)
          .rayons();
      if (mounted) setState(() => _rayons = r);
    } on Object {
      // Sans rayons, le document va au rayon des cours (defaut du serveur).
    }
    try {
      final bool actif = await widget.port.depotActif();
      if (mounted) setState(() => _depotActif = actif);
    } on Object {
      if (mounted) setState(() => _depotInconnu = true);
    }
    final String? id = _supportId;
    if (id == null) return;
    try {
      final FicheSupport fiche = await widget.port.fiche(id);
      if (!mounted) return;
      setState(() {
        _existante = fiche;
        _type = fiche.support.type;
        _langue = fiche.support.langue;
        _nom.text = fiche.support.titre;
        _description.text = fiche.description ?? '';
        _rayon = fiche.rayon;
        _parLien = fiche.lienExterne != null;
        _lien.text = fiche.lienExterne ?? '';
        _tranches = <String>{...fiche.tranches};
        _etapes.addAll(fiche.etapes);
        _lecture = fiche.lectureCoran;
        _ecole.text = fiche.ecolePriere ?? '';
        _source.text = fiche.droits.sourceTitre ?? '';
        _titulaire.text = fiche.droits.titulaire ?? '';
        _attribution.text = fiche.droits.attribution ?? '';
        if (fiche.droits.usages.contains(UsageDroit.telechargement)) {
          _acces = _accesTelechargement;
        }
      });
    } on Object {
      if (mounted) setState(() => _erreur = t.admin.bibliotheque.erreur);
    }
  }

  @override
  void dispose() {
    _support.annulerAbonnement();
    _preuve.annulerAbonnement();
    for (final TextEditingController c in <TextEditingController>[
      _nom,
      _description,
      _lien,
      _source,
      _titulaire,
      _attribution,
      _ecole,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Pas de bouton de fichier tant que le serveur n'a pas dit « active ».
  bool get _depotInactif => _depotActif != true;

  /// L'adresse d'un lien est une URL https dont l'hote est un nom de domaine ;
  /// la base la revalide (la regle y est ecrite une fois).
  static final RegExp _https = RegExp(
    r'^https://[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+(:[0-9]{1,5})?([/?#][^\s<>"\\]*)?$',
    caseSensitive: false,
  );

  bool get _lienValide =>
      _https.hasMatch(_lien.text.trim()) &&
      // Une adresse IP n'est pas un lien accepte (la base le refuse aussi).
      !RegExp(r'^https://[0-9.]+([:/?#]|$)').hasMatch(_lien.text.trim());

  /// Le type d'un document donne par un lien : une video si l'adresse est
  /// celle d'un site de videos connu, sinon un lien externe.
  TypeRessource get _typeDuLien =>
      lienDeVideo(_lien.text) ? TypeRessource.video : TypeRessource.lienExterne;

  /// Un lien externe demande sa description (la base la refuse sans elle).
  bool get _descriptionManque =>
      _parLien &&
      _existante == null &&
      _typeDuLien == TypeRessource.lienExterne &&
      _description.text.trim().isEmpty;

  bool get _fichierVerifie =>
      _support.pret || (_existante?.derniereVersion?.empreinte != null);

  /// Les tranches retenues : celles cochees, sinon le defaut (D1 : un lien
  /// exclut les 6 a 9 ans).
  Set<String> get _tranchesEffectives =>
      _tranches ?? (_parLien ? tranchesLienParDefaut : tranchesTout);

  /// Vrai quand « Ajouter le document » peut aboutir : fichier verifie (ou
  /// lien complet), au moins une tranche d'age (D1), une ecole qui tient en
  /// base (D2).
  bool get _pret =>
      _tranchesEffectives.isNotEmpty &&
      ecoleValide(_ecole.text) &&
      (_parLien
          ? (_lienValide || _existante != null) &&
                _nom.text.trim().isNotEmpty &&
                !_descriptionManque
          : _fichierVerifie);

  String get _langueInterface => LocaleSettings.currentLocale.languageCode;

  List<String>? get _tranchesSaisies => _tranches == null
      ? null
      : <String>[
          for (final String c in tranchesProposees)
            if (_tranches!.contains(c)) c,
        ];

  /// La personne choisit un fichier : le type se lit dans le contenu, le nom
  /// est propose, et l'envoi part aussitot.
  Future<void> _choisirFichier() async {
    setState(() {
      _erreur = null;
      _refus = null;
      _incomplet = false;
    });
    final FichierChoisi? fichier = await ref
        .read(selecteurFichierSupportProvider)
        .choisirDocument();
    if (fichier == null || !mounted) return;
    final i = t.admin.bibliotheque.import.simple;
    final LectureFichier lecture = lireFichier(
      fichier.octets,
      nom: fichier.nom,
    );
    if (lecture is FichierRefuse) {
      setState(() {
        _refus = switch (lecture.raison) {
          RefusFichier.vide => i.refus.vide,
          RefusFichier.video => i.refus.video,
          RefusFichier.inconnu => i.refus.inconnu,
          RefusFichier.tropLourd => LibellesGroupe.valeurSeule(
            i.refus.tropLourd(limite: '${lecture.limiteMio}'),
          ),
        };
      });
      return;
    }
    final FichierReconnu reconnu = lecture as FichierReconnu;
    final TypeRessource? attendu = _supportId == null ? null : _type;
    if (attendu != null && attendu != reconnu.type) {
      // Le brouillon existe deja avec un autre type : le serveur refuserait.
      setState(() => _refus = i.typeDifferent(type: libelleType(attendu)));
      return;
    }
    if (_nom.text.trim().isEmpty) _nom.text = nomPropose(fichier.nom);
    final FichierChoisi verifie = FichierChoisi(
      nom: fichier.nom,
      octets: fichier.octets,
      mime: reconnu.mime,
    );
    _support
      ..annulerAbonnement()
      ..fichier = verifie
      ..intention = null;
    setState(() {
      _type = reconnu.type;
      _langue ??= langueDeduite(_nom.text, _langueInterface);
      _support.progression = const ProgressionUpload(
        phase: PhaseUpload.attente,
      );
    });
    await _envoyer(_support, FinaliteUpload.support, verifie);
  }

  /// Cree le brouillon si besoin : il en faut un pour deposer.
  Future<String?> _assurerBrouillon() async {
    if (_supportId != null) return _supportId;
    final TypeRessource? type = _parLien ? _typeDuLien : _type;
    if (type == null) return null;
    final String nom = _nom.text.trim();
    try {
      final String id = await widget.port.creerBrouillon(
        NouveauSupport(
          titre: nom,
          type: type,
          langue: _langue ?? langueDeduite(nom, _langueInterface),
          // Le texte libre de categorie n'est plus demande : le rayon range.
          categorie: '',
          description: _description.text.trim(),
          rayon: _rayon,
          lienExterne: _parLien ? _lien.text.trim() : null,
          etapes: _etapes.toList(),
          tranches: _tranchesSaisies,
          lectureCoran: _lecture,
          ecolePriere: _ecole.text.trim().isEmpty ? null : _ecole.text.trim(),
        ),
      );
      if (mounted) setState(() => _supportId = id);
      return id;
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.admin.bibliotheque.import.erreurs.creation);
      }
      return null;
    }
  }

  void _echec(_Depot depot, ErreurUpload cause) {
    if (!mounted) return;
    setState(
      () => depot.progression = ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: cause,
      ),
    );
  }

  Future<void> _envoyer(
    _Depot depot,
    FinaliteUpload finalite,
    FichierChoisi fichier,
  ) async {
    final String? id = await _assurerBrouillon();
    if (!mounted) return;
    if (id == null) {
      // Le brouillon n'a pas pu etre cree : la phrase est deja a l'ecran.
      setState(() => depot.progression = null);
      return;
    }
    try {
      final IntentionUpload intention = await widget.port.demanderUpload(
        supportId: id,
        fichier: fichier.descriptif,
        finalite: finalite,
      );
      if (!mounted) return;
      depot.intention = intention;
      depot.abonnement = widget.port
          .deposer(uploadId: intention.id, octets: fichier.octets)
          .listen((ProgressionUpload p) {
            if (mounted) setState(() => depot.progression = p);
          }, onError: (Object e) => _echec(depot, causeDeLaDemande(e)));
    } on Object catch (e) {
      // Chaque cause a sa phrase : jamais « connexion » par defaut.
      _echec(depot, causeDeLaDemande(e));
    }
  }

  Future<void> _reessayer() async {
    final FichierChoisi? fichier = _support.fichier;
    if (fichier == null) return;
    _support.annulerAbonnement();
    setState(() {
      _erreur = null;
      _support.progression = const ProgressionUpload(
        phase: PhaseUpload.attente,
      );
    });
    await _envoyer(_support, FinaliteUpload.support, fichier);
  }

  Future<void> _deposerPreuve() async {
    setState(() => _erreur = null);
    final FichierChoisi? fichier = await ref
        .read(selecteurFichierSupportProvider)
        .choisir(TypeRessource.pdf);
    if (fichier == null || !mounted) return;
    _preuve
      ..annulerAbonnement()
      ..fichier = fichier;
    setState(
      () => _preuve.progression = const ProgressionUpload(
        phase: PhaseUpload.attente,
      ),
    );
    await _envoyer(_preuve, FinaliteUpload.preuve, fichier);
  }

  Future<void> _annuler(_Depot depot) async {
    final IntentionUpload? i = depot.intention;
    if (i != null) {
      try {
        await widget.port.annulerUpload(i.id);
      } on Object {
        // L'annulation locale prime : le flux s'arrete.
      }
    }
  }

  /// Le seul bouton : enregistre le nom, la description, le rangement et
  /// l'acces, puis mene a la verification avant publication.
  Future<void> _ajouter() async {
    if (_nom.text.trim().isEmpty) {
      setState(() => _incomplet = true);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      final bool nouveau = _supportId == null;
      final String? id = await _assurerBrouillon();
      if (id == null) return;
      FicheSupport fiche = await widget.port.fiche(id);
      if (!nouveau) {
        // Le brouillon a ete cree au choix du fichier : ce que la personne a
        // corrige depuis (nom, description, rangement, reglages) part ici.
        final ResultatEcriture maj = await widget.port.mettreAJour(
          supportId: id,
          modification: ModificationSupport(
            titre: _nom.text.trim(),
            description: _description.text.trim(),
            rayon: _rayon,
            etapes: _etapes.toList(),
            tranches: _tranchesSaisies,
            lectureCoran: _lecture ?? '',
            ecolePriere: _ecole.text.trim(),
          ),
          revisionAttendue: fiche.revision,
        );
        if (!mounted) return;
        if (maj is! EcritureFaite) {
          setState(() => _erreur = t.admin.bibliotheque.fiche.conflit);
          return;
        }
        fiche = await widget.port.fiche(id);
      }
      final ResultatEcriture r = await widget.port.revoirDroits(
        supportId: id,
        versionId: fiche.derniereVersion?.id ?? '',
        saisie: SaisieDroits(
          sourceTitre: _source.text.trim(),
          titulaire: _titulaire.text.trim(),
          preuveFournie: _preuve.pret || fiche.droits.preuveFournie,
          // L'acces choisi : lire dans l'application et en classe, et le
          // telechargement seulement s'il est permis. Le hors ligne garde ce
          // que la fiche porte deja (rien pour un nouveau document).
          usages: <UsageDroit>{
            UsageDroit.application,
            UsageDroit.classe,
            if (_acces == _accesTelechargement && !_parLien)
              UsageDroit.telechargement,
            if (fiche.droits.usages.contains(UsageDroit.horsLigne))
              UsageDroit.horsLigne,
          },
          attribution: _attribution.text.trim().isEmpty
              ? null
              : _attribution.text.trim(),
          approuver: false,
        ),
        revisionAttendue: fiche.revision,
      );
      if (!mounted) return;
      if (r is EcritureFaite) {
        GoRouter.of(context).go(Routes.adminPedagogieSupportPublication(id));
        return;
      }
      setState(() => _erreur = t.admin.bibliotheque.fiche.conflit);
    } on Object {
      if (mounted) {
        setState(() => _erreur = t.admin.bibliotheque.import.erreurs.droits);
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le reste du formulaire n'apparait qu'une fois le fichier choisi (ou le
    // lien demande) : avant, une seule chose a faire.
    final bool suite =
        _parLien || _support.fichier != null || _existante != null;
    return Column(
      key: const ValueKey<String>('import-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionFichier(),
        if (suite) ...<Widget>[
          Ecart.vLg,
          _sectionDocument(),
          Ecart.vLg,
          _sectionPlus(),
        ],
        Ecart.vLg,
        if (_erreur != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _erreur!,
                key: const ValueKey<String>('import-erreur'),
              ),
            ),
          ),
        _actions(),
      ],
    );
  }

  Widget _titreSection(String texte) => Semantics(
    header: true,
    child: Text(texte, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _sectionFichier() {
    final f = t.admin.bibliotheque.import;
    final FicheSupport? existante = _existante;
    final bool dejaLa = existante?.derniereVersion?.empreinte != null;
    return AppCard(
      key: const ValueKey<String>('import-fichier'),
      entete: _titreSection(f.sections.fichier),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_parLien) ...<Widget>[
            ZoneSaisie(
              controleur: _lien,
              cleChamp: const ValueKey<String>('import-lien'),
              libelle: f.champs.lien,
              maxLignes: 1,
              lectureSeule: existante != null,
              erreur: _lien.text.trim().isNotEmpty && !_lienValide
                  ? f.lienInvalide
                  : null,
              onChanged: (_) => setState(() {}),
              actionClavier: TextInputAction.next,
            ),
            if (existante == null) ...<Widget>[
              Ecart.vSm,
              // D4 : une video se donne par son lien.
              Text(
                f.classement.videoLien,
                key: const ValueKey<String>('import-video-lien'),
              ),
            ],
            if (existante == null && !_depotInactif) ...<Widget>[
              Ecart.vSm,
              LienFleche(
                key: const ValueKey<String>('import-fichier-a-la-place'),
                libelle: f.simple.fichierALaPlace,
                alignerEnDebut: true,
                onPress: () => setState(() => _parLien = false),
              ),
            ],
          ] else if (dejaLa)
            Text(
              f.simple.fichierPresent,
              key: const ValueKey<String>('import-fichier-present'),
            )
          else ...<Widget>[
            if (_support.fichier == null) ...<Widget>[
              Text(f.simple.intro, key: const ValueKey<String>('import-intro')),
              Ecart.vMd,
            ],
            if (_depotActif == false) ...<Widget>[
              Text(
                f.classement.depotInactif,
                key: const ValueKey<String>('import-depot-inactif'),
              ),
              Ecart.vMd,
            ] else if (_depotActif == null && _depotInconnu) ...<Widget>[
              Text(
                f.classement.depotInconnu,
                key: const ValueKey<String>('import-depot-inconnu'),
              ),
              Ecart.vMd,
            ],
            if (!_depotInactif) _blocFichier(),
            if (_refus != null) ...<Widget>[
              Ecart.vSm,
              Semantics(
                liveRegion: true,
                child: Text(
                  _refus!,
                  key: const ValueKey<String>('import-refus'),
                ),
              ),
            ],
            if (existante == null &&
                !_support.pret &&
                !_enEnvoi(_support)) ...<Widget>[
              Ecart.vSm,
              LienFleche(
                key: const ValueKey<String>('import-lien-a-la-place'),
                libelle: f.simple.lienALaPlace,
                alignerEnDebut: true,
                onPress: () => setState(() {
                  _parLien = true;
                  _refus = null;
                }),
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _enEnvoi(_Depot depot) {
    final ProgressionUpload? p = depot.progression;
    return p != null &&
        (p.phase == PhaseUpload.attente ||
            p.phase == PhaseUpload.envoi ||
            p.phase == PhaseUpload.enAttenteConfirmation ||
            p.phase == PhaseUpload.verification);
  }

  String? _phraseEtat(ProgressionUpload? p) {
    final i = t.admin.bibliotheque.import;
    return switch (p?.phase) {
      null => null,
      PhaseUpload.attente => i.etats.attente,
      PhaseUpload.envoi => LibellesGroupe.valeurSeule(
        i.etats.envoi(pourcent: '${((p!.partie) * 100).round()}'),
      ),
      PhaseUpload.enAttenteConfirmation => i.etats.confirmation,
      PhaseUpload.verification => i.etats.verification,
      PhaseUpload.pret => i.etats.pret,
      PhaseUpload.annule => i.etats.annule,
      PhaseUpload.echec => phraseErreurDepot(p!.erreur),
    };
  }

  /// La progression et l'etat d'un depot, avec son annulation.
  List<Widget> _suivi(_Depot depot, String suffixe) {
    final i = t.admin.bibliotheque.import;
    final ProgressionUpload? p = depot.progression;
    final bool enEnvoi = _enEnvoi(depot);
    final String? phrase = _phraseEtat(p);
    return <Widget>[
      if (p != null && enEnvoi) ...<Widget>[
        Ecart.vSm,
        Semantics(
          label: i.progression,
          value: '${((p.partie) * 100).round()} %',
          child: LinearProgressIndicator(
            key: ValueKey<String>('import-progression-$suffixe'),
            value: p.phase == PhaseUpload.attente ? null : p.partie,
          ),
        ),
      ],
      if (phrase != null) ...<Widget>[
        Ecart.vSm,
        Semantics(
          liveRegion: true,
          child: Text(phrase, key: ValueKey<String>('import-etat-$suffixe')),
        ),
      ],
      if (enEnvoi && p!.phase != PhaseUpload.verification) ...<Widget>[
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: ValueKey<String>('import-annuler-$suffixe'),
            libelle: i.annulerDepot,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: () => unawaited(_annuler(depot)),
          ),
        ),
      ],
    ];
  }

  Widget _blocFichier() {
    final i = t.admin.bibliotheque.import;
    final FichierChoisi? fichier = _support.fichier;
    final TypeRessource? type = _type;
    final bool enEnvoi = _enEnvoi(_support);
    final bool echec = _support.progression?.phase == PhaseUpload.echec;
    final TextStyle? corps = Theme.of(context).textTheme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (fichier != null) ...<Widget>[
          // Le nom du fichier est du contenu : s'il est en arabe, il prend la
          // police du contenu arabe et son sens de lecture.
          Text(
            fichier.nom,
            key: const ValueKey<String>('import-nom-support'),
            style: styleContenuArabe(fichier.nom, corps),
            textDirection: commenceParArabe(fichier.nom)
                ? TextDirection.rtl
                : null,
          ),
          if (type != null) ...<Widget>[
            Ecart.vXs,
            Text(
              i.simple.reconnu(type: libelleType(type)),
              key: const ValueKey<String>('import-reconnu'),
            ),
          ],
        ],
        ..._suivi(_support, 'support'),
        // Pas de remplacement concurrent, ni apres verification : le choix
        // revient hors envoi, tant que le fichier n'est pas verifie.
        if (!enEnvoi && !_support.pret) ...<Widget>[
          if (fichier != null) Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            // Choix de formulaire, pas un filtre : reessayer ou changer de fichier
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                if (echec)
                  ActionPrincipale(
                    key: const ValueKey<String>('import-reessayer'),
                    libelle: t.commun.reessayer,
                    niveau: NiveauAction.secondaire,
                    pleineLargeur: false,
                    onPress: () => unawaited(_reessayer()),
                  ),
                ActionPrincipale(
                  key: const ValueKey<String>('import-choisir-support'),
                  libelle: fichier == null ? i.choisirFichier : i.choisirAutre,
                  niveau: echec
                      ? NiveauAction.tertiaire
                      : NiveauAction.secondaire,
                  pleineLargeur: false,
                  onPress: () => unawaited(_choisirFichier()),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionDocument() {
    final f = t.admin.bibliotheque.import;
    final s = f.simple;
    final String langue = _langueInterface;
    return AppCard(
      key: const ValueKey<String>('import-document'),
      entete: _titreSection(f.sections.ressource),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ZoneSaisie(
            controleur: _nom,
            cleChamp: const ValueKey<String>('import-nom'),
            libelle: s.nom,
            maxLignes: 1,
            sens: commenceParArabe(_nom.text) ? TextDirection.rtl : null,
            erreur: _incomplet && _nom.text.trim().isEmpty ? s.nomVide : null,
            onChanged: (_) => setState(() {}),
            actionClavier: TextInputAction.next,
          ),
          Ecart.vMd,
          ZoneSaisie(
            controleur: _description,
            cleChamp: const ValueKey<String>('import-description'),
            libelle: s.description,
            minLignes: 2,
            maxLignes: 4,
            sens: commenceParArabe(_description.text)
                ? TextDirection.rtl
                : null,
            erreur: _descriptionManque ? s.descriptionLien : null,
            onChanged: (_) => setState(() {}),
          ),
          // L'acces ne concerne qu'un fichier : un lien ne se telecharge pas.
          if (!_parLien) ...<Widget>[
            Ecart.vLg,
            Text(s.acces.titre, style: Theme.of(context).textTheme.titleSmall),
            Ecart.vSm,
            ChoiceCardGroup(
              key: const ValueKey<String>('import-acces'),
              autoriserSaisieLibre: false,
              valeurInitiale: ReponseChoix(valeurs: <String>{_acces}),
              options: <OptionChoix>[
                OptionChoix(
                  cle: const ValueKey<String>('import-acces-lecture'),
                  valeur: _accesLecture,
                  libelle: s.acces.lecture,
                  description: s.acces.lectureAide,
                ),
                OptionChoix(
                  cle: const ValueKey<String>('import-acces-telechargement'),
                  valeur: _accesTelechargement,
                  libelle: s.acces.telechargement,
                  description: s.acces.telechargementAide,
                ),
              ],
              onChange: (ReponseChoix r) => setState(
                () => _acces = r.valeurs.isEmpty
                    ? _accesLecture
                    : r.valeurs.first,
              ),
            ),
          ],
          // Le rangement : les rayons que le serveur a semes, jamais un second
          // classement. Sans rayons lus, le document va au rayon des cours.
          if (_rayons.length > 1) ...<Widget>[
            Ecart.vLg,
            Text(
              s.rangement.titre,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Ecart.vSm,
            ChoiceCardGroup(
              key: ValueKey<String>('import-rangement-${_rayons.length}'),
              autoriserSaisieLibre: false,
              valeurInitiale: ReponseChoix(valeurs: <String>{_rayon}),
              options: <OptionChoix>[
                for (final RayonBibliotheque r in _rayons)
                  OptionChoix(
                    cle: ValueKey<String>('import-rayon-${r.code}'),
                    valeur: r.code,
                    libelle: r.titrePour(langue),
                    description: switch (r.code) {
                      codeRayonCours => s.rangement.cours,
                      codeRayonPlusLoin => s.rangement.plusLoin,
                      _ => null,
                    },
                  ),
              ],
              onChange: (ReponseChoix r) => setState(
                () => _rayon = r.valeurs.isEmpty
                    ? codeRayonCours
                    : r.valeurs.first,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// « Plus de reglages », replie : tout ce que la personne n'a pas a toucher
  /// pour ajouter un document, et qui garde une valeur par defaut sure.
  Widget _sectionPlus() {
    final f = t.admin.bibliotheque.import;
    final s = f.simple;
    final d = f.droits;
    final String? langue = _langue;
    return AppCard(
      key: const ValueKey<String>('import-plus'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LienFleche(
            key: const ValueKey<String>('import-plus-bascule'),
            libelle: _plus ? s.moins : s.plus,
            fleche: false,
            alignerEnDebut: true,
            onPress: () => setState(() => _plus = !_plus),
          ),
          if (!_plus)
            Text(s.plusAide, key: const ValueKey<String>('import-plus-aide'))
          else ...<Widget>[
            if (langue != null) ...<Widget>[
              Ecart.vSm,
              Text(
                s.langue(langue: libelleLangue(langue)),
                key: const ValueKey<String>('import-langue'),
              ),
            ],
            Ecart.vMd,
            ChoixTranches(
              choisies: _tranchesEffectives,
              lien: _parLien,
              onChoix: (Set<String> v) => setState(() => _tranches = v),
            ),
            Ecart.vMd,
            ChoixEtapes(
              choisies: _etapes,
              onChoix: (Set<String> v) => setState(() {
                _etapes
                  ..clear()
                  ..addAll(v);
              }),
            ),
            Ecart.vMd,
            ChampsLectureEcole(
              lecture: _lecture,
              onLecture: (String? v) => setState(() => _lecture = v),
              ecole: _ecole,
            ),
            Ecart.vLg,
            Text(
              f.sections.droits,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Ecart.vXs,
            Text(d.aide),
            Ecart.vMd,
            ZoneSaisie(
              controleur: _source,
              cleChamp: const ValueKey<String>('import-source'),
              libelle: d.source,
              maxLignes: 1,
            ),
            Ecart.vMd,
            ZoneSaisie(
              controleur: _titulaire,
              cleChamp: const ValueKey<String>('import-titulaire'),
              libelle: d.titulaire,
              maxLignes: 1,
            ),
            Ecart.vMd,
            ZoneSaisie(
              controleur: _attribution,
              cleChamp: const ValueKey<String>('import-attribution'),
              libelle: d.attribution,
              maxLignes: 2,
            ),
            // La preuve se depose comme un fichier : il lui faut le brouillon,
            // donc le fichier du document d'abord (ou le brouillon repris).
            if (!_depotInactif && _supportId != null) ...<Widget>[
              Ecart.vMd,
              Text(d.preuve, style: Theme.of(context).textTheme.titleSmall),
              if (_preuve.fichier != null) ...<Widget>[
                Ecart.vXs,
                TexteSansCoupure(_preuve.fichier!.nom),
              ],
              ..._suivi(_preuve, 'preuve'),
              if (!_enEnvoi(_preuve)) ...<Widget>[
                Ecart.vSm,
                LienFleche(
                  key: const ValueKey<String>('import-choisir-preuve'),
                  libelle: _preuve.fichier == null
                      ? d.deposerPreuve
                      : f.choisirAutre,
                  alignerEnDebut: true,
                  onPress: () => unawaited(_deposerPreuve()),
                ),
              ],
            ],
            if (_existante?.droits.preuveFournie ?? false) ...<Widget>[
              Ecart.vSm,
              Text(d.preuveDeposee),
            ],
          ],
        ],
      ),
    );
  }

  Widget _actions() {
    final f = t.admin.bibliotheque.import;
    final s = f.simple;
    final bool pret = _pret;
    final String aide = _parLien
        ? s.aideLien
        : (_enEnvoi(_support) ? s.aideEnvoi : s.aideFichier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!pret)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(aide, key: const ValueKey<String>('import-aide')),
          ),
        if (pret)
          ActionPrincipale(
            key: const ValueKey<String>('import-poursuivre'),
            libelle: s.ajouter,
            enCours: _envoi,
            onPress: _envoi ? null : () => unawaited(_ajouter()),
          ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: const ValueKey<String>('import-retour'),
            libelle: f.retour,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: () =>
                GoRouter.of(context).go(Routes.adminPedagogieBibliotheque),
          ),
        ),
      ],
    );
  }
}
