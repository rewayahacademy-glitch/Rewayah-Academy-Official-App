/// CAP29-D : verifier et publier (spec CAP-29 §3.5, §4.3, maquette M03).
///
/// L'ecran reunit ce qu'il faut pour decider : la source et le fichier, la
/// revue des droits (la fonction unique de revue, atteinte aussi par
/// « Completer les droits » de la fiche), et le controle de la version.
///
/// - **Chaque critere est rendu par le serveur** (valide, bloque, pas encore
///   evalue) ; aucun compteur code en dur, aucun critere presume valide.
/// - **« Publier la version » n'est jamais grise** : tant que le serveur n'a
///   pas tout valide, le bouton reste actif et la phrase du blocage est
///   visible a cote, avec la liste de ce qui bloque et comment le lever (la
///   maquette M03 montre un bouton desactive : elle n'est pas copiee).
/// - Quand tout est valide, une **confirmation recapitulative** dit la portee
///   et l'effet (version immuable, visible des classes attribuees) ; le succes
///   n'est annonce qu'apres la reponse du serveur ; la publication est
///   atomique, jamais a moitie.
/// - La publication n'est offerte qu'avec la capacite `peutPublier`, jamais
///   selon un role ; sans elle, le controle reste consultable.
/// - Idempotence : une cle par tentative, gardee tant que la publication n'a
///   pas abouti (un reseau coupe ne publie pas deux fois).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/accessibilite/texte_sans_coupure.dart';
import '../../../core/admin/admin_domaine.dart';
import '../../../core/admin/modeles_bibliotheque_admin.dart';
import '../../../core/admin/port_bibliotheque_admin.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/reseau/etat_sans_donnees.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/action_principale.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/chargement_avec_delais.dart';
import '../../../core/widgets/confirm_destructive.dart';
import '../../../core/widgets/etat_systeme.dart';
import '../../../core/widgets/ligne_cle_valeur.dart';
import '../../../core/widgets/page_shell.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/sous_navigation_domaine.dart';
import '../../../core/widgets/zone_saisie.dart';
import '../catalogue/catalogue_page.dart' show rangBibliotheque;
import '../libelles_bibliotheque.dart';
import '../porte_bibliotheque.dart';

/// L'ecran « Verifier et publier » du support [supportId].
class PublicationPage extends StatelessWidget {
  /// Cree l'ecran.
  const PublicationPage({required this.supportId, super.key});

  /// Le support.
  final String supportId;

  @override
  Widget build(BuildContext context) {
    return PageShell(
      titre: t.admin.bibliotheque.publication.titre,
      sousTitre: t.admin.bibliotheque.publication.intro,
      entete: SousNavigationDomaine(
        onglets: ongletsPedagogie(),
        indexActif: rangBibliotheque,
      ),
      onRetour: () =>
          GoRouter.of(context).go(Routes.adminPedagogieSupport(supportId)),
      child: PorteBibliotheque(
        construire: (
          BuildContext context,
          PortBibliothequeAdmin port,
          CapacitesBibliotheque capacites,
        ) => _Publication(port: port, supportId: supportId),
      ),
    );
  }
}

class _Publication extends StatefulWidget {
  const _Publication({required this.port, required this.supportId});

  final PortBibliothequeAdmin port;
  final String supportId;

  @override
  State<_Publication> createState() => _PublicationEtat();
}

class _PublicationEtat extends State<_Publication> {
  FicheSupport? _fiche;
  ControleVersion? _controle;
  Object? _erreur;
  bool _chargement = true;
  bool _envoi = false;
  String? _message;
  bool _echec = false;
  bool _conflit = false;
  bool _bloquee = false;
  bool _controleApprouve = false;
  String _cle = const Uuid().v4();

  final TextEditingController _source = TextEditingController();
  final TextEditingController _titulaire = TextEditingController();
  final TextEditingController _attribution = TextEditingController();
  final Set<UsageDroit> _usages = <UsageDroit>{};

  @override
  void initState() {
    super.initState();
    unawaited(_charger());
  }

  @override
  void dispose() {
    _source.dispose();
    _titulaire.dispose();
    _attribution.dispose();
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
      final VersionSupport? v = f.derniereVersion;
      final ControleVersion? c = v == null
          ? null
          : await widget.port.controler(v.id);
      if (!mounted) return;
      _source.text = f.droits.sourceTitre ?? '';
      _titulaire.text = f.droits.titulaire ?? '';
      _attribution.text = f.droits.attribution ?? '';
      _usages
        ..clear()
        ..addAll(f.droits.usages);
      setState(() {
        _fiche = f;
        _controle = c;
        _chargement = false;
        _conflit = false;
        _bloquee = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e;
        _chargement = false;
      });
    }
  }

  Future<void> _enregistrerDroits(FicheSupport f) async {
    final a = t.admin.bibliotheque.publication;
    final VersionSupport? v = f.derniereVersion;
    if (v == null) return;
    setState(() {
      _envoi = true;
      _message = null;
      _echec = false;
    });
    try {
      final ResultatEcriture r = await widget.port.revoirDroits(
        supportId: f.support.id,
        versionId: v.id,
        saisie: SaisieDroits(
          sourceTitre: _source.text.trim(),
          titulaire: _titulaire.text.trim(),
          preuveFournie: f.droits.preuveFournie,
          usages: <UsageDroit>{..._usages},
          attribution: _attribution.text.trim().isEmpty
              ? null
              : _attribution.text.trim(),
          expireLeUtc: f.droits.expireLeUtc,
          approuver: _controleApprouve,
        ),
        revisionAttendue: f.revision,
      );
      if (!mounted) return;
      switch (r) {
        case EcritureFaite():
          await _charger(garderMessage: true);
          if (mounted) setState(() => _message = a.droitsEnregistres);
        case EcritureEnConflit():
          setState(() => _conflit = true);
      }
    } on Object {
      if (mounted) {
        setState(() {
          _echec = true;
          _message = a.droitsEchec;
        });
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _publier(FicheSupport f) async {
    final a = t.admin.bibliotheque.publication;
    final VersionSupport? v = f.derniereVersion;
    final ControleVersion? c = _controle;
    if (v == null || c == null) return;
    if (!c.publiable) {
      // Jamais grise : on relit le controle du serveur et la phrase du blocage
      // reste visible.
      setState(() => _bloquee = true);
      try {
        final ControleVersion frais = await widget.port.controler(v.id);
        if (mounted) setState(() => _controle = frais);
      } on Object {
        // Le controle precedent reste affiche.
      }
      return;
    }
    final bool oui = await ConfirmDestructive.demander(
      context,
      question: a.confirmerTitre(numero: '${v.numero}'),
      consequence: a.confirmerEffet,
      libelleConfirmer: a.confirmerBouton,
      irreversible: true,
    );
    if (!oui || !mounted) return;
    setState(() {
      _envoi = true;
      _message = null;
      _echec = false;
    });
    try {
      final ResultatPublication r = await widget.port.publier(
        supportId: f.support.id,
        versionId: v.id,
        revisionAttendue: f.revision,
        cle: _cle,
      );
      if (!mounted) return;
      switch (r) {
        case VersionPubliee():
          _cle = const Uuid().v4();
          await _charger(garderMessage: true);
          if (mounted) setState(() => _message = a.publiee);
        case PublicationBloquee(:final ControleVersion controle):
          setState(() {
            _controle = controle;
            _bloquee = true;
          });
        case PublicationEnConflit():
          setState(() => _conflit = true);
      }
    } on Object {
      // Reseau coupe : la meme cle sert a la nouvelle tentative.
      if (mounted) {
        setState(() {
          _echec = true;
          _message = a.echec;
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
          key: const ValueKey<String>('publication-introuvable'),
          nature: NatureEtat.introuvable,
          phrase: a.introuvable,
          libelleAction: a.retourCatalogue,
          onAction: () =>
              GoRouter.of(context).go(Routes.adminPedagogieBibliotheque),
        );
      }
      return e is BibliothequeHorsLigne
          ? EtatSansDonnees(
              key: const ValueKey<String>('publication-sans-donnees'),
              quoi: a.sansDonnees,
              onAction: () => unawaited(_charger()),
            )
          : EtatSysteme(
              key: const ValueKey<String>('publication-erreur'),
              nature: NatureEtat.echecServeur,
              phrase: a.erreur,
              onAction: () => unawaited(_charger()),
            );
    }
    final FicheSupport f = _fiche!;
    final VersionSupport? v = f.derniereVersion;
    final ControleVersion? c = _controle;
    final bool brouillon = v?.modifiable ?? false;
    return Column(
      key: const ValueKey<String>('publication-contenu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: TexteSansCoupure(
            f.support.titre,
            key: const ValueKey<String>('publication-titre'),
            style: Theme.of(context).textTheme.titleLarge,
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
                  _echec ? 'publication-echec' : 'publication-message',
                ),
              ),
            ),
          ),
        _Apercu(fiche: f),
        Ecart.vLg,
        _Droits(
          fiche: f,
          source: _source,
          titulaire: _titulaire,
          attribution: _attribution,
          usages: _usages,
          controleApprouve: _controleApprouve,
          editable: brouillon && f.capacites.peutModifier && !f.support.retire,
          envoi: _envoi,
          conflit: _conflit,
          onApprouve: (bool v) => setState(() => _controleApprouve = v),
          onUsage: (UsageDroit u, bool v) => setState(() {
            if (v) {
              _usages.add(u);
            } else {
              _usages.remove(u);
            }
          }),
          onEnregistrer: () => unawaited(_enregistrerDroits(f)),
          onRecharger: () => unawaited(_charger()),
        ),
        Ecart.vLg,
        if (c != null) _Checklist(controle: c),
        Ecart.vLg,
        _Publier(
          fiche: f,
          controle: c,
          brouillon: brouillon,
          envoi: _envoi,
          bloquee: _bloquee,
          onPublier: () => unawaited(_publier(f)),
        ),
      ],
    );
  }
}

class _Apercu extends StatelessWidget {
  const _Apercu({required this.fiche});

  final FicheSupport fiche;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.publication;
    final VersionSupport? v = fiche.derniereVersion;
    final bool aFichier = v?.empreinte != null;
    return AppCard(
      key: const ValueKey<String>('publication-apercu'),
      entete: Semantics(
        header: true,
        child: TexteSansCoupure(
          a.apercuTitre,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LigneCleValeur(
            cle: t.admin.bibliotheque.fiche.meta.type,
            valeur: libelleType(fiche.support.type),
          ),
          Ecart.vSm,
          Text(aFichier ? a.apercuFichier : a.apercuAucunFichier),
          if (aFichier) ...<Widget>[
            Ecart.vSm,
            Text(
              a.empreinte(valeur: v!.empreinte!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Droits extends StatelessWidget {
  const _Droits({
    required this.fiche,
    required this.source,
    required this.titulaire,
    required this.attribution,
    required this.usages,
    required this.controleApprouve,
    required this.editable,
    required this.envoi,
    required this.conflit,
    required this.onApprouve,
    required this.onUsage,
    required this.onEnregistrer,
    required this.onRecharger,
  });

  final FicheSupport fiche;
  final TextEditingController source;
  final TextEditingController titulaire;
  final TextEditingController attribution;
  final Set<UsageDroit> usages;
  final bool controleApprouve;
  final bool editable;
  final bool envoi;
  final bool conflit;
  final void Function(bool) onApprouve;
  final void Function(UsageDroit, bool) onUsage;
  final VoidCallback onEnregistrer;
  final VoidCallback onRecharger;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.publication;
    final d = t.admin.bibliotheque.import.droits;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: const ValueKey<String>('publication-droits'),
      entete: Semantics(
        header: true,
        child: TexteSansCoupure(a.droitsTitre, style: textes.titleMedium),
      ),
      child: !editable
          ? Text(a.droitsFiges, key: const ValueKey<String>('droits-figes'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ZoneSaisie(
                  controleur: source,
                  cleChamp: const ValueKey<String>('droits-source'),
                  libelle: d.source,
                  maxLignes: 1,
                ),
                Ecart.vMd,
                ZoneSaisie(
                  controleur: titulaire,
                  cleChamp: const ValueKey<String>('droits-titulaire'),
                  libelle: d.titulaire,
                  maxLignes: 1,
                ),
                Ecart.vMd,
                ZoneSaisie(
                  controleur: attribution,
                  cleChamp: const ValueKey<String>('droits-attribution'),
                  libelle: d.attribution,
                  maxLignes: 2,
                ),
                Ecart.vMd,
                Text(d.usages, style: textes.titleSmall),
                for (final UsageDroit u in UsageDroit.values)
                  Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      key: ValueKey<String>('droits-usage-${u.name}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: TexteSansCoupure(libelleUsage(u)),
                      value: usages.contains(u),
                      onChanged: (bool? v) => onUsage(u, v ?? false),
                    ),
                  ),
                Material(
                  type: MaterialType.transparency,
                  child: CheckboxListTile(
                    key: const ValueKey<String>('droits-approuver'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: TexteSansCoupure(a.confirmerControle),
                    value: controleApprouve,
                    onChanged: (bool? v) => onApprouve(v ?? false),
                  ),
                ),
                Ecart.vMd,
                if (conflit) ...<Widget>[
                  Text(
                    t.admin.bibliotheque.fiche.conflit,
                    key: const ValueKey<String>('publication-conflit'),
                  ),
                  Ecart.vSm,
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ActionPrincipale(
                      key: const ValueKey<String>('publication-recharger'),
                      libelle: t.admin.bibliotheque.fiche.recharger,
                      niveau: NiveauAction.tertiaire,
                      pleineLargeur: false,
                      onPress: onRecharger,
                    ),
                  ),
                ] else
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ActionPrincipale(
                      key: const ValueKey<String>('publication-enregistrer'),
                      libelle: a.enregistrerDroits,
                      niveau: NiveauAction.secondaire,
                      pleineLargeur: false,
                      enCours: envoi,
                      onPress: envoi ? null : onEnregistrer,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.controle});

  final ControleVersion controle;

  String _libelle(CleCritere c) {
    final k = t.admin.bibliotheque.publication.criteres;
    return switch (c) {
      CleCritere.source => k.source,
      CleCritere.titulaire => k.titulaire,
      CleCritere.preuve => k.preuve,
      CleCritere.usageApplication => k.usageApplication,
      CleCritere.usageClasse => k.usageClasse,
      CleCritere.usageTelechargement => k.usageTelechargement,
      CleCritere.expirationAttribution => k.expirationAttribution,
      CleCritere.fichierSain => k.fichierSain,
      CleCritere.renduTeste => k.renduTeste,
      CleCritere.langueNiveau => k.langueNiveau,
      CleCritere.versionEmpreinte => k.versionEmpreinte,
    };
  }

  String _explication(CleCritere c) {
    final k = t.admin.bibliotheque.publication.explications;
    return switch (c) {
      CleCritere.source => k.source,
      CleCritere.titulaire => k.titulaire,
      CleCritere.preuve => k.preuve,
      CleCritere.usageApplication => k.usageApplication,
      CleCritere.usageClasse => k.usageClasse,
      CleCritere.usageTelechargement => k.usageTelechargement,
      CleCritere.expirationAttribution => k.expirationAttribution,
      CleCritere.fichierSain => k.fichierSain,
      CleCritere.renduTeste => k.renduTeste,
      CleCritere.langueNiveau => k.langueNiveau,
      CleCritere.versionEmpreinte => k.versionEmpreinte,
    };
  }

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.publication;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    return AppCard(
      key: const ValueKey<String>('publication-checklist'),
      entete: Semantics(
        header: true,
        child: TexteSansCoupure(a.checklistTitre, style: textes.titleMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final CritereControle k in controle.criteres)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              // Un etat se dit par trois signaux : l'icone, le mot, l'encre.
              child: Semantics(
                container: true,
                excludeSemantics: true,
                label:
                    '${_libelle(k.cle)}, ${switch (k.etat) {
                      EtatCritere.valide => a.etats.valide,
                      EtatCritere.bloque => a.etats.bloque,
                      EtatCritere.inconnu => a.etats.inconnu,
                    }}',
                child: Row(
                  key: ValueKey<String>('critere-${k.cle.name}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    IconTheme(
                      data: (switch (k.etat) {
                        EtatCritere.valide => palette.inkSuccess,
                        EtatCritere.bloque => palette.inkAlert,
                        EtatCritere.inconnu => palette.inkMuted,
                      }).asIconTheme(size: AppSpacing.xxl),
                      child: Icon(switch (k.etat) {
                        EtatCritere.valide => AppIcons.succes.actif,
                        EtatCritere.bloque => AppIcons.avertissement.actif,
                        EtatCritere.inconnu => AppIcons.attente.repos,
                      }),
                    ),
                    Ecart.hMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TexteSansCoupure(
                            _libelle(k.cle),
                            style: textes.titleSmall,
                          ),
                          Text(switch (k.etat) {
                            EtatCritere.valide => a.etats.valide,
                            EtatCritere.bloque => a.etats.bloque,
                            EtatCritere.inconnu => a.etats.inconnu,
                          }, style: textes.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (controle.bloquants.isNotEmpty) ...<Widget>[
            Ecart.vSm,
            Semantics(
              header: true,
              child: Text(
                a.blocagesTitre,
                key: const ValueKey<String>('publication-blocages-titre'),
                style: textes.titleSmall,
              ),
            ),
            Ecart.vSm,
            for (final CritereControle k in controle.bloquants)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  _explication(k.cle),
                  key: ValueKey<String>('blocage-${k.cle.name}'),
                ),
              ),
          ] else
            Text(a.aucunBlocage, key: const ValueKey<String>('aucun-blocage')),
        ],
      ),
    );
  }
}

class _Publier extends StatelessWidget {
  const _Publier({
    required this.fiche,
    required this.controle,
    required this.brouillon,
    required this.envoi,
    required this.bloquee,
    required this.onPublier,
  });

  final FicheSupport fiche;
  final ControleVersion? controle;
  final bool brouillon;
  final bool envoi;
  final bool bloquee;
  final VoidCallback onPublier;

  @override
  Widget build(BuildContext context) {
    final a = t.admin.bibliotheque.publication;
    if (!brouillon) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(a.dejaPubliee, key: const ValueKey<String>('deja-publiee')),
          Ecart.vMd,
          ActionPrincipale(
            key: const ValueKey<String>('publication-vers-fiche'),
            libelle: a.versLaFiche,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
            onPress: () =>
                GoRouter.of(context)
                    .go(Routes.adminPedagogieSupport(fiche.support.id)),
          ),
        ],
      );
    }
    if (!fiche.capacites.peutPublier) {
      return Text(
        a.pasDeCapacite,
        key: const ValueKey<String>('publication-sans-capacite'),
      );
    }
    final bool publiable = controle?.publiable ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // La phrase du blocage reste visible tant que le serveur n'a pas tout
        // valide : le bouton n'est pas grise, la raison est a cote.
        if (!publiable)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Semantics(
              liveRegion: bloquee,
              child: Text(
                a.bloque,
                key: const ValueKey<String>('publication-bloque'),
              ),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ActionPrincipale(
            key: const ValueKey<String>('publication-publier'),
            libelle: a.publier,
            pleineLargeur: false,
            enCours: envoi,
            onPress: envoi ? null : onPublier,
          ),
        ),
      ],
    );
  }
}
