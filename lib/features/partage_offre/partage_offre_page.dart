/// `CAND-06` : la carte a partager (`/attente/partage`), « Aidez une personne a
/// apprendre la parole d'Allah. ».
///
/// Une personne en Salle d'examen peut envoyer l'offre a quelqu'un qui voudrait
/// apprendre, par une carte au format story. **Tres peu de mots** (directeur,
/// 22/10/2026 : « la fierte de participer a un geste noble et la simplicite ») :
/// l'invitation en titre, la langue de la carte, l'apercu, la mention
/// « Facultatif » et les gestes. **Facultatif et sans aucun effet sur la
/// candidature** : la page le dit avant les boutons, et rien ne s'ecrit en base
/// (aucun compteur, aucun evenement). Pas de recrutement d'enseignants, pas de
/// prix : decision du directeur du 22/10/2026
/// (`DECISION-CANDIDATURES-2026-10-21.md`, section 1 bis).
///
/// **La carte s'adapte a la personne qui partage** : sa variante (une femme, ou
/// les hommes et le genre inconnu) vient de son profil, jamais devinee ; sa
/// langue par defaut est la premiere langue d'enseignement de sa candidature
/// (francais, anglais ou portugais), sinon la langue de l'application. Quatre
/// puces (Francais, English, Portugues, l'arabe) changent la langue de la carte
/// avant de partager.
///
/// Trois gestes : « Je partage » (menu de partage de l'appareil, avec l'image,
/// seulement quand l'appareil le propose), « Enregistrer l'image » et « Copier
/// le lien ». L'image est rendue des l'ouverture, avant le toucher : le menu de
/// partage du navigateur doit s'ouvrir dans le geste de la personne.
///
/// Etats : l'etat du dossier et les reglages de la carte se lisent (`Skeleton`,
/// erreur avec « Reessayer », hors ligne), pas de candidature en cours (retour
/// au portail), pas de lien d'offre (capacite indisponible), image en
/// preparation (boutons en cours), image non preparee (« Reessayer »), puis le
/// contenu avec le retour de chaque geste. Le partage, l'enregistrement et la
/// copie ne demandent pas de reseau : hors ligne, le bandeau de la page le dit
/// une fois et rien d'autre change.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/candidature/modeles_candidature.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/i18n/isolat_bidi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/partage_offre/lien_offre.dart';
import '../../core/partage_offre/personnalisation_carte.dart';
import '../../core/partage_offre/port_partage_offre.dart';
import '../../core/router/routes.dart';
import '../../core/tc_telechargement/port_enregistrement_fichier.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../candidature/lecture_page.dart';
import 'carte_partage.dart';
import 'rendu_carte.dart';
import 'textes_carte.dart';

/// La page de partage de la carte.
class PartageOffrePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const PartageOffrePage({super.key});

  /// La cle de la lecture du dossier.
  static const Key etatKey = ValueKey<String>('partage-etat');

  /// La cle de la phrase « pas encore disponible ».
  static const Key nonOuvertKey = ValueKey<String>('partage-non-ouvert');

  /// La cle de la lecture des reglages de la carte (genre, langues).
  static const Key reglagesKey = ValueKey<String>('partage-reglages');

  @override
  ConsumerState<PartageOffrePage> createState() => _PartageOffrePageState();
}

class _PartageOffrePageState extends ConsumerState<PartageOffrePage> {
  bool _versLePortail = false;

  /// Revient au portail, une seule fois, apres le rendu en cours.
  void _retourAuPortail() {
    if (_versLePortail) {
      return;
    }
    _versLePortail = true;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) {
        context.go(Routes.attente);
      }
    });
  }

  @override
  Widget build(BuildContext context) => lecturePage<EtatDossier>(
    ref: ref,
    key: PartageOffrePage.etatKey,
    titre: t.recrutement.partage.titre,
    valeur: ref.watch(etatDossierProvider),
    titreEchec: t.recrutement.portail.nonCharge,
    onReessayer: () => ref.invalidate(etatDossierProvider),
    construire: (EtatDossier lu) {
      final CandidatureDossier c = lu.candidature;
      // Une adresse tapee sans candidature en cours (aucune, refusee, retiree) :
      // le portail dit ou on en est. La carte s'adresse a qui candidate.
      if (!lu.profilExiste ||
          !c.existe ||
          c.issue != IssueCandidature.enCours) {
        _retourAuPortail();
        return PageSimple(
          titre: t.recrutement.partage.titre,
          corps: const Skeleton.liste(lignes: 3),
        );
      }
      final Uri? lien = ref.watch(lienOffreProvider);
      if (lien == null) {
        return PageSimple(
          titre: t.recrutement.partage.titre,
          corps: EtatSysteme(
            key: PartageOffrePage.nonOuvertKey,
            nature: NatureEtat.indisponible,
            phrase: t.recrutement.partage.nonOuvert,
            dependance: 'SITE_URL',
          ),
        );
      }
      // La variante et la langue de depart de la carte : lues une fois.
      return lecturePage<ReglagesCarte>(
        ref: ref,
        key: PartageOffrePage.reglagesKey,
        titre: t.recrutement.partage.titre,
        valeur: ref.watch(reglagesCarteProvider),
        titreEchec: t.recrutement.portail.nonCharge,
        onReessayer: () => ref.invalidate(reglagesCarteProvider),
        construire: (ReglagesCarte r) => _Partage(lien: lien, reglages: r),
      );
    },
  );
}

/// Ce que la page dit d'un geste termine : un succes ou un echec.
@immutable
class _Retour {
  const _Retour(this.texte, {required this.echec});

  final String texte;
  final bool echec;
}

/// Le contenu : la langue de la carte, l'apercu, la mention « Facultatif » et
/// les trois gestes.
class _Partage extends ConsumerStatefulWidget {
  const _Partage({required this.lien, required this.reglages});

  final Uri lien;

  /// La variante et les langues d'enseignement de la personne.
  final ReglagesCarte reglages;

  /// La cle de l'apercu de la carte.
  static const Key apercuKey = ValueKey<String>('partage-apercu');

  /// La cle du libelle du choix de la langue de la carte.
  static const Key langueKey = ValueKey<String>('partage-langue');

  /// La cle des quatre puces de la langue de la carte.
  static const Key languesKey = ValueKey<String>('partage-langues');

  /// La cle de la phrase « facultatif, sans effet sur la candidature ».
  static const Key facultatifKey = ValueKey<String>('partage-facultatif');

  /// La cle du bouton « Partager ».
  static const Key partagerKey = ValueKey<String>('partage-partager');

  /// La cle du bouton « Enregistrer l'image ».
  static const Key enregistrerKey = ValueKey<String>('partage-enregistrer');

  /// La cle du bouton « Copier le lien ».
  static const Key copierKey = ValueKey<String>('partage-copier');

  /// La cle du bouton « Reessayer » (image non preparee).
  static const Key reessayerKey = ValueKey<String>('partage-reessayer');

  /// La cle du message du dernier geste.
  static const Key retourKey = ValueKey<String>('partage-retour');

  /// La cle de la note de l'appareil (pas de menu, ou lien seul).
  static const Key noteKey = ValueKey<String>('partage-note');

  /// La cle de la ligne du lien.
  static const Key lienKey = ValueKey<String>('partage-lien');

  @override
  ConsumerState<_Partage> createState() => _PartageState();
}

class _PartageState extends ConsumerState<_Partage> {
  final GlobalKey _cle = GlobalKey(debugLabel: 'carte-partage');

  /// L'image rendue, nulle tant qu'elle se prepare ou si elle a echoue.
  Uint8List? _png;

  /// Vrai tant que l'image se prepare (vrai des l'ouverture).
  bool _preparation = true;

  /// Vrai quand la carte n'a pas pu etre rendue en image.
  bool _carteEnEchec = false;

  bool _partageEnCours = false;
  bool _enregistrementEnCours = false;
  _Retour? _retour;

  /// Une preparation plus recente rend caduque celle qui revient apres elle.
  int _ticket = 0;

  /// La langue de la carte : celle de depart, puis celle que la personne choisit.
  /// L'image est a refaire quand elle change.
  late LangueCarte _langue = widget.reglages.langueParDefaut(
    LangueCarte.depuisLocale(LocaleSettings.currentLocale),
  );

  /// La variante de la carte, lue sur le profil de la personne.
  VarianteCarte get _variante => widget.reglages.variante;

  @override
  void initState() {
    super.initState();
    // L'image se rend des que la carte est peinte, avant tout toucher.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      unawaited(_preparer());
    });
  }

  @override
  void didUpdateWidget(_Partage ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.lien != widget.lien) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        unawaited(_preparer());
      });
    }
  }

  /// Change la langue de la carte : l'image se refait avec la nouvelle.
  void _choisirLangue(LangueCarte langue) {
    if (langue == _langue) {
      return;
    }
    setState(() {
      _langue = langue;
      _png = null;
      _preparation = true;
      _carteEnEchec = false;
      _retour = null;
    });
    // La carte se repeint dans la langue choisie, puis l'image est relue.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      unawaited(_preparer());
    });
  }

  Future<void> _preparer() async {
    if (!mounted) {
      return;
    }
    final int ticket = ++_ticket;
    setState(() {
      _preparation = true;
      _carteEnEchec = false;
      _png = null;
      _retour = null;
    });
    try {
      final Uint8List png = await ref.read(renduCarteProvider)(_cle);
      if (!mounted || ticket != _ticket) {
        return;
      }
      setState(() {
        _png = png;
        _preparation = false;
      });
    } on Object {
      if (!mounted || ticket != _ticket) {
        return;
      }
      setState(() {
        _preparation = false;
        _carteEnEchec = true;
        _retour = _Retour(t.recrutement.partage.echec.carte, echec: true);
      });
    }
  }

  /// Ouvre le menu de partage. **Aucun `await` avant l'appel du port** : le
  /// navigateur n'ouvre son menu que dans le geste de la personne.
  Future<void> _partager() async {
    final Uint8List? png = _png;
    if (png == null || _partageEnCours) {
      return;
    }
    final PortPartageOffre port = ref.read(portPartageOffreProvider);
    final c = t.recrutement.partage;
    final TextesCarte carte = textesCarte[_langue]!;
    setState(() {
      _partageEnCours = true;
      _retour = null;
    });
    _Retour? retour;
    try {
      final IssuePartage issue = await port.partager(
        png: png,
        nomFichier: nomFichierCarte,
        // Le message lu par la personne qui recoit, dans la langue de la carte :
        // ce qu'elle y gagne.
        titre: carte.titre,
        texte: carte.sousTitre,
        lien: widget.lien,
      );
      // Fermer le menu n'est pas une erreur : aucun message.
      retour = issue == IssuePartage.partage
          ? _Retour(c.fait.partage, echec: false)
          : null;
    } on Object {
      retour = _Retour(c.echec.partage, echec: true);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _partageEnCours = false;
      _retour = retour;
    });
  }

  Future<void> _enregistrer() async {
    final Uint8List? png = _png;
    if (png == null || _enregistrementEnCours) {
      return;
    }
    final PortEnregistrementFichier port = ref.read(
      portEnregistrementFichierProvider,
    );
    final c = t.recrutement.partage;
    setState(() {
      _enregistrementEnCours = true;
      _retour = null;
    });
    _Retour? retour;
    try {
      final String? destination = await port.enregistrerCopie(
        octets: png,
        nomFichierPropose: nomFichierCarte,
        typeMime: 'image/png',
      );
      // Hors du web, `null` est la fermeture de la boite d'enregistrement : pas
      // un echec, aucun message. Sur le web, le navigateur telecharge sans
      // boite et le selecteur ne rend jamais d'adresse.
      retour = destination != null || kIsWeb
          ? _Retour(c.fait.enregistre, echec: false)
          : null;
    } on Object {
      retour = _Retour(c.echec.enregistrement, echec: true);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _enregistrementEnCours = false;
      _retour = retour;
    });
  }

  Future<void> _copier() async {
    final c = t.recrutement.partage;
    setState(() => _retour = null);
    _Retour retour;
    try {
      await Clipboard.setData(ClipboardData(text: widget.lien.toString()));
      retour = _Retour(c.fait.copie, echec: false);
    } on Object {
      retour = _Retour(c.echec.copie, echec: true);
    }
    if (!mounted) {
      return;
    }
    setState(() => _retour = retour);
  }

  /// Un geste de la page : le seul `ActionPrincipale` plein est celui du geste
  /// que l'appareil propose en premier ([plein]).
  Widget _geste({
    required Key cle,
    required String libelle,
    required VoidCallback? onPress,
    required bool plein,
    bool enCours = false,
    String? libelleSemantique,
  }) => ActionPrincipale(
    key: cle,
    libelle: libelle,
    libelleSemantique: libelleSemantique,
    niveau: plein ? NiveauAction.principale : NiveauAction.secondaire,
    // Le geste plein est l'unique invitation de la page : en aplat violet,
    // comme « Continuer » (demande du directeur du 22/10/2026), la lavande
    // douce le ferait passer pour un bouton inerte.
    affirmee: plein,
    enCours: enCours,
    onPress: onPress,
  );

  /// Les gestes, dans l'ordre de lecture d'une colonne : le plein d'abord.
  ///
  /// Aucun bouton n'est grise : tant que l'image se prepare, le geste est « en
  /// cours » (l'indicateur remplace le libelle, la pression est ignoree) ;
  /// `_partager` et `_enregistrer` ne font rien sans image.
  List<Widget> _gestes(NiveauPartage niveau) {
    final c = t.recrutement.partage;
    final Widget copier = _geste(
      cle: _Partage.copierKey,
      libelle: c.copier,
      onPress: () => unawaited(_copier()),
      plein: false,
    );
    if (_carteEnEchec) {
      // L'image n'a pas pu etre rendue : on ne propose ni de la partager ni de
      // l'enregistrer. Le lien, lui, se copie.
      return <Widget>[
        _geste(
          cle: _Partage.reessayerKey,
          libelle: t.commun.reessayer,
          onPress: () => unawaited(_preparer()),
          plein: true,
        ),
        copier,
      ];
    }
    final bool peutPartager = niveau != NiveauPartage.aucun;
    return <Widget>[
      if (peutPartager)
        _geste(
          cle: _Partage.partagerKey,
          libelle: c.partager,
          libelleSemantique: c.partagerLaCarte,
          plein: true,
          enCours: _preparation || _partageEnCours,
          onPress: () => unawaited(_partager()),
        ),
      _geste(
        cle: _Partage.enregistrerKey,
        libelle: c.enregistrer,
        // Sans menu de partage, enregistrer l'image est le geste principal.
        plein: !peutPartager,
        enCours: _preparation || _enregistrementEnCours,
        onPress: () => unawaited(_enregistrer()),
      ),
      copier,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = t.recrutement.partage;
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);
    final PortPartageOffre port = ref.watch(portPartageOffreProvider);
    final NiveauPartage niveau = port.niveau;
    final bool large = AppGabarit.de(context) != Gabarit.mobile;

    // La langue de la carte : quatre puces exclusives, avant l'apercu. Le nom de
    // chaque langue est ecrit dans cette langue.
    final Widget langues = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          c.langueCarte,
          key: _Partage.langueKey,
          style: palette.inkMuted.applyTo(
            textes.labelMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vSm,
        Semantics(
          container: true,
          // Quatre puces, une retenue : a 320 points et texte agrandi elles
          // passent a la ligne, jamais un mot coupe.
          // Choix de formulaire, pas un filtre : la langue de la carte.
          child: Wrap(
            key: _Partage.languesKey,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final LangueCarte l in LangueCarte.values)
                Semantics(
                  inMutuallyExclusiveGroup: true,
                  child: FilterPill(
                    libelle: textesCarte[l]!.nomPropre,
                    retenue: l == _langue,
                    onPress: () => _choisirLangue(l),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    // La mention « Facultatif » avant les boutons : le seul texte de la page.
    final Widget facultatif = Text(
      c.facultatif,
      key: _Partage.facultatifKey,
      style: textes.titleSmall,
    );
    final String? note = _carteEnEchec
        ? null
        : switch (niveau) {
            NiveauPartage.aucun => c.sansMenu,
            NiveauPartage.lien => c.lienSeul,
            NiveauPartage.image => null,
          };
    final List<Widget> gestes = _gestes(niveau);
    final Widget boutons = large
        // Au bord de fin, le geste plein en dernier (premier a l'arrivee de la
        // lecture, dernier de la ligne).
        ? Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: gestes.reversed.toList(),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: gestes,
          );
    final _Retour? retour = _retour;
    final Widget? message = retour == null
        ? null
        : Semantics(
            liveRegion: true,
            child: Text(
              retour.texte,
              key: _Partage.retourKey,
              style: retour.echec
                  ? palette.inkAlert.applyTo(
                      textes.bodyMedium ?? const TextStyle(),
                    )
                  : textes.bodyMedium,
            ),
          );
    // Le retour d'un geste se lit sous les boutons, qui ne bougent pas sous le
    // doigt. Celui d'une image non preparee se lit avant : « Reessayer » est
    // alors le seul geste, et sa raison doit etre sous les yeux.
    final bool messageEnHaut = _carteEnEchec;
    final Widget suite = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (note != null) ...<Widget>[
          Text(
            note,
            key: _Partage.noteKey,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vLg,
        ],
        if (message != null && messageEnHaut) ...<Widget>[message, Ecart.vLg],
        boutons,
        if (message != null && !messageEnHaut) ...<Widget>[Ecart.vLg, message],
        Ecart.vLg,
        SelectableText(
          c.lien(lien: isolerSens(lienLisible(widget.lien))),
          key: _Partage.lienKey,
          style: palette.inkMuted.applyTo(
            textes.bodyMedium ?? const TextStyle(),
          ),
        ),
      ],
    );

    final Widget apercu = _Apercu(
      cle: _cle,
      lien: widget.lien,
      langue: _langue,
      variante: _variante,
      largeur: large ? _Apercu.largeurLarge : _Apercu.largeurMobile,
    );

    return PageShell(
      titre: invitationPartage(_variante),
      onRetour: () => GoRouter.of(context).go(Routes.attente),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
          child: large
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          langues,
                          Ecart.vXl,
                          facultatif,
                          Ecart.vLg,
                          suite,
                        ],
                      ),
                    ),
                    Ecart.hXxl,
                    apercu,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    langues,
                    Ecart.vLg,
                    Center(child: apercu),
                    Ecart.vXl,
                    facultatif,
                    Ecart.vLg,
                    suite,
                  ],
                ),
        ),
      ),
    );
  }
}

/// L'apercu : la carte a sa taille d'export, reduite pour l'ecran. La
/// `RepaintBoundary` est a l'interieur de la reduction : l'image exportee a la
/// taille de la carte, jamais celle de l'apercu.
class _Apercu extends StatelessWidget {
  const _Apercu({
    required this.cle,
    required this.lien,
    required this.langue,
    required this.variante,
    required this.largeur,
  });

  final GlobalKey cle;
  final Uri lien;
  final LangueCarte langue;
  final VarianteCarte variante;
  final double largeur;

  /// La largeur de l'apercu sur telephone.
  static const double largeurMobile = 224;

  /// La largeur de l'apercu sur tablette et bureau.
  static const double largeurLarge = 288;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final double hauteur =
        largeur * CartePartage.hauteur / CartePartage.largeur;
    return DecoratedBox(
      key: _Partage.apercuKey,
      decoration: AppElevation.avecFilet(
        surface: palette.surfaceRaised,
        filet: palette.contourCarte,
        ombre: palette.ombre,
        arrondi: AppRadius.arrondiMd,
        ombres: AppElevation.niveau1(palette.ombre),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.arrondiMd,
        child: SizedBox(
          width: largeur,
          height: hauteur,
          child: FittedBox(
            child: SizedBox(
              width: CartePartage.largeur,
              height: CartePartage.hauteur,
              child: RepaintBoundary(
                key: cle,
                child: CartePartage(
                  lien: lien,
                  langue: langue,
                  variante: variante,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
