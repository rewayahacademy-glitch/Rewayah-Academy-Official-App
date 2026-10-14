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
import '../libelles_bibliotheque.dart';
import '../porte_bibliotheque.dart';
import 'selecteur_support.dart';

/// Les types que l'on peut importer comme fichier.
const List<TypeRessource> typesImportables = <TypeRessource>[
  TypeRessource.pdf,
  TypeRessource.image,
  TypeRessource.texteStructure,
  TypeRessource.lecon,
];

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

  TypeRessource? _type;
  String? _langue;
  String? _niveau;
  FacettesCatalogue _facettes = const FacettesCatalogue();
  final Set<UsageDroit> _usages = <UsageDroit>{};

  String? _supportId;
  FicheSupport? _existante;
  final _Depot _support = _Depot();
  final _Depot _preuve = _Depot();

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
    for (final TextEditingController c in <TextEditingController>[
      _titre,
      _categorie,
      _source,
      _titulaire,
      _attribution,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ressourceComplete =>
      _existante != null ||
      (_titre.text.trim().isNotEmpty &&
          _type != null &&
          _langue != null &&
          _categorie.text.trim().isNotEmpty);

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
    // La preuve est un document (PDF ou image) ; le support, de son type.
    final TypeRessource typeFichier = finalite == FinaliteUpload.preuve
        ? TypeRessource.pdf
        : type;
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
          .listen(
            (ProgressionUpload p) {
              if (mounted) setState(() => depot.progression = p);
            },
            onError: (Object _) {
              if (mounted) {
                setState(
                  () => depot.progression = const ProgressionUpload(
                    phase: PhaseUpload.echec,
                    erreur: ErreurUpload.reseau,
                  ),
                );
              }
            },
          );
    } on Object {
      if (mounted) {
        setState(
          () => depot.progression = const ProgressionUpload(
            phase: PhaseUpload.echec,
            erreur: ErreurUpload.reseau,
          ),
        );
      }
    }
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
    final String? id = _supportId;
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
                  actionClavier: TextInputAction.done,
                ),
                if (_incomplet && !_ressourceComplete) ...<Widget>[
                  Ecart.vSm,
                  Text(
                    t.admin.bibliotheque.import.completerDabord,
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
      PhaseUpload.echec => switch (p!.erreur) {
        ErreurUpload.taille => i.erreurs.taille,
        ErreurUpload.type => i.erreurs.type,
        ErreurUpload.reseau || null => i.erreurs.reseau,
        ErreurUpload.refuse => i.erreurs.refuse,
        ErreurUpload.empreinte => i.erreurs.empreinte,
      },
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
          _blocDepot(
            _support,
            FinaliteUpload.support,
            libelleChoisir: f.choisirFichier,
            libelleAutre: f.choisirAutre,
          ),
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
          Ecart.vMd,
          Text(d.preuve, style: Theme.of(context).textTheme.titleSmall),
          _blocDepot(
            _preuve,
            FinaliteUpload.preuve,
            libelleChoisir: d.deposerPreuve,
            libelleAutre: f.choisirAutre,
          ),
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
        _support.pret || (_existante?.derniereVersion?.empreinte != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!pret)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              f.poursuivreAide,
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
