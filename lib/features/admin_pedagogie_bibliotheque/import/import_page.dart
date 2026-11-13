/// CAP29-C : ajouter un support (spec CAP-29 §3.4, §5.3, maquette M04).
///
/// Trois sections sur une seule page, sans etape artificielle : la ressource
/// (titre, type, langue, categorie), le fichier, les droits et l'acces.
///
/// - Le depot passe par le port : intention, depot avec progression mesuree,
///   confirmation du serveur. Le client ne choisit jamais la cle de stockage et
///   ne voit aucune URL signee ; ici, aucun R2 reel (double de demonstration).
/// - Phases visibles : preparation, envoi (pourcentage), attente de
///   confirmation, verification, pret. Jamais « publie » a cette etape.
/// - Annulation pendant l'envoi ; pas de remplacement concurrent (« Choisir un
///   autre fichier » n'est rendu que hors envoi) ; erreurs de taille, de type,
///   de reseau, de refus, d'empreinte, chacune avec sa phrase.
/// - Types reellement pris en charge seulement : PDF, image, texte structure,
///   lecon. Pas d'EPUB, pas d'audio, pas d'import en masse, et le Coran n'est
///   jamais un fichier depose (source canonique).
/// - « Poursuivre vers la verification » n'est rendu que fichier verifie ; la
///   phrase dit ce qui manque sinon (jamais un bouton grise).
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
import '../../../core/tc_bibliotheque/donnees_catalogue.dart';
import '../../../core/tc_bibliotheque/library_resource.dart';
import '../../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/menu_filtre.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../../../core/widgets/zone_saisie.dart';
import '../catalogue/catalogue_page.dart' show rangBibliotheque;
import '../classement_document.dart';
import '../libelles_bibliotheque.dart';
import '../porte_bibliotheque.dart';
import 'selecteur_support.dart';

/// Les types que l'on peut importer comme fichier.
const List<TypeRessource> typesImportables = <TypeRessource>[
  TypeRessource.pdf,
  TypeRessource.image,
  TypeRessource.texteStructure,
  TypeRessource.lecon,
  TypeRessource.audio,
  TypeRessource.video,
  TypeRessource.lienExterne,
];

/// Vrai pour un type qui se donne par un lien et non par un fichier : le lien
/// externe, et la video (le poids des fichiers video depasse ce que le depot
/// accepte).
bool typeParLien(TypeRessource? type) =>
    type == TypeRessource.lienExterne || type == TypeRessource.video;

/// L'ecran « Ajouter un support ». [supportId] : le brouillon que l'on
/// complete, ou `null` pour un nouveau support.
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

class _ImportEtat extends ConsumerState<_Import> {
  final TextEditingController _titre = TextEditingController();
  final TextEditingController _categorie = TextEditingController();
  final TextEditingController _source = TextEditingController();
  final TextEditingController _titulaire = TextEditingController();
  final TextEditingController _attribution = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _ordre = TextEditingController();
  final TextEditingController _ecole = TextEditingController();
  final TextEditingController _lien = TextEditingController();

  TypeRessource? _type;
  String _rayon = codeRayonCours;
  List<RayonBibliotheque> _rayons = const <RayonBibliotheque>[];
  String? _langue;
  String? _niveau;
  FacettesCatalogue _facettes = const FacettesCatalogue();
  final Set<UsageDroit> _usages = <UsageDroit>{};

  /// Les tranches cochees ; `null` tant que la direction n'y a pas touche : la
  /// valeur par defaut suit alors le type (D1).
  Set<String>? _tranches;
  final Set<String> _etapesChoisies = <String>{};
  String? _lecture;

  /// Vrai seulement quand le serveur a dit que le depot de fichiers est active.
  /// Faux : pas encore active (C2). `null` : pas de reponse (en attente ou
  /// erreur) ; sans reponse, AUCUN bouton de fichier n'est affiche (revue I1).
  bool? _depotActif;
  bool _depotInconnu = false;

  String? _supportId;
  FicheSupport? _existante;
  final _Depot _support = _Depot();
  final _Depot _preuve = _Depot();
  final _Depot _vignette = _Depot();

  bool _incomplet = false;
  String? _erreur;
  bool _envoiDroits = false;

  @override
  void initState() {
    super.initState();
    _supportId = widget.supportId;
    unawaited(_initialiser());
  }

  Future<void> _initialiser() async {
    try {
      final FacettesCatalogue f = await widget.port.facettes();
      if (mounted) setState(() => _facettes = f);
    } on Object {
      // Sans facettes, le niveau n'est pas propose ; le reste fonctionne.
    }
    try {
      // Les rayons viennent du serveur (donnee), jamais d'un ecran.
      final List<RayonBibliotheque> r = await ref
          .read(portCatalogueProvider)
          .rayons();
      if (mounted) setState(() => _rayons = r);
    } on Object {
      // Sans rayons, le document va au rayon des cours (par defaut serveur).
    }
    try {
      final bool actif = await widget.port.depotActif();
      if (mounted) setState(() => _depotActif = actif);
    } on Object {
      // Sans reponse, on ne propose PAS le depot de fichiers : la phrase dit
      // que l'etat n'a pas pu etre verifie, le lien reste possible.
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
        _source.text = fiche.droits.sourceTitre ?? '';
        _titulaire.text = fiche.droits.titulaire ?? '';
        _attribution.text = fiche.droits.attribution ?? '';
        _usages.addAll(fiche.droits.usages);
      });
    } on Object {
      if (mounted) setState(() => _erreur = t.admin.bibliotheque.erreur);
    }
  }

  @override
  void dispose() {
    _support.annulerAbonnement();
    _preuve.annulerAbonnement();
    _vignette.annulerAbonnement();
    for (final TextEditingController c in <TextEditingController>[
      _titre,
      _categorie,
      _source,
      _titulaire,
      _attribution,
      _description,
      _ordre,
      _ecole,
      _lien,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Pas de bouton de fichier tant que le serveur n'a pas dit « active ».
  bool get _depotInactif => _depotActif != true;

  bool get _ressourceComplete =>
      _existante != null ||
      (_titre.text.trim().isNotEmpty &&
          _type != null &&
          _langue != null &&
          _categorie.text.trim().isNotEmpty &&
          _lienComplet &&
          _tranchesEffectives.isNotEmpty &&
          ecoleValide(_ecole.text));

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

  /// Un lien externe et une video par lien exigent leur adresse ; un lien
  /// externe exige aussi sa description. Les autres types n'ont ni l'un ni
  /// l'autre a donner ici.
  bool get _lienComplet {
    if (!typeParLien(_type)) return true;
    if (!_lienValide) return false;
    return _type != TypeRessource.lienExterne ||
        _description.text.trim().isNotEmpty;
  }

  /// Les tranches retenues : celles que la direction a cochees, sinon le
  /// defaut du type (un lien exclut les 6 a 9 ans, D1).
  Set<String> get _tranchesEffectives =>
      _tranches ??
      (_type == TypeRessource.lienExterne
          ? tranchesLienParDefaut
          : tranchesTout);

  /// Cree le brouillon si besoin : il faut un brouillon pour deposer.
  Future<String?> _assurerBrouillon() async {
    if (_supportId != null) return _supportId;
    if (!_ressourceComplete) {
      setState(() => _incomplet = true);
      return null;
    }
    try {
      final String id = await widget.port.creerBrouillon(
        NouveauSupport(
          titre: _titre.text.trim(),
          type: _type!,
          langue: _langue!,
          categorie: _categorie.text.trim(),
          niveau: _niveau,
          description: _description.text.trim(),
          rayon: _rayon,
          ordre: int.tryParse(_ordre.text.trim()) ?? 0,
          lienExterne: typeParLien(_type) ? _lien.text.trim() : null,
          etapes: _etapesChoisies.toList(),
          tranches: <String>[
            for (final String c in tranchesProposees)
              if (_tranchesEffectives.contains(c)) c,
          ],
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

  Future<void> _deposer(_Depot depot, FinaliteUpload finalite) async {
    setState(() {
      _erreur = null;
      _incomplet = false;
    });
    final String? id = await _assurerBrouillon();
    final TypeRessource? type = _type;
    if (id == null || type == null || !mounted) return;
    // La preuve est un document (PDF) ; la vignette, une image ; le fichier du
    // document, de son type.
    final TypeRessource typeFichier = switch (finalite) {
      FinaliteUpload.preuve => TypeRessource.pdf,
      FinaliteUpload.vignette => TypeRessource.image,
      FinaliteUpload.support => type,
    };
    final FichierChoisi? fichier = await ref
        .read(selecteurFichierSupportProvider)
        .choisir(typeFichier);
    if (fichier == null || !mounted) return;
    depot
      ..annulerAbonnement()
      ..fichier = fichier;
    setState(
      () => depot.progression = const ProgressionUpload(
        phase: PhaseUpload.attente,
      ),
    );
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
          }, onError: (Object e) => _echecDepot(depot, causeDeLaDemande(e)));
    } on Object catch (e) {
      // Chaque cause a sa phrase : jamais « connexion » par defaut. Avant le
      // 13/11/2026, tout refus du serveur s'affichait « la connexion s'est
      // interrompue ».
      _echecDepot(depot, causeDeLaDemande(e));
    }
  }

  void _echecDepot(_Depot depot, ErreurUpload cause) {
    if (!mounted) return;
    setState(
      () => depot.progression = ProgressionUpload(
        phase: PhaseUpload.echec,
        erreur: cause,
      ),
    );
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

  Future<void> _poursuivre() async {
    // Un document par lien n'a aucun depot : son brouillon se cree ici.
    final String? id = await _assurerBrouillon();
    if (id == null) return;
    setState(() {
      _envoiDroits = true;
      _erreur = null;
    });
    try {
      final FicheSupport fiche = await widget.port.fiche(id);
      final ResultatEcriture r = await widget.port.revoirDroits(
        supportId: id,
        versionId: fiche.derniereVersion?.id ?? '',
        saisie: SaisieDroits(
          sourceTitre: _source.text.trim(),
          titulaire: _titulaire.text.trim(),
          preuveFournie: _preuve.pret || fiche.droits.preuveFournie,
          usages: <UsageDroit>{..._usages},
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
      if (mounted) setState(() => _envoiDroits = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('import-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _sectionRessource(),
        Ecart.vLg,
        _sectionFichier(),
        Ecart.vLg,
        _sectionDroits(),
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

  Widget _sectionRessource() {
    final c = t.admin.bibliotheque.import.champs;
    final FicheSupport? existante = _existante;
    return AppCard(
      key: const ValueKey<String>('import-ressource'),
      entete: Semantics(
        header: true,
        child: Text(
          t.admin.bibliotheque.import.sections.ressource,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: existante != null
          // Le brouillon existe deja : ce que l'on a saisi reste visible, sans
          // ressaisie.
          ? Column(
              children: <Widget>[
                LigneCleValeur(cle: c.titre, valeur: existante.support.titre),
                Ecart.vSm,
                LigneCleValeur(
                  cle: c.type,
                  valeur: libelleType(existante.support.type),
                ),
                Ecart.vSm,
                LigneCleValeur(
                  cle: c.langue,
                  valeur: libelleLangue(existante.support.langue),
                ),
                Ecart.vSm,
                LigneCleValeur(
                  cle: c.categorie,
                  valeur: existante.support.categorie,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ZoneSaisie(
                  controleur: _titre,
                  cleChamp: const ValueKey<String>('import-titre'),
                  libelle: c.titre,
                  maxLignes: 1,
                  erreur: _incomplet && _titre.text.trim().isEmpty
                      ? t.admin.bibliotheque.import.completerDabord
                      : null,
                  actionClavier: TextInputAction.next,
                ),
                Ecart.vMd,
                // Choix de formulaire, pas un filtre : type, langue et niveau d'un support a creer
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    MenuFiltre<TypeRessource>(
                      libelle: c.type,
                      valeur: _type,
                      selecteurDeSection: true,
                      entrees: <EntreeFiltre<TypeRessource>>[
                        for (final TypeRessource tp in typesImportables)
                          EntreeFiltre<TypeRessource>(
                            valeur: tp,
                            libelle: libelleType(tp),
                          ),
                      ],
                      onChoix: (TypeRessource? v) => setState(() => _type = v),
                    ),
                    MenuFiltre<String>(
                      libelle: c.langue,
                      valeur: _langue,
                      selecteurDeSection: true,
                      entrees: <EntreeFiltre<String>>[
                        for (final String l in const <String>['fr', 'ar', 'en'])
                          EntreeFiltre<String>(
                            valeur: l,
                            libelle: libelleLangue(l),
                          ),
                      ],
                      onChoix: (String? v) => setState(() => _langue = v),
                    ),
                    if (_facettes.niveaux.isNotEmpty)
                      MenuFiltre<String>(
                        libelle: c.niveau,
                        valeur: _niveau,
                        entrees: <EntreeFiltre<String>>[
                          for (final String n in _facettes.niveaux)
                            EntreeFiltre<String>(valeur: n, libelle: n),
                        ],
                        onChoix: (String? v) => setState(() => _niveau = v),
                      ),
                  ],
                ),
                Ecart.vMd,
                ZoneSaisie(
                  controleur: _categorie,
                  cleChamp: const ValueKey<String>('import-categorie'),
                  libelle: c.categorie,
                  maxLignes: 1,
                  actionClavier: TextInputAction.next,
                ),
                Ecart.vMd,
                ZoneSaisie(
                  controleur: _description,
                  cleChamp: const ValueKey<String>('import-description'),
                  libelle: c.description,
                  minLignes: 2,
                  maxLignes: 4,
                  majuscules: TextCapitalization.sentences,
                  erreur:
                      _incomplet &&
                          _type == TypeRessource.lienExterne &&
                          _description.text.trim().isEmpty
                      ? t.admin.bibliotheque.import.completerLien
                      : null,
                  onChanged: (_) => setState(() {}),
                  actionClavier: TextInputAction.newline,
                ),
                if (typeParLien(_type)) ...<Widget>[
                  Ecart.vMd,
                  if (_type == TypeRessource.video) ...<Widget>[
                    Text(
                      t.admin.bibliotheque.import.classement.videoLien,
                      key: const ValueKey<String>('import-video-lien'),
                    ),
                    Ecart.vSm,
                  ],
                  ZoneSaisie(
                    controleur: _lien,
                    cleChamp: const ValueKey<String>('import-lien'),
                    libelle: c.lien,
                    maxLignes: 1,
                    erreur: _lien.text.trim().isNotEmpty && !_lienValide
                        ? t.admin.bibliotheque.import.lienInvalide
                        : null,
                    onChanged: (_) => setState(() {}),
                    actionClavier: TextInputAction.next,
                  ),
                ],
                Ecart.vMd,
                // Choix de formulaire, pas un filtre : le rayon se choisit parmi
                // ceux du serveur.
                if (_rayons.isNotEmpty)
                  MenuFiltre<String>(
                    libelle: c.rayon,
                    valeur: _rayon,
                    selecteurDeSection: true,
                    entrees: <EntreeFiltre<String>>[
                      for (final RayonBibliotheque r in _rayons)
                        EntreeFiltre<String>(
                          valeur: r.code,
                          libelle: r.titrePour(
                            LocaleSettings.currentLocale.languageCode,
                          ),
                        ),
                    ],
                    onChoix: (String? v) =>
                        setState(() => _rayon = v ?? codeRayonCours),
                  ),
                Ecart.vMd,
                ZoneSaisie(
                  controleur: _ordre,
                  cleChamp: const ValueKey<String>('import-ordre'),
                  libelle: c.ordre,
                  maxLignes: 1,
                  actionClavier: TextInputAction.next,
                ),
                Ecart.vMd,
                ChoixTranches(
                  choisies: _tranchesEffectives,
                  lien: _type == TypeRessource.lienExterne,
                  onChoix: (Set<String> v) => setState(() => _tranches = v),
                ),
                Ecart.vMd,
                ChoixEtapes(
                  choisies: _etapesChoisies,
                  onChoix: (Set<String> v) => setState(() {
                    _etapesChoisies
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
                if (_incomplet && !_ressourceComplete) ...<Widget>[
                  Ecart.vSm,
                  Text(
                    typeParLien(_type)
                        ? t.admin.bibliotheque.import.completerLien
                        : t.admin.bibliotheque.import.completerDabord,
                    key: const ValueKey<String>('import-incomplet'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _blocDepot(
    _Depot depot,
    FinaliteUpload finalite, {
    required String libelleChoisir,
    required String libelleAutre,
  }) {
    final i = t.admin.bibliotheque.import;
    // Depot non active : pas de bouton qui ne pourrait pas aboutir, la phrase
    // de la section Fichier le dit une fois (C2).
    if (_depotInactif) return const SizedBox.shrink();
    final ProgressionUpload? p = depot.progression;
    final bool enEnvoi =
        p != null &&
        (p.phase == PhaseUpload.attente ||
            p.phase == PhaseUpload.envoi ||
            p.phase == PhaseUpload.enAttenteConfirmation ||
            p.phase == PhaseUpload.verification);
    final String? phrase = switch (p?.phase) {
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
    final String suffixe = finalite.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (depot.fichier != null)
          Text(
            depot.fichier!.nom,
            key: ValueKey<String>('import-nom-$suffixe'),
          ),
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
        Ecart.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              // Pas de remplacement concurrent : le choix revient hors envoi.
              if (!enEnvoi)
                ActionPrincipale(
                  key: ValueKey<String>('import-choisir-$suffixe'),
                  libelle: depot.fichier == null
                      ? libelleChoisir
                      : libelleAutre,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: false,
                  onPress: () => unawaited(_deposer(depot, finalite)),
                ),
              if (enEnvoi && p.phase != PhaseUpload.verification)
                ActionPrincipale(
                  key: ValueKey<String>('import-annuler-$suffixe'),
                  libelle: i.annulerDepot,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: () => unawaited(_annuler(depot)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionFichier() {
    final f = t.admin.bibliotheque.import;
    final TypeRessource? type = _type;
    final String formats = switch (type) {
      TypeRessource.pdf => f.formats.pdf,
      TypeRessource.image => f.formats.image,
      TypeRessource.texteStructure || TypeRessource.lecon => f.formats.json,
      TypeRessource.audio => f.formats.audio,
      TypeRessource.video || TypeRessource.lienExterne => f.formats.lien,
      _ => f.formats.aucun,
    };
    return AppCard(
      key: const ValueKey<String>('import-fichier'),
      entete: Semantics(
        header: true,
        child: Text(
          f.sections.fichier,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (type != null) ...<Widget>[Text(formats), Ecart.vMd],
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
          // Un document par lien n'a aucun fichier : pas de bouton qui ne
          // pourrait pas aboutir.
          if (!typeParLien(type))
            _blocDepot(
              _support,
              FinaliteUpload.support,
              libelleChoisir: f.choisirFichier,
              libelleAutre: f.choisirAutre,
            ),
          if (!_depotInactif) ...<Widget>[
            Ecart.vLg,
            Text(f.vignette, style: Theme.of(context).textTheme.titleSmall),
            Ecart.vXs,
            Text(f.vignetteAide),
            Ecart.vSm,
            _blocDepot(
              _vignette,
              FinaliteUpload.vignette,
              libelleChoisir: f.choisirVignette,
              libelleAutre: f.choisirAutreVignette,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionDroits() {
    final f = t.admin.bibliotheque.import;
    final d = f.droits;
    return AppCard(
      key: const ValueKey<String>('import-droits'),
      entete: Semantics(
        header: true,
        child: Text(
          f.sections.droits,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
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
          Ecart.vMd,
          Text(d.usages, style: Theme.of(context).textTheme.titleSmall),
          // Les quatre usages sont independants (spec §4.3).
          for (final UsageDroit u in UsageDroit.values)
            Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                key: ValueKey<String>('import-usage-${u.name}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: TexteSansCoupure(libelleUsage(u)),
                value: _usages.contains(u),
                onChanged: (bool? v) => setState(() {
                  if (v ?? false) {
                    _usages.add(u);
                  } else {
                    _usages.remove(u);
                  }
                }),
              ),
            ),
          if (!_depotInactif) ...<Widget>[
            Ecart.vMd,
            Text(d.preuve, style: Theme.of(context).textTheme.titleSmall),
            _blocDepot(
              _preuve,
              FinaliteUpload.preuve,
              libelleChoisir: d.deposerPreuve,
              libelleAutre: f.choisirAutre,
            ),
          ],
          if (_existante?.droits.preuveFournie ?? false) ...<Widget>[
            Ecart.vSm,
            Text(d.preuveDeposee),
          ],
        ],
      ),
    );
  }

  Widget _actions() {
    final f = t.admin.bibliotheque.import;
    final bool enCours = _envoiDroits;
    final bool pret =
        _support.pret ||
        (_existante?.derniereVersion?.empreinte != null) ||
        // Un lien externe ou une video par lien : rien a deposer, l'adresse
        // suffit.
        (typeParLien(_type) && _ressourceComplete);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!pret)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              typeParLien(_type) ? f.completerLien : f.poursuivreAide,
              key: const ValueKey<String>('import-aide'),
            ),
          ),
        if (pret)
          ActionPrincipale(
            key: const ValueKey<String>('import-poursuivre'),
            libelle: f.poursuivre,
            enCours: enCours,
            onPress: enCours ? null : () => unawaited(_poursuivre()),
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
