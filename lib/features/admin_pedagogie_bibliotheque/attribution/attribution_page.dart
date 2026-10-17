/// CAP29-E : attribuer un support publie a des classes, et le retirer
/// (spec CAP-29 §3.6 et §3.7).
///
/// - **Attribution** : une liste de classes **paginee a curseur** (trente
///   classes paralleles et plus), les classes deja servies sont nommees et
///   non selectionnables (l'attribution est idempotente cote serveur, mais
///   l'ecran ne propose pas de refaire ce qui est fait), l'epinglage est un
///   choix explicite. Le bouton n'est jamais grise : sans classe choisie, la
///   phrase dit quoi faire.
/// - **Retrait** : un motif obligatoire, une confirmation qui dit la
///   consequence (masque pour toutes les classes, rien n'est supprime), puis le
///   statut dans l'historique. Le retrait est un fait distinct de la version.
/// - Chaque action suit sa **capacite** (`peutAttribuer`, `peutRetirer`),
///   jamais un role. Revision perimee : conflit, on recharge.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/admin/admin_domaine.dart';
import '../../../core/admin/modeles_bibliotheque_admin.dart';
import '../../../core/admin/port_bibliotheque_admin.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/etat_sans_donnees.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/chargement_avec_delais.dart';
import '../../../core/widgets/confirm_destructive.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../../../core/widgets/zone_saisie.dart';
import '../catalogue/catalogue_page.dart' show rangBibliotheque;
import '../porte_bibliotheque.dart';

/// L'ecran du support [supportId].
class AttributionSupportPage extends StatelessWidget {
  /// Cree l'ecran.
  const AttributionSupportPage({required this.supportId, super.key});

  /// Le support.
  final String supportId;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.bibliotheque.attribution.titre,
      sousTitre: t.admin.bibliotheque.attribution.intro,
      entete: SousNavigationDomaine(
        onglets: ongletsPedagogie(),
        indexActif: rangBibliotheque,
      ),
      onRetour: () =>
          GoRouter.of(context).go(Routes.adminPedagogieSupport(supportId)),
      child: PorteBibliotheque(
        construire:
            (
              BuildContext context,
              PortBibliothequeAdmin port,
              CapacitesBibliotheque capacites,
            ) => _Attribution(
              port: port,
              capacites: capacites,
              supportId: supportId,
            ),
      ),
    );
  }
}

class _Attribution extends StatefulWidget {
  const _Attribution({
    required this.port,
    required this.capacites,
    required this.supportId,
  });

  final PortBibliothequeAdmin port;
  final CapacitesBibliotheque capacites;
  final String supportId;

  @override
  State<_Attribution> createState() => _AttributionEtat();
}

class _AttributionEtat extends State<_Attribution> {
  FicheSupport? _fiche;
  final List<ClasseAttribuable> _classes = <ClasseAttribuable>[];
  String? _curseur;
  final Set<String> _choisies = <String>{};
  Object? _erreur;
  bool _chargement = true;
  bool _plus = false;
  bool _enCours = false;
  bool _epingler = false;
  bool _conflit = false;
  bool _echec = false;
  String? _message;
  String? _blocage;
  String? _blocageRetrait;
  final TextEditingController _motif = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  Future<void> _charger({bool garderMessage = false}) async {
    setState(() {
      _chargement = true;
      _erreur = null;
      if (!garderMessage) _message = null;
    });
    try {
      final FicheSupport f = await widget.port.fiche(widget.supportId);
      final PageClasses p = f.support.publie && !f.support.retire
          ? await widget.port.classes(supportId: widget.supportId)
          : const PageClasses(elements: <ClasseAttribuable>[]);
      if (!mounted) return;
      setState(() {
        _fiche = f;
        _classes
          ..clear()
          ..addAll(p.elements);
        _curseur = p.curseur;
        _choisies.clear();
        _conflit = false;
        _chargement = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e;
        _chargement = false;
      });
    }
  }

  Future<void> _voirPlus() async {
    final String? c = _curseur;
    if (c == null || _plus) return;
    setState(() => _plus = true);
    try {
      final PageClasses p = await widget.port.classes(
        supportId: widget.supportId,
        curseur: c,
      );
      if (!mounted) return;
      setState(() {
        _classes.addAll(p.elements);
        _curseur = p.curseur;
      });
    } on Object {
      if (mounted) {
        setState(() {
          _echec = true;
          _message = t.admin.bibliotheque.attribution.erreur;
        });
      }
    } finally {
      if (mounted) setState(() => _plus = false);
    }
  }

  Future<void> _attribuer(FicheSupport f) async {
    final a = t.admin.bibliotheque.attribution;
    if (_choisies.isEmpty) {
      setState(() => _blocage = a.attribuerAucune);
      return;
    }
    setState(() {
      _enCours = true;
      _blocage = null;
      _message = null;
      _echec = false;
    });
    try {
      final ResultatEcriture r = await widget.port.attribuer(
        supportId: f.support.id,
        classeIds: <String>{..._choisies},
        epingler: _epingler,
        revisionAttendue: f.revision,
      );
      if (!mounted) return;
      switch (r) {
        case EcritureFaite():
          await _charger(garderMessage: true);
          if (mounted) setState(() => _message = a.attribuee);
        case EcritureEnConflit():
          setState(() => _conflit = true);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _echec = true;
          _message = a.attribueEchec;
        });
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _retirer(FicheSupport f) async {
    final a = t.admin.bibliotheque.attribution;
    final String motif = _motif.text.trim();
    if (motif.isEmpty) {
      setState(() => _blocageRetrait = a.motifRequis);
      return;
    }
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: a.retraitConfirmerTitre(titre: f.support.titre),
      consequence: a.retraitConfirmerEffet,
      libelleConfirmer: a.retraitConfirmerBouton,
      irreversible: true,
    );
    if (!oui || !mounted) return;
    setState(() {
      _enCours = true;
      _blocageRetrait = null;
      _message = null;
      _echec = false;
    });
    try {
      final ResultatEcriture r = await widget.port.retirer(
        supportId: f.support.id,
        motif: motif,
        revisionAttendue: f.revision,
      );
      if (!mounted) return;
      switch (r) {
        case EcritureFaite():
          _motif.clear();
          await _charger(garderMessage: true);
          if (mounted) setState(() => _message = a.retire);
        case EcritureEnConflit():
          setState(() => _conflit = true);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _echec = true;
          _message = a.retraitEchec;
        });
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
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
          key: const ValueKey<String>('attribution-introuvable'),
          nature: NatureEtat.introuvable,
          phrase: a.introuvable,
          libelleAction: a.retourCatalogue,
          onAction: () =>
              GoRouter.of(context).go(Routes.adminPedagogieBibliotheque),
        );
      }
      return e is BibliothequeHorsLigne
          ? EtatSansDonnees(
              key: const ValueKey<String>('attribution-sans-donnees'),
              quoi: a.sansDonnees,
              onAction: () => unawaited(_charger()),
            )
          : EtatSysteme(
              key: const ValueKey<String>('attribution-erreur'),
              nature: NatureEtat.echecServeur,
              phrase: a.attribution.erreur,
              onAction: () => unawaited(_charger()),
            );
    }
    final FicheSupport f = _fiche!;
    final SupportAdmin s = f.support;
    final TextTheme textes = Theme.of(context).textTheme;
    final bool offert = s.publie && !s.retire;
    final bool attribuer = offert && f.capacites.peutAttribuer;
    final bool retirer = offert && f.capacites.peutRetirer;
    return Column(
      key: const ValueKey<String>('attribution-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(
            s.titre,
            key: const ValueKey<String>('attribution-titre'),
            style: textes.titleLarge,
          ),
        ),
        Ecart.vLg,
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _message!,
                key: ValueKey<String>(
                  _echec ? 'attribution-echec' : 'attribution-message',
                ),
              ),
            ),
          ),
        if (_conflit) ...<Widget>[
          Text(
            a.attribution.conflit,
            key: const ValueKey<String>('attribution-conflit'),
          ),
          Ecart.vSm,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('attribution-recharger'),
              libelle: a.fiche.recharger,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: () => unawaited(_charger()),
            ),
          ),
          Ecart.vLg,
        ],
        if (s.retire)
          Text(
            f.motifRetrait == null
                ? a.fiche.retireSansMotif
                : a.fiche.retireMotif(motif: f.motifRetrait!),
            key: const ValueKey<String>('attribution-retire'),
          )
        else if (!s.publie)
          Text(
            a.attribution.nonPublie,
            key: const ValueKey<String>('attribution-non-publie'),
          )
        else ...<Widget>[
          if (attribuer) _sectionClasses(context, f),
          if (attribuer && retirer) Ecart.vLg,
          if (retirer) _sectionRetrait(context, f),
        ],
      ],
    );
  }

  Widget _sectionClasses(BuildContext context, FicheSupport f) {
    final a = t.admin.bibliotheque.attribution;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: const ValueKey<String>('attribution-classes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(a.classesTitre, style: textes.titleMedium),
          ),
          Ecart.vSm,
          if (_classes.isEmpty)
            Text(a.aucune, key: const ValueKey<String>('attribution-aucune'))
          else
            for (final ClasseAttribuable c in _classes)
              Material(
                type: MaterialType.transparency,
                child: CheckboxListTile(
                  key: ValueKey<String>('attribution-classe-${c.id}'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: TexteSansCoupure(c.nom),
                  subtitle: c.dejaServie
                      ? TexteSansCoupure(
                          c.epinglee ? a.classeEpinglee : a.classeServie,
                        )
                      : null,
                  // Une classe deja servie est cochee et non modifiable ici.
                  value: c.dejaServie || _choisies.contains(c.id),
                  onChanged: c.dejaServie
                      ? null
                      : (bool? v) => setState(() {
                          if (v ?? false) {
                            _choisies.add(c.id);
                          } else {
                            _choisies.remove(c.id);
                          }
                          _blocage = null;
                        }),
                ),
              ),
          if (_curseur != null) ...<Widget>[
            Ecart.vSm,
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ActionPrincipale(
                key: const ValueKey<String>('attribution-plus'),
                libelle: a.plusDeClasses,
                niveau: NiveauAction.tertiaire,
                pleineLargeur: false,
                enCours: _plus,
                onPress: () => unawaited(_voirPlus()),
              ),
            ),
          ],
          Ecart.vMd,
          Material(
            type: MaterialType.transparency,
            child: CheckboxListTile(
              key: const ValueKey<String>('attribution-epingler'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: TexteSansCoupure(a.epingler),
              value: _epingler,
              onChanged: (bool? v) => setState(() => _epingler = v ?? false),
            ),
          ),
          Ecart.vMd,
          if (_blocage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _blocage!,
                  key: const ValueKey<String>('attribution-blocage'),
                ),
              ),
            ),
          ActionPrincipale(
            key: const ValueKey<String>('attribution-attribuer'),
            libelle: a.attribuer(nombre: '${_choisies.length}'),
            enCours: _enCours,
            onPress: () => unawaited(_attribuer(f)),
          ),
        ],
      ),
    );
  }

  Widget _sectionRetrait(BuildContext context, FicheSupport f) {
    final a = t.admin.bibliotheque.attribution;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: const ValueKey<String>('attribution-retrait'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: TexteSansCoupure(a.retraitTitre, style: textes.titleMedium),
          ),
          Ecart.vSm,
          Text(a.retraitIntro),
          Ecart.vMd,
          ZoneSaisie(
            controleur: _motif,
            cleChamp: const ValueKey<String>('attribution-motif'),
            libelle: a.motif,
            maxLignes: 3,
          ),
          Ecart.vMd,
          if (_blocageRetrait != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _blocageRetrait!,
                  key: const ValueKey<String>('attribution-blocage-retrait'),
                ),
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ActionPrincipale(
              key: const ValueKey<String>('attribution-retirer'),
              libelle: a.retirer,
              niveau: NiveauAction.tertiaire,
              pleineLargeur: false,
              onPress: () => unawaited(_retirer(f)),
            ),
          ),
        ],
      ),
    );
  }
}
