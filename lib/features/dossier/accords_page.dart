/// Lot E6 (decision du directeur du 17/10/2026, DECISION-ENTREE) : la page
/// unique des accords, `/attente/accords`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/domain/enums.dart';
import '../../core/dossier/etat_dossier.dart';
import '../../core/dossier/resignature_contrat.dart';
import '../../core/dossier/service_dossier.dart';
import '../../core/dossier/versions_contrat.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/profil/service_acceptations.dart';
import '../../core/recrutement/port_signature_contrat.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/zone_saisie.dart';
import '../connexion/recuperation_page.dart'
    show IssueEnvoiLien, issueEchecEnvoi;
import '../consentements/texte_observation.dart';
import '../recrutement/signature_contrat_page.dart';
import 'politique_controle.dart';
import 'signature_page.dart' show ParagrapheTexte, paragraphesA3, paragraphesE1;

/// L'adresse de la page des accords pour une ancienne adresse du portail
/// (`/attente/accuse`, `/attente/contrat`) : le parametre `pour` (eleve
/// adulte) est garde, rien d'autre.
String versLesAccords(Uri ancienne) {
  final String? pour = ancienne.queryParameters['pour'];
  return pour == null
      ? Routes.attenteAccords
      : Uri(
          path: Routes.attenteAccords,
          queryParameters: <String, String>{'pour': pour},
        ).toString();
}

/// Une case de la page des accords.
enum _Case {
  /// « Ce que vous devez savoir » (texte A3, ou E1 pour l'enseignant).
  savoir,

  /// Les visites des parents (conditions du tuteur).
  observation,

  /// Le contrat de l'enseignant, sans port de signature serveur.
  contrat,

  /// L'article 9 du contrat enseignant.
  religion,

  /// Le contrat de l'enseignant servi par le serveur (nom tape).
  contratServeur,
}

/// Un envoi de la page des accords : une acceptation enregistree a part.
enum _Envoi {
  /// L'accuse de l'ADR-011 ([SorteContrat.accuseEnregistrementControle]).
  accuse,

  /// Le contrat propre au role, par le service du dossier.
  contrat,

  /// Le contrat de l'enseignant, par le port de signature serveur.
  contratServeur,
}

/// Lot E6 (decision du directeur du 17/10/2026, DECISION-ENTREE) : **une
/// seule page des accords**, qui defile.
///
/// Chaque texte que le role doit accepter y figure une fois, suivi de sa case
/// ([CaseAccordTexte], toute la carte est la cible) : « Ce que vous devez
/// savoir » (A3, ou E1 pour l'enseignant), puis pour le tuteur et l'eleve
/// adulte (`?pour=moi`) les visites des parents, pour l'enseignant son
/// contrat (clause des visites de controle, politique, article 9). Le texte
/// A3 n'est affiche qu'une fois : les conditions du tuteur le reprennent, sa
/// case le couvre.
///
/// Un seul bouton « Suivant », **inactif tant qu'une case manque** : cette
/// regle remplace BOUTONS-GRISES-1 pour les accords. On ne passe donc jamais
/// sans consentir, et la page ne renvoie jamais en arriere pour cocher.
///
/// L'envoi : le service n'enregistre qu'une acceptation a la fois
/// ([ServiceDossier.accepterContrat]) ; les acceptations partent dans l'ordre
/// de la page. Un echec arrete l'envoi et laisse la page en place, cases
/// gardees ; ce qui est deja enregistre n'est pas renvoye (l'unicite en base
/// porte sur profil, sorte, version). Une acceptation deja faite (lue dans
/// l'etat du dossier) reste affichee, cochee et figee.
class AccordsPage extends ConsumerStatefulWidget {
  /// Cree la page des accords.
  const AccordsPage({super.key});

  @override
  ConsumerState<AccordsPage> createState() => _AccordsPageState();
}

class _AccordsPageState extends ConsumerState<AccordsPage> {
  final Map<_Case, bool> _cochees = <_Case, bool>{};
  final Set<_Envoi> _envoyes = <_Envoi>{};
  final TextEditingController _nom = TextEditingController();
  bool _envoi = false;
  String? _erreur;
  String? _erreurNom;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  bool _cochee(_Case c) => _cochees[c] ?? false;

  void _cocher(_Case c, bool v) => setState(() {
    _cochees[c] = v;
    _erreur = null;
  });

  /// La variante des visites des parents, lue dans `?pour=`.
  VarianteObservation _variante() {
    String? pour;
    try {
      pour = GoRouterState.of(context).uri.queryParameters['pour'];
    } on Object {
      pour = null;
    }
    return VarianteObservation.depuisParametre(pour);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<EtatDossier> etat = ref.watch(etatDossierProvider);
    final EtatDossier? lu = etat.hasValue && !etat.requireValue.roleIllisible
        ? etat.requireValue
        : null;
    if (lu == null) {
      final bool illisible = etat.hasError || etat.hasValue;
      return PageShell(
        titre: t.accords.titre,
        onRetour: () => GoRouter.of(context).go(Routes.attente),
        actions: illisible
            ? ActionPrincipale(
                libelle: t.commun.reessayer,
                niveau: NiveauAction.secondaire,
                onPress: () => ref.invalidate(etatDossierProvider),
              )
            : null,
        child: _Colonne(
          children: <Widget>[
            if (illisible)
              Semantics(
                liveRegion: true,
                child: Text(
                  issueEchecEnvoi(etat.error ?? const FormatException()) ==
                          IssueEnvoiLien.horsLigne
                      ? t.attente.horsLigne
                      : t.attente.illisible,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            else
              const Skeleton.liste(lignes: 6),
          ],
        ),
      );
    }
    return _contenu(lu);
  }

  Widget _contenu(EtatDossier lu) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final SorteContrat sorte = SorteContrat.pour(lu.role ?? AppRole.guardian);
    final bool enseignant = sorte == SorteContrat.contratEnseignant;
    final bool serveur =
        enseignant && ref.watch(portSignatureContratProvider) != null;
    final bool resignature =
        enseignant && ref.watch(resignatureContratEnseignantProvider);

    // Ce qui reste a accepter, lu dans l'etat du dossier ; un envoi reussi
    // sur cette page compte comme fait.
    final bool accuseAFaire =
        !lu.accuseSigne && !_envoyes.contains(_Envoi.accuse);

    // Le contrat de l'enseignant servi par le serveur : son texte, sa version
    // et la signature existante viennent du port.
    final AsyncValue<ContratEtSignature>? lecture = serveur
        ? ref.watch(contratEtSignatureProvider)
        : null;
    final ContratEtSignature? contratLu = lecture?.value;
    final bool serveurSigne =
        contratLu != null &&
        contratLu.signature != null &&
        contratLu.signature!.version == contratLu.contrat.version;
    final bool contratAFaire = serveur
        ? !serveurSigne && !_envoyes.contains(_Envoi.contratServeur)
        : (!lu.contratSigne || resignature) &&
              !_envoyes.contains(_Envoi.contrat);

    final String version = VersionsContrat.pour(
      sorte,
      demonstration: ref.watch(serviceDossierProvider).demonstration,
      politiquePubliee: ref.watch(politiqueControlePublieeProvider),
    );
    final bool ancienContrat = version == VersionsContrat.courante;

    // Les cases a cocher pour que « Suivant » s'active.
    final List<_Case> requises = <_Case>[
      if (accuseAFaire) _Case.savoir,
      if (contratAFaire && !enseignant) _Case.observation,
      if (contratAFaire && enseignant && !serveur) _Case.contrat,
      if (contratAFaire && enseignant && !serveur && !ancienContrat)
        _Case.religion,
      if (contratAFaire && serveur) _Case.contratServeur,
    ];
    final int restantes = requises.where((_Case c) => !_cochee(c)).length;
    final bool nomRequis = contratAFaire && serveur;
    final bool nomManque = nomRequis && _nom.text.trim().isEmpty;
    final bool serveurLisible =
        !nomRequis ||
        (contratLu != null && empreinteConforme(contratLu.contrat));
    final bool rienAFaire = !accuseAFaire && !contratAFaire;
    final bool pret =
        !rienAFaire && restantes == 0 && !nomManque && serveurLisible;

    final ContratEtSignature? aSigner = nomRequis ? contratLu : null;
    final bool pieceAFournir =
        enseignant && lu.manquants.contains(PieceManquante.pieceIdentite);

    final List<Widget> sections = <Widget>[
      if (rienAFaire)
        Semantics(
          liveRegion: true,
          child: Text(t.accords.dejaAcceptes, style: textes.titleMedium),
        )
      else ...<Widget>[
        Text(t.accords.intro, style: textes.bodyMedium),
        Ecart.vXxl,
        // 1. Ce que vous devez savoir : le texte A3 (E1), une seule fois.
        _Section(
          titre: t.attente.carteAccuse,
          children: <Widget>[
            _Paragraphes(
              paragraphes: enseignant ? paragraphesE1() : paragraphesA3(),
            ),
            Ecart.vXl,
            CaseAccordTexte(
              libelle: t.accords.caseSavoir,
              cochee: !accuseAFaire || _cochee(_Case.savoir),
              onChanged: !accuseAFaire || _envoi
                  ? null
                  : (bool v) => _cocher(_Case.savoir, v),
            ),
          ],
        ),
        // 2. Tuteur et eleve adulte : les visites des parents.
        if (!enseignant && contratAFaire) ...<Widget>[
          Ecart.vXxl,
          _Section(
            titre: t.consentement.texte.titre,
            children: <Widget>[
              TexteObservation(variante: _variante()),
              Ecart.vXl,
              CaseAccordObservation(
                variante: _variante(),
                cochee: _cochee(_Case.observation),
                onChanged: _envoi
                    ? null
                    : (bool v) => _cocher(_Case.observation, v),
              ),
            ],
          ),
        ],
        // 3. Enseignant, sans port serveur : le contrat de l'application.
        if (enseignant && !serveur && contratAFaire) ...<Widget>[
          Ecart.vXxl,
          _Section(
            titre: t.accords.sectionContrat,
            children: <Widget>[
              if (resignature) ...<Widget>[
                Text(t.contrat.resignature, style: textes.bodyMedium),
                Ecart.vXl,
              ],
              if (ancienContrat) ...<Widget>[
                Text(t.contrat.intro, style: textes.bodyMedium),
                Ecart.vXl,
                _Paragraphes(
                  paragraphes: <ParagrapheTexte>[
                    (titre: t.contrat.pointEnregistrement, corps: null),
                    (titre: t.contrat.pointControle, corps: null),
                    (titre: t.contrat.pointCoordonnees, corps: null),
                  ],
                ),
              ] else ...<Widget>[
                _Paragraphes(
                  paragraphes: <ParagrapheTexte>[
                    (titre: t.contrat.pointCoordonnees, corps: null),
                    (
                      titre: t.contrat.clauseControle.titre,
                      corps: t.contrat.clauseControle.texte,
                    ),
                  ],
                ),
                // La politique que la clause fait « confirmer avoir recue »,
                // a lire avant de cocher : un lien, jamais un bouton plein.
                LienFleche(
                  libelle: t.contrat.politique.lien,
                  onPress: () => unawaited(ouvrirPolitiqueControle(context)),
                ),
              ],
              Ecart.vXl,
              CaseAccordTexte(
                libelle: t.accords.caseContrat,
                cochee: _cochee(_Case.contrat),
                onChanged: _envoi
                    ? null
                    : (bool v) => _cocher(_Case.contrat, v),
              ),
              if (!ancienContrat) ...<Widget>[
                Ecart.vMd,
                CaseAccordTexte(
                  libelle: t.contrat.clauseControle.caseReligion,
                  cochee: _cochee(_Case.religion),
                  onChanged: _envoi
                      ? null
                      : (bool v) => _cocher(_Case.religion, v),
                ),
              ],
            ],
          ),
        ],
        // 4. Enseignant, port serveur branche : le contrat servi, nom tape.
        if (nomRequis) ...<Widget>[
          Ecart.vXxl,
          _Section(
            titre: t.accords.sectionContrat,
            children: <Widget>[
              _contratServeur(lecture!, aSigner, palette, textes),
            ],
          ),
        ],
      ],
    ];

    return PageShell(
      titre: t.accords.titre,
      onRetour: () => GoRouter.of(context).go(Routes.attente),
      // Le pied suit la colonne bornee du texte ; au-dela du mobile, le
      // bouton garde la largeur de son libelle, au bord de fin.
      actions: _Colonne(
        alignement: AppGabarit.de(context) == Gabarit.mobile
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.end,
        children: <Widget>[
          if (_erreur != null) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                _erreur!,
                key: const ValueKey<String>('accords-erreur'),
                textAlign: TextAlign.center,
                style: palette.inkAlert.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ] else if (!rienAFaire) ...<Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                restantes > 0
                    ? t.accords.reste(n: restantes)
                    : nomManque
                    ? t.recrutement.signature.nomVide
                    : t.accords.toutCoche,
                key: const ValueKey<String>('accords-reste'),
                textAlign: TextAlign.center,
                style: palette.inkMuted.applyTo(
                  textes.bodyMedium ?? const TextStyle(),
                ),
              ),
            ),
            Ecart.vMd,
          ],
          // Inactif tant qu'une case manque (DECISION-ENTREE du 17/10/2026,
          // qui remplace BOUTONS-GRISES-1 pour les accords).
          ActionPrincipale(
            key: const ValueKey<String>('accords-suivant'),
            libelle: rienAFaire ? t.commun.continuer : t.accords.suivant,
            enCours: _envoi,
            fleche: true,
            onPress: rienAFaire
                ? () => _suite(pieceAFournir: pieceAFournir)
                : pret && !_envoi
                ? () => unawaited(
                    _envoyer(
                      accuse: accuseAFaire,
                      contrat: contratAFaire && !serveur,
                      sorte: sorte,
                      version: version,
                      contratServeur: aSigner?.contrat,
                      resignature: resignature,
                      pieceAFournir: pieceAFournir,
                    ),
                  )
                : null,
          ),
        ],
      ),
      child: _Colonne(children: sections),
    );
  }

  /// La section du contrat servi par le serveur : chargement, erreur,
  /// texte altere, ou texte a signer avec le nom et sa case.
  Widget _contratServeur(
    AsyncValue<ContratEtSignature> lecture,
    ContratEtSignature? lu,
    AppPalette palette,
    TextTheme textes,
  ) {
    final r = t.recrutement.signature;
    void relire() => ref
      ..invalidate(contratEnseignantCourantProvider)
      ..invalidate(maSignatureEnseignantProvider);
    if (lu == null) {
      if (!lecture.hasError) {
        return const Skeleton.liste(lignes: 6);
      }
      final Object e = lecture.error!;
      final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
      return EtatSysteme(
        key: const ValueKey<String>('accords-contrat-erreur'),
        nature: NatureEtat.echecServeur,
        phrase: e is CapaciteIndisponible
            ? r.indisponible
            : e is ContratIntrouvable
            ? r.introuvable
            : horsLigne || e is HorsLigneSignature
            ? r.sansDonnees
            : r.erreurLecture,
        onAction: relire,
      );
    }
    final ContratCourant contrat = lu.contrat;
    if (!empreinteConforme(contrat)) {
      return EtatSysteme(
        key: const ValueKey<String>('accords-contrat-altere'),
        nature: NatureEtat.echecServeur,
        phrase: r.texteAltere,
        onAction: () => ref.invalidate(contratEnseignantCourantProvider),
      );
    }
    final Signature? ancienne = lu.signature;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (ancienne != null) ...<Widget>[
          Text(
            r.nouvelleVersion(version: ancienne.version),
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
        ],
        Text(
          r.version(version: contrat.version.replaceAll('-', '‑')),
          style: textes.titleSmall,
        ),
        Ecart.vMd,
        AppCard(
          child: SelectableText(
            contrat.texte,
            key: const ValueKey<String>('accords-contrat-texte'),
            style: textes.bodyMedium,
          ),
        ),
        Ecart.vLg,
        ZoneSaisie(
          controleur: _nom,
          cleChamp: const ValueKey<String>('accords-nom'),
          libelle: r.champNom,
          aide: r.aideNom,
          majuscules: TextCapitalization.words,
          actionClavier: TextInputAction.done,
          erreur: _erreurNom,
          lectureSeule: _envoi,
          onChanged: (_) => setState(() => _erreurNom = null),
        ),
        Ecart.vMd,
        CaseAccordTexte(
          libelle: r.accuse,
          cochee: _cochee(_Case.contratServeur),
          onChanged: _envoi
              ? null
              : (bool v) => _cocher(_Case.contratServeur, v),
        ),
      ],
    );
  }

  /// Envoie les acceptations dans l'ordre de la page, une a une. Un echec
  /// arrete l'envoi : la page reste, cases gardees, et le prochain appui
  /// reprend apres ce qui est deja enregistre.
  Future<void> _envoyer({
    required bool accuse,
    required bool contrat,
    required SorteContrat sorte,
    required String version,
    required ContratCourant? contratServeur,
    required bool resignature,
    required bool pieceAFournir,
  }) async {
    setState(() {
      _envoi = true;
      _erreur = null;
      _erreurNom = null;
    });
    final ServiceDossier service = ref.read(serviceDossierProvider);
    final r = t.recrutement.signature;
    try {
      if (accuse && !_envoyes.contains(_Envoi.accuse)) {
        await service.accepterContrat(
          SorteContrat.accuseEnregistrementControle,
          VersionsContrat.pour(SorteContrat.accuseEnregistrementControle),
        );
        _envoyes.add(_Envoi.accuse);
      }
      if (contrat && !_envoyes.contains(_Envoi.contrat)) {
        await service.accepterContrat(sorte, version);
        _envoyes.add(_Envoi.contrat);
      }
      if (contratServeur != null && !_envoyes.contains(_Envoi.contratServeur)) {
        final PortSignatureContrat? port = ref.read(
          portSignatureContratProvider,
        );
        if (port == null) {
          throw const CapaciteIndisponible(dependanceSignatureContrat);
        }
        try {
          await port.signerContrat(
            contratServeur.kind,
            contratServeur.version,
            _nom.text.trim(),
          );
        } on VersionPerimee {
          // Le texte a change pendant la lecture : il est recharge, le nom
          // reste, sa case se decoche (elle portait sur l'ancien texte).
          ref.invalidate(contratEnseignantCourantProvider);
          if (mounted) {
            setState(() {
              _cochees[_Case.contratServeur] = false;
              _erreur = r.versionPerimee;
            });
          }
          return;
        } on NomVide {
          if (mounted) setState(() => _erreurNom = r.nomVide);
          return;
        } on NomTropLong {
          if (mounted) setState(() => _erreurNom = r.nomTropLong);
          return;
        }
        _envoyes.add(_Envoi.contratServeur);
        ref
          ..invalidate(contratEnseignantCourantProvider)
          ..invalidate(maSignatureEnseignantProvider);
      }
      ref.invalidate(etatDossierProvider);
      if (resignature) {
        // Une relecture en echec n'annule pas la signature, deja enregistree :
        // la redirection se reposera la question a la lecture suivante.
        try {
          ref.invalidate(acceptationsProvider);
          await ref.read(acceptationsProvider.future);
        } on Object {
          // Rien : voir ci-dessus.
        }
      }
      if (mounted) {
        _suite(pieceAFournir: pieceAFournir);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _erreur =
              e is HorsLigneSignature ||
                  issueEchecEnvoi(e) == IssueEnvoiLien.horsLigne
              ? t.contrat.horsLigne
              : e is NonConnecte
              ? r.nonConnecte
              : t.contrat.erreur,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _envoi = false);
      }
    }
  }

  /// Apres les accords : la piece d'identite pour l'enseignant qui ne l'a
  /// pas encore deposee (elle demande un fichier, elle reste une etape), le
  /// portail sinon, qui dit l'etat du compte.
  void _suite({required bool pieceAFournir}) =>
      GoRouter.of(context)
          .go(pieceAFournir ? Routes.attentePiece : Routes.attente);
}

/// La colonne de la page, bornee comme le portail d'attente.
class _Colonne extends StatelessWidget {
  const _Colonne({
    required this.children,
    this.alignement = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final CrossAxisAlignment alignement;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppPage.largeurReglages),
      child: Column(
        crossAxisAlignment: alignement,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    ),
  );
}

/// Une section de la page des accords : son titre, son texte, sa case.
class _Section extends StatelessWidget {
  const _Section({required this.titre, required this.children});

  final String titre;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Semantics(
        header: true,
        child: Text(titre, style: Theme.of(context).textTheme.titleMedium),
      ),
      Ecart.vMd,
      ...children,
    ],
  );
}

/// Des paragraphes en clair, dans UNE carte groupee.
class _Paragraphes extends StatelessWidget {
  const _Paragraphes({required this.paragraphes});

  final List<ParagrapheTexte> paragraphes;

  @override
  Widget build(BuildContext context) => GroupeReglages(
    lignes: <LigneRubrique>[
      for (final ParagrapheTexte p in paragraphes)
        LigneRubrique(
          icone: AppIcons.controleQualite,
          libelle: p.titre,
          legende: p.corps,
        ),
    ],
  );
}
