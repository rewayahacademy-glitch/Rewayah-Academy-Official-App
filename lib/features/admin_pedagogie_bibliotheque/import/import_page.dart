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
/// 5. au besoin, ajouter une vignette (facultative, jamais bloquante) ;
/// 6. un seul bouton, « Enregistrer le document », rendu seulement quand il
///    peut aboutir (jamais grisé, une phrase dit ce qui manque) : il publie
///    vraiment (dépôt direct de la direction, migration 20261124700000).
///
/// Chaque dépôt a trois états visibles, jamais par la couleur seule : en
/// cours (barre et pourcentage), réussi (coche, ton de succès, phrase),
/// échoué (alerte, ton d'alerte, phrase vraie, « Réessayer »).
///
/// Tout le reste (âges, étapes, lecture, droits détaillés, preuve) a une
/// valeur par défaut sûre et vit dans « Plus de réglages », replié.
///
/// Le dépôt passe par le port (intention, envoi, confirmation du serveur) ; le
/// client ne choisit jamais la clé de stockage. Chaque échec a sa phrase vraie
/// (`_phraseErreur`) : « connexion » seulement quand rien n'a répondu.
library;

import 'dart:async';
import 'dart:typed_data';

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
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bandeau_attention.dart';
import '../../../core/widgets/choice_card_group.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/status_pill.dart' show TonEtat;
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
    ErreurUpload.vide => e.vide,
    ErreurUpload.nonModifiable => e.nonModifiable,
    ErreurUpload.dejaDepose => e.dejaDepose,
    ErreurUpload.expire => e.expire,
    ErreurUpload.contenu => e.contenu,
    ErreurUpload.introuvable => e.introuvable,
    // Une cause que l'on ne connait pas n'est pas « la connexion ».
    ErreurUpload.service || null => e.service,
  };
}

/// La phrase d'un echec, suivie du NOM du reglage du serveur quand la fonction
/// le donne : la direction sait lequel poser, sans le decouvrir par un echec.
String phraseEchecDepot(ErreurUpload? erreur, String? reglage) {
  final String phrase = phraseErreurDepot(erreur);
  if (reglage == null) return phrase;
  return '$phrase ${t.admin.bibliotheque.import.simple.reglageNomme(nom: reglage)}';
}

/// La taille d'un fichier, lisible : octets, Ko ou Mo.
String tailleLisible(int octets) {
  final s = t.admin.bibliotheque.import.simple;
  String nombre(double v) {
    final String brut = v >= 10 || v == v.roundToDouble()
        ? v.round().toString()
        : v.toStringAsFixed(1);
    // La virgule decimale du francais et de l'arabe.
    return brut.replaceAll('.', ',');
  }

  final String texte = octets < 1024
      ? s.tailleO(n: '$octets')
      : octets < 1024 * 1024
      ? s.tailleKo(n: nombre(octets / 1024))
      : s.tailleMo(n: nombre(octets / (1024 * 1024)));
  return LibellesGroupe.valeurSeule(texte);
}

/// Le reglage nomme par une exception de la demande, s'il y en a un.
String? reglageDeLaDemande(Object erreur) =>
    erreur is DepotImpossible ? erreur.reglage : null;

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

const int _vignetteMaxOctets = 2 * 1024 * 1024;

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

  /// La phrase d'une vignette qui n'est pas prise (pas une image, trop lourde).
  String? _refusVignette;

  /// Vrai quand la personne donne un lien a la place d'un fichier.
  bool _parLien = false;

  AccesDocument _acces = AccesDocument.lecture;
  String _rayon = codeRayonCours;
  List<RayonBibliotheque> _rayons = const <RayonBibliotheque>[];
  String? _langue;
  bool _plus = false;

  /// La declaration « l'academie a le droit de diffuser ce document », exigee
  /// hors du rayon des cours.
  bool _droitTiers = false;

  /// Les tranches cochees ; `null` : le defaut du serveur (les quatre, ou
  /// trois sans les 6 a 9 ans pour un lien, D1).
  Set<String>? _tranches;
  final Set<String> _etapes = <String>{};
  String? _lecture;

  /// Vrai seulement quand le serveur a dit que le depot de fichiers est pret.
  /// `null` : pas de reponse ; sans reponse, aucun bouton de fichier.
  bool? _depotActif;
  bool _depotInconnu = false;

  /// Les reglages de production qui manquent, par leur nom.
  List<String> _manquants = const <String>[];

  String? _supportId;
  FicheSupport? _existante;
  final _Depot _support = _Depot();
  final _Depot _preuve = _Depot();
  final _Depot _vignette = _Depot();

  /// Vrai quand le document porte une vignette (deposee ici, ou deja la).
  bool _vignettePosee = false;
  String? _messageVignette;

  bool _incomplet = false;
  String? _erreur;
  bool _envoi = false;

  /// Vrai quand le document est enregistre et visible : l'ecran le dit.
  bool _enregistre = false;

  /// Vrai quand le document est garde en brouillon sans pouvoir etre publie.
  bool _bloque = false;

  @override
  void initState() {
    super.initState();
    _supportId = widget.supportId;
    // L'ecole trop longue retire le bouton (D2) : l'ecran la suit.
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
    await _lireReglages();
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
        _vignettePosee = fiche.aVignette;
        if (fiche.droits.usages.contains(UsageDroit.telechargement)) {
          _acces = AccesDocument.telechargement;
        }
      });
    } on Object {
      if (mounted) setState(() => _erreur = t.admin.bibliotheque.erreur);
    }
  }

  /// Le depot est-il pret ? La fonction nomme chaque reglage qui manque ; si
  /// elle ne sait pas encore le dire (ancienne version), la base dit au moins
  /// si son secret est pose.
  Future<void> _lireReglages() async {
    try {
      final List<String> manquants = await widget.port.reglagesDepotManquants();
      if (!mounted) return;
      setState(() {
        _manquants = manquants;
        _depotActif = manquants.isEmpty;
      });
      return;
    } on Object {
      // On retombe sur la lecture de la base.
    }
    try {
      final bool actif = await widget.port.depotActif();
      if (mounted) setState(() => _depotActif = actif);
    } on Object {
      if (mounted) setState(() => _depotInconnu = true);
    }
  }

  @override
  void dispose() {
    _support.annulerAbonnement();
    _preuve.annulerAbonnement();
    _vignette.annulerAbonnement();
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

  /// Pas de bouton de fichier tant que le serveur n'a pas dit « pret ».
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
      _lienValide &&
      _typeDuLien == TypeRessource.lienExterne &&
      _description.text.trim().isEmpty;

  bool get _fichierAjoute =>
      _support.pret || (_existante?.derniereVersion?.empreinte != null);

  bool get _lienComplet => _lienValide || _existante != null;

  /// Un document qui ne vient pas de l'academie : la declaration est exigee.
  bool get _tiers => _rayon != codeRayonCours;

  /// Les tranches retenues : celles cochees, sinon le defaut (D1 : un lien
  /// exclut les 6 a 9 ans).
  Set<String> get _tranchesEffectives =>
      _tranches ?? (_parLien ? tranchesLienParDefaut : tranchesTout);

  /// Ce qui manque encore pour enregistrer, en une phrase ; `null` quand
  /// « Enregistrer le document » peut aboutir. Un bouton qui ne peut pas
  /// aboutir n'est pas rendu : cette phrase tient sa place (K-56).
  String? get _manque {
    final s = t.admin.bibliotheque.import.simple;
    final c = t.admin.bibliotheque.import.classement;
    if (_parLien) {
      if (!_lienComplet || _nom.text.trim().isEmpty) return s.aideLien;
      if (_descriptionManque) return s.descriptionLien;
    } else {
      if (_enEnvoi(_support)) return s.aideEnvoi;
      if (!_fichierAjoute) return s.aideFichier;
      if (_nom.text.trim().isEmpty) return s.aideNom;
    }
    if (_tiers && !_droitTiers) return s.aideDroit;
    if (_tranchesEffectives.isEmpty) return c.tranchesAucune;
    if (!ecoleValide(_ecole.text)) return c.ecoleTrop;
    return null;
  }

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

  /// La vignette, facultative : une image de 2 Mio au plus. Son echec ne
  /// retient jamais l'enregistrement du document.
  Future<void> _choisirVignette() async {
    final v = t.admin.bibliotheque.import.simple.vignette;
    setState(() {
      _refusVignette = null;
      _messageVignette = null;
    });
    final FichierChoisi? fichier = await ref
        .read(selecteurFichierSupportProvider)
        .choisir(TypeRessource.image);
    if (fichier == null || !mounted) return;
    final LectureFichier lecture = lireFichier(
      fichier.octets,
      nom: fichier.nom,
    );
    if (lecture is! FichierReconnu || lecture.type != TypeRessource.image) {
      setState(() => _refusVignette = v.pasUneImage);
      return;
    }
    if (fichier.octets.length > _vignetteMaxOctets) {
      setState(() => _refusVignette = v.tropLourde);
      return;
    }
    final FichierChoisi image = FichierChoisi(
      nom: fichier.nom,
      octets: fichier.octets,
      mime: lecture.mime,
    );
    _vignette
      ..annulerAbonnement()
      ..fichier = image
      ..intention = null;
    setState(
      () => _vignette.progression = const ProgressionUpload(
        phase: PhaseUpload.attente,
      ),
    );
    await _envoyer(_vignette, FinaliteUpload.vignette, image);
  }

  Future<void> _retirerVignette() async {
    final String? id = _supportId;
    if (id == null) return;
    final v = t.admin.bibliotheque.import.simple.vignette;
    try {
      final FicheSupport fiche = await widget.port.fiche(id);
      final ResultatEcriture r = await widget.port.mettreAJour(
        supportId: id,
        modification: const ModificationSupport(retirerVignette: true),
        revisionAttendue: fiche.revision,
      );
      if (!mounted) return;
      if (r is EcritureFaite) {
        _vignette.annulerAbonnement();
        setState(() {
          _vignette
            ..fichier = null
            ..progression = null
            ..intention = null;
          _vignettePosee = false;
          _messageVignette = v.retiree;
        });
      } else {
        setState(() => _messageVignette = t.admin.bibliotheque.fiche.conflit);
      }
    } on Object {
      if (mounted) {
        setState(
          () => _messageVignette = t.admin.bibliotheque.fiche.echecEnregistrer,
        );
      }
    }
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

  void _echec(_Depot depot, ErreurUpload cause, String? reglage) {
    if (!mounted) return;
    setState(
      () => depot.progression = ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: cause,
        reglage: reglage,
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
          .listen(
            (ProgressionUpload p) {
              if (!mounted) return;
              setState(() {
                depot.progression = p;
                if (identical(depot, _vignette) &&
                    p.phase == PhaseUpload.pret) {
                  _vignettePosee = true;
                }
              });
            },
            onError: (Object e) =>
                _echec(depot, causeDeLaDemande(e), reglageDeLaDemande(e)),
          );
    } on Object catch (e) {
      // Chaque cause a sa phrase : jamais « connexion » par defaut.
      _echec(depot, causeDeLaDemande(e), reglageDeLaDemande(e));
    }
  }

  Future<void> _reessayer(_Depot depot, FinaliteUpload finalite) async {
    final FichierChoisi? fichier = depot.fichier;
    if (fichier == null) return;
    depot.annulerAbonnement();
    setState(() {
      _erreur = null;
      depot.progression = const ProgressionUpload(phase: PhaseUpload.attente);
    });
    await _envoyer(depot, finalite, fichier);
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

  bool get _droitsSaisis =>
      _source.text.trim().isNotEmpty ||
      _titulaire.text.trim().isNotEmpty ||
      _attribution.text.trim().isNotEmpty ||
      _preuve.pret;

  /// Le seul bouton : enregistre le nom, la description et le rayon, puis
  /// publie le document (depot direct de la direction). Les droits restes
  /// vides prennent leur valeur par defaut cote serveur.
  Future<void> _enregistrer() async {
    if (_manque != null) {
      setState(() => _incomplet = true);
      return;
    }
    setState(() {
      _envoi = true;
      _erreur = null;
      _bloque = false;
    });
    final s = t.admin.bibliotheque.import.simple;
    try {
      final bool nouveau = _supportId == null;
      final String? id = await _assurerBrouillon();
      if (id == null) return;
      FicheSupport fiche = await widget.port.fiche(id);
      if (!nouveau) {
        // Le brouillon a ete cree au choix du fichier : ce que la personne a
        // corrige depuis (nom, description, rayon, reglages) part ici.
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
      if (_droitsSaisis) {
        // Ce que la direction a precise dans « Plus de reglages » est garde
        // tel quel ; le serveur ne remplit que ce qui est reste vide.
        final ResultatEcriture droits = await widget.port.revoirDroits(
          supportId: id,
          versionId: fiche.derniereVersion?.id ?? '',
          saisie: SaisieDroits(
            sourceTitre: _source.text.trim(),
            titulaire: _titulaire.text.trim(),
            preuveFournie: _preuve.pret || fiche.droits.preuveFournie,
            usages: <UsageDroit>{
              UsageDroit.application,
              UsageDroit.classe,
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
        if (droits is! EcritureFaite) {
          setState(() => _erreur = t.admin.bibliotheque.fiche.conflit);
          return;
        }
        fiche = await widget.port.fiche(id);
      }
      final ResultatPublication r = await widget.port.deposerDirect(
        supportId: id,
        revisionAttendue: fiche.revision,
        // La meme tentative rend la meme reponse ; une correction en change.
        cle: 'depot-direct-$id-${fiche.revision}',
        acces: _parLien ? AccesDocument.lecture : _acces,
        droitTiers: _tiers && _droitTiers,
      );
      if (!mounted) return;
      switch (r) {
        case VersionPubliee():
          setState(() => _enregistre = true);
        case PublicationBloquee():
          setState(() {
            _bloque = true;
            _erreur = s.bloque;
          });
        case PublicationEnConflit():
          setState(() => _erreur = t.admin.bibliotheque.fiche.conflit);
      }
    } on Object {
      if (mounted) setState(() => _erreur = s.enregistrementEchec);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  /// Repart d'un formulaire vide, pour ajouter un autre document.
  void _recommencer() {
    _support.annulerAbonnement();
    _preuve.annulerAbonnement();
    _vignette.annulerAbonnement();
    for (final TextEditingController c in <TextEditingController>[
      _nom,
      _description,
      _lien,
      _source,
      _titulaire,
      _attribution,
      _ecole,
    ]) {
      c.clear();
    }
    setState(() {
      for (final _Depot d in <_Depot>[_support, _preuve, _vignette]) {
        d
          ..fichier = null
          ..intention = null
          ..progression = null;
      }
      _type = null;
      _refus = null;
      _refusVignette = null;
      _parLien = false;
      _acces = AccesDocument.lecture;
      _rayon = codeRayonCours;
      _langue = null;
      _plus = false;
      _droitTiers = false;
      _tranches = null;
      _etapes.clear();
      _lecture = null;
      _supportId = null;
      _existante = null;
      _vignettePosee = false;
      _messageVignette = null;
      _incomplet = false;
      _erreur = null;
      _enregistre = false;
      _bloque = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_enregistre) return _reussite();
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
        if (_erreur != null) ...<Widget>[
          BandeauAttention(
            key: const ValueKey<String>('import-erreur'),
            ton: TonEtat.alerte,
            titre: t.admin.bibliotheque.import.simple.nonEnregistre,
            message: _erreur!,
            action: _bloque && _supportId != null
                ? LienFleche(
                    key: const ValueKey<String>('import-voir-verification'),
                    libelle:
                        t.admin.bibliotheque.import.simple.voirVerification,
                    onPress: () => GoRouter.of(
                      context,
                    ).go(Routes.adminPedagogieSupportPublication(_supportId!)),
                  )
                : null,
          ),
          Ecart.vLg,
        ],
        _actions(),
      ],
    );
  }

  /// Le document est enregistre et visible : l'ecran le dit, avec un lien
  /// pour l'ouvrir.
  Widget _reussite() {
    final s = t.admin.bibliotheque.import.simple;
    final String? id = _supportId;
    return Column(
      key: const ValueKey<String>('import-reussite'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BandeauAttention(
          key: const ValueKey<String>('import-enregistre'),
          ton: TonEtat.succes,
          titre: s.enregistreTitre,
          message: s.enregistreMessage,
          action: id == null
              ? null
              : LienFleche(
                  key: const ValueKey<String>('import-ouvrir'),
                  libelle: s.ouvrir,
                  onPress: () =>
                      GoRouter.of(context).go(Routes.adminPedagogieSupport(id)),
                ),
        ),
        Ecart.vLg,
        LienFleche(
          key: const ValueKey<String>('import-autre'),
          libelle: s.autre,
          alignerEnDebut: true,
          onPress: _recommencer,
        ),
        Ecart.vSm,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: const ValueKey<String>('import-retour'),
            libelle: t.admin.bibliotheque.import.retour,
            niveau: NiveauAction.tertiaire,
            pleineLargeur: false,
            onPress: () =>
                GoRouter.of(context).go(Routes.adminPedagogieBibliotheque),
          ),
        ),
      ],
    );
  }

  Widget _titreSection(String texte) => Semantics(
    header: true,
    child: Text(texte, style: Theme.of(context).textTheme.titleMedium),
  );

  /// Le depot n'est pas pret : l'ecran nomme le reglage qui manque (son nom,
  /// jamais sa valeur), au lieu de le laisser decouvrir par un echec.
  List<Widget> _etatDuDepot() {
    final f = t.admin.bibliotheque.import;
    if (_manquants.isNotEmpty) {
      return <Widget>[
        BandeauAttention(
          key: const ValueKey<String>('import-reglages'),
          titre: f.simple.reglagesTitre,
          message: <String>[
            f.simple.reglagesMessage,
            for (final String nom in _manquants)
              f.simple.reglageNomme(nom: nom),
          ].join('\n'),
        ),
        Ecart.vMd,
      ];
    }
    if (_depotActif == false) {
      return <Widget>[
        Text(
          f.classement.depotInactif,
          key: const ValueKey<String>('import-depot-inactif'),
        ),
        Ecart.vMd,
      ];
    }
    if (_depotActif == null && _depotInconnu) {
      return <Widget>[
        Text(
          f.classement.depotInconnu,
          key: const ValueKey<String>('import-depot-inconnu'),
        ),
        Ecart.vMd,
      ];
    }
    return const <Widget>[];
  }

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
            BandeauAttention(
              key: const ValueKey<String>('import-fichier-present'),
              ton: TonEtat.succes,
              titre: f.simple.fichierAjoute,
              message: f.simple.fichierPresent,
            )
          else ...<Widget>[
            if (_support.fichier == null) ...<Widget>[
              Text(f.simple.intro, key: const ValueKey<String>('import-intro')),
              Ecart.vMd,
            ],
            ..._etatDuDepot(),
            if (!_depotInactif) _blocFichier(),
            if (_refus != null) ...<Widget>[
              Ecart.vSm,
              BandeauAttention(
                key: const ValueKey<String>('import-refus'),
                ton: TonEtat.alerte,
                titre: f.simple.fichierEchec,
                message: _refus!,
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

  /// Les trois etats d'un depot, visibles d'un coup d'oeil et jamais par la
  /// couleur seule : en cours (barre, pourcentage, phrase), reussi (coche,
  /// ton de succes, phrase), echoue (alerte, ton d'alerte, phrase vraie et
  /// « Reessayer »). Chaque etat est annonce aux lecteurs d'ecran.
  List<Widget> _etat(
    _Depot depot,
    String suffixe, {
    required String titreReussite,
    required String detailReussite,
    required String titreEchec,
    required VoidCallback onReessayer,
    String? suiteEchec,
  }) {
    final i = t.admin.bibliotheque.import;
    final ProgressionUpload? p = depot.progression;
    if (p == null) return const <Widget>[];
    if (_enEnvoi(depot)) {
      final int pourcent = (p.partie * 100).round();
      final String phrase = switch (p.phase) {
        PhaseUpload.attente => i.etats.attente,
        PhaseUpload.enAttenteConfirmation => i.etats.confirmation,
        PhaseUpload.verification => i.etats.verification,
        _ => LibellesGroupe.valeurSeule(i.etats.envoi(pourcent: '$pourcent')),
      };
      return <Widget>[
        Ecart.vSm,
        Semantics(
          label: i.progression,
          value: '$pourcent %',
          child: LinearProgressIndicator(
            key: ValueKey<String>('import-progression-$suffixe'),
            value: p.phase == PhaseUpload.attente ? null : p.partie,
          ),
        ),
        Ecart.vSm,
        Semantics(
          liveRegion: true,
          child: Text(phrase, key: ValueKey<String>('import-etat-$suffixe')),
        ),
        if (p.phase != PhaseUpload.verification) ...<Widget>[
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
    return <Widget>[
      Ecart.vSm,
      switch (p.phase) {
        PhaseUpload.pret => BandeauAttention(
          key: ValueKey<String>('import-reussi-$suffixe'),
          ton: TonEtat.succes,
          titre: titreReussite,
          message: detailReussite,
        ),
        PhaseUpload.echec => BandeauAttention(
          key: ValueKey<String>('import-echec-$suffixe'),
          ton: TonEtat.alerte,
          titre: titreEchec,
          message: <String>[
            phraseEchecDepot(p.erreur, p.reglage),
            ?suiteEchec,
          ].join(' '),
          action: LienFleche(
            key: ValueKey<String>('import-reessayer-$suffixe'),
            libelle: t.commun.reessayer,
            fleche: false,
            onPress: onReessayer,
          ),
        ),
        _ => Semantics(
          liveRegion: true,
          child: Text(
            i.etats.annule,
            key: ValueKey<String>('import-etat-$suffixe'),
          ),
        ),
      },
    ];
  }

  String _detail(FichierChoisi fichier, TypeRessource type) =>
      t.admin.bibliotheque.import.simple.detailFichier(
        type: libelleType(type),
        taille: tailleLisible(fichier.octets.length),
      );

  Widget _blocFichier() {
    final i = t.admin.bibliotheque.import;
    final FichierChoisi? fichier = _support.fichier;
    final TypeRessource? type = _type;
    final bool enEnvoi = _enEnvoi(_support);
    final TextStyle? corps = Theme.of(context).textTheme.bodyLarge;
    final String detail = fichier != null && type != null
        ? _detail(fichier, type)
        : '';
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
          if (type != null && !_support.pret) ...<Widget>[
            Ecart.vXs,
            Text(detail, key: const ValueKey<String>('import-reconnu')),
          ],
        ],
        ..._etat(
          _support,
          'support',
          titreReussite: i.simple.fichierAjoute,
          detailReussite: detail,
          titreEchec: i.simple.fichierEchec,
          onReessayer: () =>
              unawaited(_reessayer(_support, FinaliteUpload.support)),
        ),
        // Pas de remplacement concurrent, ni apres l'ajout : le choix revient
        // hors envoi, tant que le fichier n'est pas ajoute.
        if (!enEnvoi && !_support.pret) ...<Widget>[
          if (fichier != null) Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('import-choisir-support'),
              libelle: fichier == null ? i.choisirFichier : i.choisirAutre,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: () => unawaited(_choisirFichier()),
            ),
          ),
        ],
      ],
    );
  }

  /// La vignette : facultative, visible des qu'elle est deposee, remplacable
  /// et retirable. Elle ne retient jamais l'enregistrement.
  Widget _blocVignette() {
    final i = t.admin.bibliotheque.import;
    final v = i.simple.vignette;
    final a = t.admin.bibliotheque.fiche;
    final FichierChoisi? image = _vignette.fichier;
    final bool enEnvoi = _enEnvoi(_vignette);
    return Column(
      key: const ValueKey<String>('import-vignette'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(v.titre, style: Theme.of(context).textTheme.titleSmall),
        Ecart.vXs,
        Text(v.aide),
        if (image != null && _vignette.pret) ...<Widget>[
          Ecart.vSm,
          // La miniature de l'image deposee, des qu'elle l'est.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ClipRRect(
              borderRadius: AppRadius.arrondiSm,
              child: Image.memory(
                image.octets,
                key: const ValueKey<String>('import-vignette-miniature'),
                width: AppSpacing.respiration * 2,
                height: AppSpacing.respiration * 2,
                fit: BoxFit.cover,
                semanticLabel: v.apercu,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
        ..._etat(
          _vignette,
          'vignette',
          titreReussite: v.ajoutee,
          detailReussite: image == null
              ? ''
              : _detail(image, TypeRessource.image),
          titreEchec: v.echec,
          suiteEchec: v.echecSuite,
          onReessayer: () =>
              unawaited(_reessayer(_vignette, FinaliteUpload.vignette)),
        ),
        if (_refusVignette != null) ...<Widget>[
          Ecart.vSm,
          BandeauAttention(
            key: const ValueKey<String>('import-refus-vignette'),
            ton: TonEtat.alerte,
            titre: v.echec,
            message: '${_refusVignette!} ${v.echecSuite}',
          ),
        ],
        if (_messageVignette != null) ...<Widget>[
          Ecart.vSm,
          Semantics(
            liveRegion: true,
            child: Text(
              _messageVignette!,
              key: const ValueKey<String>('import-message-vignette'),
            ),
          ),
        ],
        if (!enEnvoi) ...<Widget>[
          Ecart.vSm,
          LienFleche(
            key: const ValueKey<String>('import-choisir-vignette'),
            libelle: _vignettePosee ? a.remplacerVignette : i.choisirVignette,
            alignerEnDebut: true,
            onPress: () => unawaited(_choisirVignette()),
          ),
          if (_vignettePosee)
            LienFleche(
              key: const ValueKey<String>('import-retirer-vignette'),
              libelle: a.retirerVignette,
              fleche: false,
              alignerEnDebut: true,
              onPress: () => unawaited(_retirerVignette()),
            ),
        ],
      ],
    );
  }

  Widget _sectionDocument() {
    final f = t.admin.bibliotheque.import;
    final s = f.simple;
    final String langue = _langueInterface;
    // La vignette se depose sur le document : il lui faut son brouillon, donc
    // le fichier d'abord (ou le brouillon repris).
    final bool vignettePossible = !_depotInactif && _supportId != null;
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
              valeurInitiale: ReponseChoix(valeurs: <String>{_acces.name}),
              options: <OptionChoix>[
                OptionChoix(
                  cle: const ValueKey<String>('import-acces-lecture'),
                  valeur: AccesDocument.lecture.name,
                  libelle: s.acces.lecture,
                  description: s.acces.lectureAide,
                ),
                OptionChoix(
                  cle: const ValueKey<String>('import-acces-telechargement'),
                  valeur: AccesDocument.telechargement.name,
                  libelle: s.acces.telechargement,
                  description: s.acces.telechargementAide,
                ),
              ],
              onChange: (ReponseChoix r) => setState(
                () => _acces =
                    r.valeurs.contains(AccesDocument.telechargement.name)
                    ? AccesDocument.telechargement
                    : AccesDocument.lecture,
              ),
            ),
          ],
          // Le rayon : ceux que le serveur a semes, jamais un second
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
          // Un document qui ne vient pas de l'academie : une seule
          // declaration, gardee avec le nom de la personne et la date.
          if (_tiers) ...<Widget>[
            Ecart.vMd,
            LigneCase(
              cle: const ValueKey<String>('import-droit-tiers'),
              libelle: s.droitTiers,
              precision: s.droitTiersAide,
              coche: _droitTiers,
              onChange: (bool v) => setState(() => _droitTiers = v),
            ),
          ],
          if (vignettePossible) ...<Widget>[Ecart.vLg, _blocVignette()],
        ],
      ),
    );
  }

  /// « Plus de reglages », replie : tout ce que la personne n'a pas a toucher
  /// pour enregistrer un document, et qui garde une valeur par defaut sure.
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
              ..._etat(
                _preuve,
                'preuve',
                titreReussite: d.preuveDeposee,
                detailReussite: _preuve.fichier == null
                    ? ''
                    : tailleLisible(_preuve.fichier!.octets.length),
                titreEchec: s.fichierEchec,
                onReessayer: () =>
                    unawaited(_reessayer(_preuve, FinaliteUpload.preuve)),
              ),
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
    final String? manque = _manque;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Un bouton qui ne peut pas aboutir n'est pas rendu : la phrase dit
        // ce qui manque.
        if (manque != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Semantics(
              liveRegion: true,
              child: Text(manque, key: const ValueKey<String>('import-aide')),
            ),
          ),
        if (manque == null)
          ActionPrincipale(
            key: const ValueKey<String>('import-poursuivre'),
            libelle: s.enregistrer,
            enCours: _envoi,
            onPress: _envoi ? null : () => unawaited(_enregistrer()),
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
