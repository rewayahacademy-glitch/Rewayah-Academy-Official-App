/// CAP29-B : la fiche et la preparation d'un support (spec CAP-29 §3.3, §4,
/// maquette M02).
///
/// Bureau : deux colonnes, a gauche l'apercu, l'edition et les metadonnees, a
/// droite le workflow, les versions, les droits, le perimetre, l'historique et
/// les actions. Telephone et tablette : une colonne en sections repliables, une
/// **seule** action principale, en bas, sans doublon.
///
/// - Une version publiee est **immuable** : pas de champ a editer, seulement
///   « Creer une nouvelle version » (un nouveau brouillon).
/// - Les trois vocabulaires restent distincts : version, revue des droits,
///   retrait.
/// - Chaque action existe selon une capacite rendue par le serveur
///   ([CapacitesSupport]), jamais selon un role ; un geste impossible n'est pas
///   rendu (jamais grise).
/// - L'apercu n'invente aucun document : sans fichier il le dit ; le rendu reel
///   se controle a l'etape « Verifier et publier ».
/// - Ecriture sous controle de revision : un conflit d'edition est dit et la
///   fiche se recharge.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/admin/admin_domaine.dart';
import '../../../core/admin/modeles_bibliotheque_admin.dart';
import '../../../core/admin/port_bibliotheque_admin.dart';
import '../../../core/i18n/dates_appareil.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/etat_sans_donnees.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_gabarit.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/chargement_avec_delais.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/zone_saisie.dart';
import '../catalogue/catalogue_page.dart' show rangBibliotheque;
import '../libelles_bibliotheque.dart';
import '../porte_bibliotheque.dart';

/// L'ecran d'une fiche de support.
class FichePage extends StatelessWidget {
  /// Cree l'ecran du support [supportId].
  const FichePage({required this.supportId, super.key});

  /// Le support ouvert.
  final String supportId;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.bibliotheque.ficheTitre,
      entete: SousNavigationDomaine(
        onglets: ongletsPedagogie(),
        indexActif: rangBibliotheque,
      ),
      onRetour: () =>
          GoRouter.of(context).go(Routes.adminPedagogieBibliotheque),
      child: PorteBibliotheque(
        construire: (
          BuildContext context,
          PortBibliothequeAdmin port,
          CapacitesBibliotheque capacites,
        ) => _Fiche(port: port, supportId: supportId),
      ),
    );
  }
}

class _Fiche extends StatefulWidget {
  const _Fiche({required this.port, required this.supportId});

  final PortBibliothequeAdmin port;
  final String supportId;

  @override
  State<_Fiche> createState() => _FicheEtat();
}

class _FicheEtat extends State<_Fiche> {
  FicheSupport? _fiche;
  Object? _erreur;
  bool _chargement = true;
  bool _envoi = false;
  String? _message;
  bool _conflit = false;
  bool _echec = false;
  String? _erreurTitre;

  final TextEditingController _titre = TextEditingController();
  final TextEditingController _titreCourt = TextEditingController();
  final TextEditingController _edition = TextEditingController();
  final TextEditingController _organisme = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _conditions = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _titre,
      _titreCourt,
      _edition,
      _organisme,
      _description,
      _conditions,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final FicheSupport f = await widget.port.fiche(widget.supportId);
      if (!mounted) return;
      _titre.text = f.support.titre;
      _titreCourt.text = f.titreCourt;
      _edition.text = f.edition ?? '';
      _organisme.text = f.organisme ?? '';
      _description.text = f.description ?? '';
      _conditions.text = f.conditionsAttribution ?? '';
      setState(() {
        _fiche = f;
        _chargement = false;
        _conflit = false;
        _echec = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e;
        _chargement = false;
      });
    }
  }

  Future<void> _enregistrer(FicheSupport f) async {
    final a = t.admin.bibliotheque.fiche;
    if (_titre.text.trim().isEmpty) {
      setState(() => _erreurTitre = a.titreVide);
      return;
    }
    setState(() {
      _envoi = true;
      _erreurTitre = null;
      _message = null;
      _echec = false;
    });
    try {
      final ResultatEcriture r = await widget.port.mettreAJour(
        supportId: f.support.id,
        modification: ModificationSupport(
          titre: _titre.text.trim(),
          titreCourt: _titreCourt.text.trim(),
          edition: _edition.text.trim(),
          organisme: _organisme.text.trim(),
          description: _description.text.trim(),
          conditionsAttribution: _conditions.text.trim(),
        ),
        revisionAttendue: f.revision,
      );
      if (!mounted) return;
      switch (r) {
        case EcritureFaite():
          await _charger();
          if (mounted) setState(() => _message = a.enregistre);
        case EcritureEnConflit():
          setState(() => _conflit = true);
      }
    } on Object {
      if (mounted) setState(() => _echec = true);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _nouvelleVersion(FicheSupport f) async {
    final a = t.admin.bibliotheque.fiche;
    setState(() {
      _envoi = true;
      _message = null;
      _echec = false;
    });
    try {
      await widget.port.nouvelleVersion(f.support.id);
      if (!mounted) return;
      await _charger();
      if (mounted) setState(() => _message = a.nouvelleVersionOk);
    } on Object {
      if (mounted) {
        setState(() {
          _echec = true;
          _message = a.nouvelleVersionEchec;
        });
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque;
    if (_chargement && _fiche == null) {
      return ChargementAvecDelais(
        squelette: const Skeleton.liste(lignes: 5),
        onReessayer: () => unawaited(_charger()),
      );
    }
    final Object? e = _erreur;
    if (e != null && _fiche == null) {
      if (e is BibliothequeIntrouvable) {
        return EtatSysteme(
          key: const ValueKey<String>('fiche-introuvable'),
          nature: NatureEtat.introuvable,
          phrase: a.introuvable,
          libelleAction: a.retourCatalogue,
          onAction: () =>
              GoRouter.of(context).go(Routes.adminPedagogieBibliotheque),
        );
      }
      if (e is BibliothequeNonAutorisee) {
        return EtatSysteme(
          key: const ValueKey<String>('fiche-non-autorise'),
          nature: NatureEtat.accesRefuse,
          titre: a.titre,
          phrase: a.nonAutorise,
        );
      }
      return e is BibliothequeHorsLigne
          ? EtatSansDonnees(
              key: const ValueKey<String>('fiche-sans-donnees'),
              quoi: a.sansDonnees,
              onAction: () => unawaited(_charger()),
            )
          : EtatSysteme(
              key: const ValueKey<String>('fiche-erreur'),
              nature: NatureEtat.echecServeur,
              phrase: a.erreur,
              onAction: () => unawaited(_charger()),
            );
    }
    final FicheSupport f = _fiche!;
    final bool large = AppGabarit.de(context) == Gabarit.desktop;
    final Widget action = _ActionPrincipale(
      fiche: f,
      envoi: _envoi,
      onNouvelleVersion: () => unawaited(_nouvelleVersion(f)),
    );
    final List<Widget> principale = <Widget>[
      _Entete(fiche: f),
      Ecart.vLg,
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              key: ValueKey<String>(_echec ? 'fiche-echec' : 'fiche-message'),
            ),
          ),
        ),
      _Section(
        cle: 'apercu',
        titre: a.fiche.sections.apercu,
        large: large,
        child: _Apercu(fiche: f),
      ),
      _Section(
        cle: 'edition',
        titre: a.fiche.sections.edition,
        large: large,
        child: _Edition(
          fiche: f,
          champs: <String, TextEditingController>{
            'titre': _titre,
            'titreCourt': _titreCourt,
            'edition': _edition,
            'organisme': _organisme,
            'description': _description,
            'conditions': _conditions,
          },
          erreurTitre: _erreurTitre,
          envoi: _envoi,
          conflit: _conflit,
          echec: _echec && _message == null,
          onEnregistrer: () => unawaited(_enregistrer(f)),
          onRecharger: () => unawaited(_charger()),
        ),
      ),
      _Section(
        cle: 'metadonnees',
        titre: a.fiche.sections.metadonnees,
        large: large,
        child: _Metadonnees(fiche: f),
      ),
    ];
    final List<Widget> laterale = <Widget>[
      _Section(
        cle: 'workflow',
        titre: a.fiche.sections.workflow,
        large: large,
        child: _Workflow(fiche: f),
      ),
      _Section(
        cle: 'versions',
        titre: a.fiche.sections.versions,
        large: large,
        child: _Versions(fiche: f),
      ),
      _Section(
        cle: 'droits',
        titre: a.fiche.sections.droits,
        large: large,
        child: _Droits(fiche: f),
      ),
      _Section(
        cle: 'perimetre',
        titre: a.fiche.sections.perimetre,
        large: large,
        child: _Perimetre(fiche: f),
      ),
      _Section(
        cle: 'historique',
        titre: a.fiche.sections.historique,
        large: large,
        child: _Historique(fiche: f),
      ),
    ];
    if (large) {
      return Row(
        key: const ValueKey<String>('fiche-contenu'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: principale,
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[action, Ecart.vLg, ...laterale],
            ),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey<String>('fiche-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[...principale, ...laterale, Ecart.vLg, action],
    );
  }
}

class _Entete extends StatelessWidget {
  const _Entete({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final SupportAdmin s = fiche.support;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(
            s.titre,
            key: const ValueKey<String>('fiche-titre'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Ecart.vSm,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            StatusPill(
              key: const ValueKey<String>('fiche-statut'),
              libelle: libelleEtatSupport(s),
              ton: tonEtatSupport(s),
            ),
            StatusPill(
              key: const ValueKey<String>('fiche-revue'),
              libelle: libelleRevue(s.revueDroits),
              ton: tonRevue(s.revueDroits),
            ),
          ],
        ),
      ],
    );
  }
}

/// Une section : une carte au bureau, un bloc repliable ailleurs.
class _Section extends StatefulWidget {
  const _Section({
    required this.cle,
    required this.titre,
    required this.large,
    required this.child,
  });

  final String cle;
  final String titre;
  final bool large;
  final Widget child;

  @override
  State<_Section> createState() => _SectionEtat();
}

class _SectionEtat extends State<_Section> {
  bool _ouverte = true;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final a = t.admin.bibliotheque.fiche;
    final Widget titre = Semantics(
      header: true,
      child: TexteSansCoupure(widget.titre, style: textes.titleMedium),
    );
    if (widget.large) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: AppCard(
          key: ValueKey<String>('section-${widget.cle}'),
          entete: titre,
          child: widget.child,
        ),
      );
    }
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        key: ValueKey<String>('section-${widget.cle}'),
        entete: Pressable(
          key: ValueKey<String>('section-bascule-${widget.cle}'),
          libelleSemantique: _ouverte
              ? a.masquerSection(nom: widget.titre)
              : a.afficherSection(nom: widget.titre),
          onPress: () => setState(() => _ouverte = !_ouverte),
          child: Row(
            children: <Widget>[
              Expanded(child: titre),
              IconTheme(
                data: palette.inkStrong.asIconTheme(size: AppSpacing.xxl),
                child: ExcludeSemantics(
                  // Le chevron du menu, retourne quand la section est ouverte.
                  child: Transform.rotate(
                    angle: _ouverte ? math.pi : 0,
                    child: Icon(AppIcons.menuDeroulant.repos),
                  ),
                ),
              ),
            ],
          ),
        ),
        child: _ouverte ? widget.child : const SizedBox.shrink(),
      ),
    );
  }
}

class _Apercu extends StatelessWidget {
  const _Apercu({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.fiche;
    final VersionSupport? v = fiche.derniereVersion;
    final bool aFichier = v?.empreinte != null;
    final bool modifiable =
        (v?.modifiable ?? false) && fiche.capacites.peutModifier;
    final String phrase = !aFichier
        ? a.apercuAucunFichier
        : (v!.modifiable ? a.apercuFichier : a.apercuPublie);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(phrase, key: const ValueKey<String>('fiche-apercu')),
        if (modifiable) ...<Widget>[
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('fiche-deposer'),
              libelle: aFichier ? a.remplacer : a.deposer,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              onPress: () => GoRouter.of(context)
                  .go(Routes.adminPedagogieSupportFichier(fiche.support.id)),
            ),
          ),
        ],
      ],
    );
  }
}

class _Edition extends StatelessWidget {
  const _Edition({
    required this.fiche,
    required this.champs,
    required this.erreurTitre,
    required this.envoi,
    required this.conflit,
    required this.echec,
    required this.onEnregistrer,
    required this.onRecharger,
  });

  final FicheSupport fiche;
  final Map<String, TextEditingController> champs;
  final String? erreurTitre;
  final bool envoi;
  final bool conflit;
  final bool echec;
  final VoidCallback onEnregistrer;
  final VoidCallback onRecharger;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.fiche;
    final VersionSupport? v = fiche.derniereVersion;
    final bool editable =
        (v?.modifiable ?? false) &&
        fiche.capacites.peutModifier &&
        !fiche.support.retire;
    if (!editable) {
      // Version publiee : immuable, rien a editer ; la phrase dit pourquoi.
      return Text(
        fiche.support.retire ? a.retireRestaurer : a.figee,
        key: const ValueKey<String>('fiche-figee'),
      );
    }
    ZoneSaisie champ(
      String cle,
      String libelle, {
      int lignes = 1,
      String? erreur,
    }) => ZoneSaisie(
      controleur: champs[cle]!,
      cleChamp: ValueKey<String>('fiche-champ-$cle'),
      libelle: libelle,
      erreur: erreur,
      minLignes: lignes,
      maxLignes: lignes == 1 ? 1 : 6,
      majuscules: TextCapitalization.sentences,
      actionClavier: lignes == 1
          ? TextInputAction.next
          : TextInputAction.newline,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        champ('titre', a.champs.titre, erreur: erreurTitre),
        Ecart.vMd,
        champ('titreCourt', a.champs.titreCourt),
        Ecart.vMd,
        champ('edition', a.champs.edition),
        Ecart.vMd,
        champ('organisme', a.champs.organisme),
        Ecart.vMd,
        champ('description', a.champs.description, lignes: 3),
        Ecart.vMd,
        champ('conditions', a.champs.conditions, lignes: 2),
        Ecart.vLg,
        if (conflit) ...<Widget>[
          Text(a.conflit, key: const ValueKey<String>('fiche-conflit')),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('fiche-recharger'),
              libelle: a.recharger,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: onRecharger,
            ),
          ),
        ] else ...<Widget>[
          if (echec)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                a.echecEnregistrer,
                key: const ValueKey<String>('fiche-echec-enregistrer'),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('fiche-enregistrer'),
              libelle: a.enregistrer,
              niveau: NiveauAction.secondaire,
              pleineLargeur: false,
              enCours: envoi,
              onPress: envoi ? null : onEnregistrer,
            ),
          ),
        ],
      ],
    );
  }
}

class _Metadonnees extends StatelessWidget {
  const _Metadonnees({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final m = t.admin.bibliotheque.fiche.meta;
    final SupportAdmin s = fiche.support;
    String ou(String? v) =>
        (v == null || v.trim().isEmpty) ? m.nonRenseigne : v;
    final List<(String, String)> lignes = <(String, String)>[
      (m.type, libelleType(s.type)),
      (m.langue, libelleLangue(s.langue)),
      (m.categorie, ou(s.categorie)),
      (m.niveau, ou(s.niveau)),
      (t.admin.bibliotheque.fiche.champs.edition, ou(fiche.edition)),
      (t.admin.bibliotheque.fiche.champs.organisme, ou(fiche.organisme)),
      (m.visibilite, libelleVisibilite(s.visibilite)),
      (m.horsLigne, libelleHorsLigne(fiche.politiqueHorsLigne)),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int i, (String, String) l) in lignes.indexed) ...<Widget>[
          if (i > 0) Ecart.vSm,
          LigneCleValeur(cle: l.$1, valeur: l.$2),
        ],
      ],
    );
  }
}

class _Workflow extends StatelessWidget {
  const _Workflow({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque;
    final SupportAdmin s = fiche.support;
    final VersionSupport? v = fiche.derniereVersion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LigneCleValeur(
          cle: a.catalogue.colonnes.version,
          valeur: v == null
              ? a.libelles.version.aucune
              : a.libelles.version.numero(numero: '${v.numero}'),
        ),
        Ecart.vSm,
        LigneCleValeur(
          cle: a.catalogue.colonnes.publication,
          valeur: libelleEtatSupport(s),
        ),
        if (s.retire) ...<Widget>[
          Ecart.vSm,
          Text(
            fiche.motifRetrait == null
                ? a.fiche.retireSansMotif
                : a.fiche.retireMotif(motif: fiche.motifRetrait!),
            key: const ValueKey<String>('fiche-retire'),
          ),
          Ecart.vSm,
          Text(a.fiche.retireRestaurer),
        ],
      ],
    );
  }
}

class _Versions extends StatelessWidget {
  const _Versions({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque;
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int i, VersionSupport v) in fiche.versions.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md),
            child: Column(
              key: ValueKey<String>('fiche-version-${v.numero}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      a.libelles.version.numero(numero: '${v.numero}'),
                      style: textes.titleSmall,
                    ),
                    StatusPill(
                      libelle: libelleStatutVersion(v.statut),
                      ton: switch (v.statut) {
                        StatutVersionRessource.brouillon =>
                          TonEtat.avertissement,
                        StatutVersionRessource.publiee => TonEtat.succes,
                        StatutVersionRessource.archivee => TonEtat.neutre,
                      },
                    ),
                    StatusPill(
                      libelle: libelleRevue(v.revueDroits),
                      ton: tonRevue(v.revueDroits),
                    ),
                  ],
                ),
                if (v.publieeLeUtc != null)
                  Text(
                    a.fiche.version.publieeLe(
                      date: dateDeLAppareil(v.publieeLeUtc!.toLocal()),
                    ),
                    style: textes.bodySmall,
                  ),
                if (v.empreinte == null)
                  Text(a.fiche.version.sansFichier, style: textes.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

class _Droits extends StatelessWidget {
  const _Droits({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final d = t.admin.bibliotheque.fiche.droitsChamps;
    final m = t.admin.bibliotheque.fiche.meta;
    final DroitsSupport droits = fiche.droits;
    String ou(String? v) =>
        (v == null || v.trim().isEmpty) ? m.nonRenseigne : v;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: StatusPill(
            libelle: libelleRevue(droits.revue),
            ton: tonRevue(droits.revue),
          ),
        ),
        Ecart.vMd,
        LigneCleValeur(cle: d.source, valeur: ou(droits.sourceTitre)),
        Ecart.vSm,
        LigneCleValeur(cle: d.titulaire, valeur: ou(droits.titulaire)),
        Ecart.vSm,
        LigneCleValeur(
          cle: d.preuve,
          valeur: droits.preuveFournie ? d.preuveOui : d.preuveNon,
        ),
        Ecart.vSm,
        // Les quatre usages sont distincts : l'application, la classe, le
        // telechargement et le hors ligne ne se confondent jamais.
        LigneCleValeur(
          cle: d.usages,
          valeur: droits.usages.isEmpty
              ? d.aucunUsage
              : <String>[
                  for (final UsageDroit u in UsageDroit.values)
                    if (droits.usages.contains(u)) libelleUsage(u),
                ].join(', '),
        ),
        Ecart.vSm,
        LigneCleValeur(cle: d.attribution, valeur: ou(droits.attribution)),
        if (droits.expireLeUtc != null) ...<Widget>[
          Ecart.vSm,
          LigneCleValeur(
            cle: d.echeance,
            valeur: dateDeLAppareil(droits.expireLeUtc!.toLocal()),
          ),
        ],
        if ((fiche.derniereVersion?.modifiable ?? false) &&
            fiche.capacites.peutModifier) ...<Widget>[
          Ecart.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('fiche-completer-droits'),
              libelle: t.admin.bibliotheque.fiche.actions.completerDroits,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: () => GoRouter.of(
                context,
              ).go(Routes.adminPedagogieSupportPublication(fiche.support.id)),
            ),
          ),
        ],
      ],
    );
  }
}

class _Perimetre extends StatelessWidget {
  const _Perimetre({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.fiche;
    final SupportAdmin s = fiche.support;
    final bool attribuer = fiche.capacites.peutAttribuer && s.publie;
    final bool retirer = fiche.capacites.peutRetirer && s.publie;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          a.classesServies(nombre: '${fiche.classesServies}'),
          key: const ValueKey<String>('fiche-classes-servies'),
        ),
        if (attribuer || retirer) ...<Widget>[
          Ecart.vMd,
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              if (attribuer)
                ActionPrincipale(
                  key: const ValueKey<String>('fiche-associer'),
                  libelle: a.actions.associer,
                  niveau: NiveauAction.secondaire,
                  pleineLargeur: false,
                  onPress: () =>
                      GoRouter.of(context)
                          .go(Routes.adminPedagogieSupportAttribution(s.id)),
                ),
              if (retirer)
                ActionPrincipale(
                  key: const ValueKey<String>('fiche-retirer'),
                  libelle: a.actions.retirer,
                  niveau: NiveauAction.tertiaire,
                  pleineLargeur: false,
                  onPress: () =>
                      GoRouter.of(context)
                          .go(Routes.adminPedagogieSupportAttribution(s.id)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Historique extends StatelessWidget {
  const _Historique({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.fiche;
    final TextTheme textes = Theme.of(context).textTheme;
    if (fiche.historique.isEmpty) {
      return Text(a.historiqueVide);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final (int i, EvenementAudit e) in fiche.historique.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(libelleAudit(e.action), style: textes.titleSmall),
                Text(
                  '${e.acteur} · ${dateDeLAppareil(e.quandUtc.toLocal())}',
                  style: textes.bodySmall,
                ),
                if (e.numeroVersion != null)
                  Text(
                    a.auditVersion(numero: '${e.numeroVersion}'),
                    style: textes.bodySmall,
                  ),
                if (e.motif != null)
                  Text(a.auditMotif(motif: e.motif!), style: textes.bodySmall),
              ],
            ),
          ),
      ],
    );
  }
}

/// L'unique action principale de la fiche, selon l'etat du support et les
/// capacites : brouillon -> verifier et publier ; publie -> nouvelle version ;
/// retire ou sans capacite -> rien (jamais un bouton grise).
class _ActionPrincipale extends StatelessWidget {
  const _ActionPrincipale({
    required this.fiche,
    required this.envoi,
    required this.onNouvelleVersion,
  });

  final FicheSupport fiche;
  final bool envoi;
  final VoidCallback onNouvelleVersion;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.fiche.actions;
    final SupportAdmin s = fiche.support;
    final VersionSupport? v = fiche.derniereVersion;
    if (v == null) return const SizedBox.shrink();
    final bool verifier =
        v.modifiable && !s.retire && fiche.capacites.peutPublier;
    final bool nouvelle =
        !verifier && (s.publie || s.retire) && fiche.capacites.peutModifier;
    if (!verifier && !nouvelle) return const SizedBox.shrink();
    // Un seul bouton plein, deux destinations exclusives.
    final bool enCours = nouvelle && envoi;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionPrincipale(
        key: const ValueKey<String>('fiche-action-principale'),
        libelle: verifier ? a.verifier : a.nouvelleVersion,
        pleineLargeur: AppGabarit.de(context) != Gabarit.desktop,
        enCours: enCours,
        onPress: enCours
            ? null
            : verifier
            ? () =>
                  GoRouter.of(context)
                      .go(Routes.adminPedagogieSupportPublication(s.id))
            : onNouvelleVersion,
      ),
    );
  }
}
