// Reprise du foyer, la succession de titularite (EA-11, doc sections 12, 13
// et 19, sans planche, UX_REVIEW_07 lignes 17 et 18, F18).
//
// - Le second adulte rattache, depuis « Forfait famille » (lien tertiaire,
//   UX_REVIEW_07 ligne 5 c) : une page a une etape, le texte du doc section
//   19 mot pour mot, puis « Ce qui sera repris » (section 12.6) et « Ce qui
//   n'est jamais repris » (section 12.7) en lignes groupees, « Deposer la
//   demande » au bord de fin, 16 sous la liste, et sa confirmation courte
//   (NN-CD). Ensuite, seul l'etat RENDU s'affiche : deposee, refusee par le
//   titulaire, en attente de l'administration, validee, refusee. « 30 jours »
//   n'est jamais un compte a rebours : la date d'examen possible n'est
//   montree que si le serveur la rend, telle quelle (F17).
// - Le titulaire, depuis sa notification ou la ligne de la place de Ma
//   famille : une page d'une seule decision, le texte du doc section 12.2,
//   « Refuser la demande » en bouton principal, sans confirmation (refuser ne
//   detruit rien, ligne 18 b), sans rien dire du demandeur (Q11).
//
// Une seule demande active : la page ne propose de deposer que si le serveur
// n'en rend aucune. Ton sobre, aucune formule de condoleances (Q10). Aucune
// piece demandee (doc section 20 point 10). L'administration decide toujours :
// rien n'est transfere par Flutter (doc section 12.8).
//
// Rien de recree (K-51) : `ConfirmDestructive`, `EtatSysteme`, `PageShell`,
// `LigneCleValeur`, `ActionPrincipale`, `BlocAsynchrone`,
// `Skeleton`, et les briques privees de l'invitation (ce fichier en est une
// partie, comme la sortie d'EA-8).
//
// **Aucune source serveur a ce jour** : la demande du second adulte
// (EA-BR-27) et la reponse du titulaire (EA-BR-28) rendent
// `CapaciteIndisponible`, la demonstration les surcharge (K-28).

part of 'invitation_conjoint.dart';

/// L'etat d'une demande de reprise, tel que le serveur le rend (doc section
/// 18, cas 16 a 20).
enum StatutReprise {
  /// Deposee, le titulaire en est informe.
  deposee,

  /// Le titulaire l'a refusee (doc section 12.5).
  refuseeParTitulaire,

  /// Sans reponse du titulaire, elle attend l'administration (section 12.3).
  attenteAdministration,

  /// L'administration l'a validee (section 12.6).
  validee,

  /// L'administration l'a refusee.
  refusee,
}

/// Ce que le second adulte lit de sa demande de reprise (EA-BR-27).
sealed class EtatReprise {
  const EtatReprise();
}

/// Aucune demande : le second adulte peut en deposer une.
final class RepriseAucune extends EtatReprise {
  /// Cree l'etat.
  const RepriseAucune();
}

/// La demande, son statut et ses dates rendues, jamais calculees (F17).
final class RepriseDemande extends EtatReprise {
  /// Cree l'etat.
  const RepriseDemande({
    required this.statut,
    this.deposeeLe,
    this.examenPossibleLe,
    this.redepotPossibleLe,
  });

  /// Le statut rendu.
  final StatutReprise statut;

  /// La date du depot, si elle est rendue.
  final DateTime? deposeeLe;

  /// La date a partir de laquelle l'administration pourra examiner la
  /// demande sans reponse du titulaire (section 12.3), si elle est rendue.
  final DateTime? examenPossibleLe;

  /// BACK-FRONT-REPRISE-1 (K-65) : apres un refus, la date a partir de
  /// laquelle une nouvelle demande pourra etre deposee, si elle est rendue.
  /// Jamais calculee ici (F17).
  final DateTime? redepotPossibleLe;
}

/// Ce que le titulaire lit de la demande qui le concerne (EA-BR-28).
sealed class DemandeRepriseRecue {
  const DemandeRepriseRecue();
}

/// Une demande attend : le titulaire peut la refuser (section 12.2).
final class RepriseARefuser extends DemandeRepriseRecue {
  /// Cree l'etat.
  const RepriseARefuser();
}

/// Le titulaire a refuse la demande (section 12.5).
final class RepriseRefuseeParVous extends DemandeRepriseRecue {
  /// Cree l'etat.
  const RepriseRefuseeParVous();
}

/// La reponse du serveur a un depot ou a un refus.
sealed class ResultatReprise {
  const ResultatReprise();
}

/// Le serveur a enregistre le geste ; l'etat se relit ensuite.
final class RepriseEnregistree extends ResultatReprise {
  /// Cree la reponse.
  const RepriseEnregistree();
}

/// La connexion a coupe : le geste n'est pas confirme, l'ecran ne dit que
/// cela (decision D5) ; la meme cle rend une nouvelle tentative sure.
final class RepriseEchecReseau extends ResultatReprise {
  /// Cree la reponse.
  const RepriseEchecReseau();
}

/// La reprise du foyer : idempotente par la cle fournie, une seule demande
/// active, l'administration decide (doc section 12.8).
abstract interface class PortRepriseFoyer {
  /// Le second adulte depose la demande (EA-BR-27).
  Future<ResultatReprise> deposer({required String cle});

  /// Le titulaire refuse la demande (EA-BR-28).
  Future<ResultatReprise> refuser({required String cle});
}

/// **Aucune source serveur a ce jour** (EA-BR-27, EA-BR-28).
class _RepriseIndisponible implements PortRepriseFoyer {
  const _RepriseIndisponible();

  @override
  Future<ResultatReprise> deposer({required String cle}) =>
      Future<ResultatReprise>.error(const CapaciteIndisponible('EA-BR-27'));

  @override
  Future<ResultatReprise> refuser({required String cle}) =>
      Future<ResultatReprise>.error(const CapaciteIndisponible('EA-BR-28'));
}

/// Le port de la reprise ; la demonstration le surcharge.
final Provider<PortRepriseFoyer> portRepriseFoyerProvider =
    Provider<PortRepriseFoyer>((Ref _) => const _RepriseIndisponible());

/// La demande de reprise du second adulte. **Aucune source serveur a ce
/// jour** (EA-BR-27) : `CapaciteIndisponible`.
final FutureProvider<EtatReprise> repriseFoyerProvider =
    FutureProvider<EtatReprise>(
      (Ref _) =>
          Future<EtatReprise>.error(const CapaciteIndisponible('EA-BR-27')),
    );

/// La demande de reprise qui concerne le titulaire. **Aucune source serveur
/// a ce jour** (EA-BR-28) : `CapaciteIndisponible`.
final FutureProvider<DemandeRepriseRecue> demandeRepriseRecueProvider =
    FutureProvider<DemandeRepriseRecue>(
      (Ref _) => Future<DemandeRepriseRecue>.error(
        const CapaciteIndisponible('EA-BR-28'),
      ),
    );

/// Le libelle d'un statut, tel qu'il se lit sur la ligne « Etat » (F21).
/// « En attente de l'administration » vient d'UX_REVIEW_07 ligne 17 c ; les
/// autres : libelles provisoires, lexique D4 (doc section 18).
String libelleStatutReprise(StatutReprise statut) => switch (statut) {
  StatutReprise.deposee => t.adulte.reprise.etats.deposee,
  StatutReprise.refuseeParTitulaire =>
    t.adulte.reprise.etats.refuseeParTitulaire,
  StatutReprise.attenteAdministration =>
    t.adulte.reprise.etats.attenteAdministration,
  StatutReprise.validee => t.adulte.reprise.etats.validee,
  StatutReprise.refusee => t.adulte.reprise.etats.refusee,
};

/// La phrase d'un statut : doc sections 12.3, 12.5 et 12.6 accordees a la
/// personne qui lit, libelles provisoires, lexique D4.
String phraseStatutReprise(StatutReprise statut) => switch (statut) {
  StatutReprise.deposee => t.adulte.reprise.phrases.deposee,
  StatutReprise.refuseeParTitulaire =>
    t.adulte.reprise.phrases.refuseeParTitulaire,
  StatutReprise.attenteAdministration =>
    t.adulte.reprise.phrases.attenteAdministration,
  StatutReprise.validee => t.adulte.reprise.phrases.validee,
  StatutReprise.refusee => t.adulte.reprise.phrases.refusee,
};

/// « Demande de reprise du foyer », cote second adulte.
class RepriseFoyerPage extends ConsumerStatefulWidget {
  /// Cree la page.
  const RepriseFoyerPage({
    required this.onRetour,
    required this.onDeposee,
    super.key,
  });

  /// Retour au forfait famille.
  final VoidCallback onRetour;

  /// La demande est enregistree : la page relue dans l'etat rendu.
  final VoidCallback onDeposee;

  /// « Deposer la demande ».
  static const Key deposerKey = Key('reprise.deposer');

  /// « Annuler », au bord de la poursuite (contrat B).
  static const Key annulerKey = Key('reprise.annuler');

  /// L'etat rendu de la demande.
  static const Key etatKey = Key('reprise.etat');

  @override
  ConsumerState<RepriseFoyerPage> createState() => _RepriseFoyerPageState();
}

class _RepriseFoyerPageState extends ConsumerState<RepriseFoyerPage> {
  /// Une cle par page : une nouvelle tentative apres une coupure la reprend.
  final String _cle = const Uuid().v4();

  bool _envoi = false;
  _Echec? _echec;

  Future<void> _deposer() async {
    if (_envoi) return;
    // Une declaration grave se relit et se confirme (UX_REVIEW_07 ligne
    // 17 b) : la confirmation dit que le titulaire sera informe et que
    // l'administration decide. Question d'UX_REVIEW_07, consequence :
    // libelle provisoire, lexique D4.
    final bool confirme = await ConfirmDestructive.demander(
      context,
      question: t.adulte.reprise.deposerQuestion,
      consequence: t.adulte.reprise.deposerConsequence,
      libelleConfirmer: t.adulte.reprise.deposer,
    );
    if (!confirme || !mounted || _envoi) return;
    // Le reseau a pu couper pendant la confirmation (revue EA-R m13).
    if (ref.read(horsLigneProvider).value ?? false) return;
    setState(() {
      _envoi = true;
      _echec = null;
    });
    ResultatReprise resultat;
    try {
      resultat = await ref.read(portRepriseFoyerProvider).deposer(cle: _cle);
    } on CapaciteIndisponible {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _echec = _Echec.indisponible;
      });
      return;
    } on Object {
      resultat = const RepriseEchecReseau();
    }
    if (!mounted) return;
    switch (resultat) {
      case RepriseEnregistree():
        setState(() => _envoi = false);
        // L'etat se relit, jamais un etat garde (E7).
        ref.invalidate(repriseFoyerProvider);
        widget.onDeposee();
      case RepriseEchecReseau():
        setState(() {
          _envoi = false;
          _echec = _Echec.reseau;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<EtatReprise> lecture = ref.watch(repriseFoyerProvider);
    final String titre = t.adulte.reprise.titre;
    if (lecture.error is CapaciteIndisponible) {
      return PageShell(
        titre: titre,
        onRetour: widget.onRetour,
        child: const EtatSysteme(
          nature: NatureEtat.indisponible,
          dependance: 'EA-BR-27',
        ),
      );
    }
    final EtatReprise? etat = lecture.value;
    if (etat == null) {
      return PageShell(
        titre: titre,
        onRetour: widget.onRetour,
        child: BlocAsynchrone<EtatReprise>(
          valeur: lecture,
          squelette: const Skeleton.texte(lignes: 4),
          onReessayer: () => ref.invalidate(repriseFoyerProvider),
          construire: (EtatReprise _) => const SizedBox.shrink(),
        ),
      );
    }
    return PopScope(
      canPop: !_envoi,
      child: PageShell(
        titre: titre,
        onRetour: _envoi ? null : widget.onRetour,
        child: _Colonne(
          auBordDeDebut: true,
          child: switch (etat) {
            final RepriseDemande demande => _EtatDemande(demande: demande),
            RepriseAucune() => _explication(context),
          },
        ),
      ),
    );
  }

  Widget _explication(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final r = t.adulte.reprise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Doc section 19, mot pour mot.
        Text(
          r.explication,
          style: palette.inkStrong.applyTo(
            Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
          ),
        ),
        Ecart.vXxl,
        // Doc section 12.6, mot pour mot.
        _ListeGroupee(
          titre: r.reprisTitre,
          lignes: <String>[
            r.repris.profils,
            r.repris.composition,
            r.repris.paiements,
            r.repris.parcours,
          ],
        ),
        Ecart.vXl,
        // Doc section 12.7, accorde au titulaire (« du defunt » devient « du
        // titulaire » : il est peut-etre vivant, doc section 13) : libelles
        // provisoires, lexique D4.
        _ListeGroupee(
          titre: r.jamaisTitre,
          lignes: <String>[
            r.jamais.identifiants,
            r.jamais.messages,
            r.jamais.conversations,
            r.jamais.historique,
            r.jamais.moyensPaiement,
            r.jamais.pieces,
            r.jamais.donnees,
          ],
        ),
        Ecart.vMd,
        // Doc section 12.7, derniere phrase, mot pour mot.
        _Note(texte: r.succession, attenuee: true),
        // D5 : la demande n'est pas confirmee, rien de plus.
        if (_echec == _Echec.reseau) ...<Widget>[
          Ecart.vLg,
          _FocusALApparition(
            key: InviterConjointPage.focusEchecKey,
            child: EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: r.depotEchecTitre,
              phrase: r.echecPhrase,
            ),
          ),
        ] else if (_echec == _Echec.indisponible) ...<Widget>[
          Ecart.vLg,
          const EtatSysteme(
            nature: NatureEtat.indisponible,
            dependance: 'EA-BR-27',
          ),
        ],
        // Rien ne part tout seul. Libelle provisoire, lexique D4.
        if (horsLigne) ...<Widget>[Ecart.vLg, _Note(texte: r.horsLigne)],
        Ecart.vLg,
        // Un seul bouton dominant au bord de fin, 16 sous la liste (K-42) ;
        // « Annuler » avant lui, comme les autres etapes de la vague
        // (contrat B, EA-6).
        _Actions(
          secondaire: ActionPrincipale(
            key: RepriseFoyerPage.annulerKey,
            libelle: t.commun.annuler,
            onPress: _envoi ? null : widget.onRetour,
            niveau: NiveauAction.secondaire,
            pleineLargeur: false,
          ),
          principale: ActionPrincipale(
            key: RepriseFoyerPage.deposerKey,
            libelle: r.deposer,
            onPress: horsLigne || _echec == _Echec.indisponible
                ? null
                : () => unawaited(_deposer()),
            enCours: _envoi,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }
}

/// Une liste de lecture groupee sur une seule surface (K-42 point 4), sous
/// son titre : `_Carte` de l'invitation (une `AppCard`, M4), des lignes de
/// texte sans action.
/// `GroupeReglages` exige une icone par rubrique : ces lignes n'en sont pas.
class _ListeGroupee extends StatelessWidget {
  const _ListeGroupee({required this.titre, required this.lignes});

  final String titre;
  final List<String> lignes;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            titre,
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ),
        Ecart.vSm,
        _Carte(
          lignes: <Widget>[
            for (final String ligne in lignes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  ligne,
                  style: palette.surfaceRaised.applyTo(
                    textes.bodyMedium ?? const TextStyle(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// L'etat rendu d'une demande : motif, depot et etat sur une carte (F21),
/// puis sa phrase. Aucune action : une seule demande active, l'administration
/// decide (doc section 12.8).
class _EtatDemande extends StatelessWidget {
  const _EtatDemande({required this.demande});

  final RepriseDemande demande;

  @override
  Widget build(BuildContext context) {
    final r = t.adulte.reprise;
    final DateTime? depot = demande.deposeeLe;
    final DateTime? examen = demande.examenPossibleLe;
    final DateTime? redepot = demande.redepotPossibleLe;
    final bool refusee =
        demande.statut == StatutReprise.refusee ||
        demande.statut == StatutReprise.refuseeParTitulaire;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _FocusALApparition(
          key: RepriseFoyerPage.etatKey,
          child: Semantics(
            liveRegion: true,
            child: _Carte(
              lignes: <Widget>[
                // Motif systeme du doc section 12.1, mot pour mot.
                LigneCleValeur(cle: r.motif, valeur: r.motifDeces),
                if (depot != null)
                  LigneCleValeur(cle: r.deposeeLe, valeur: dateLongue(depot)),
                LigneCleValeur(
                  cle: r.etat,
                  valeur: libelleStatutReprise(demande.statut),
                ),
              ],
            ),
          ),
        ),
        Ecart.vLg,
        _Note(texte: phraseStatutReprise(demande.statut), attenuee: true),
        // La date rendue seulement, jamais « dans 30 jours » (F17).
        if (demande.statut == StatutReprise.deposee &&
            examen != null) ...<Widget>[
          Ecart.vMd,
          _Note(
            texte: r.phrases.examenLe(date: dateEcheance(examen)),
            attenuee: true,
          ),
        ],
        if (refusee && redepot != null) ...<Widget>[
          Ecart.vMd,
          _Note(
            key: const ValueKey<String>('reprise-redepot'),
            texte: r.phrases.redepotLe(date: dateEcheance(redepot)),
            attenuee: true,
          ),
        ],
      ],
    );
  }
}

/// La demande de reprise, cote titulaire : une seule decision (UX_REVIEW_07
/// ligne 18).
class RepriseTitulairePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const RepriseTitulairePage({
    required this.onRetour,
    required this.onRefusee,
    super.key,
  });

  /// Retour a Ma famille.
  final VoidCallback onRetour;

  /// Le refus est enregistre : la page relue dans l'etat rendu.
  final VoidCallback onRefusee;

  /// « Refuser la demande ».
  static const Key refuserKey = Key('reprise.refuser');

  /// Le refus enregistre.
  static const Key refuseeKey = Key('reprise.refusee');

  @override
  ConsumerState<RepriseTitulairePage> createState() =>
      _RepriseTitulairePageState();
}

class _RepriseTitulairePageState extends ConsumerState<RepriseTitulairePage> {
  /// Une cle par page : une nouvelle tentative apres une coupure la reprend.
  final String _cle = const Uuid().v4();

  bool _envoi = false;
  _Echec? _echec;

  // Pas de confirmation : refuser protege le titulaire et ne detruit rien
  // (UX_REVIEW_07 ligne 18 b).
  Future<void> _refuser() async {
    if (_envoi) return;
    // Hors ligne, rien ne part (revue EA-R m13).
    if (ref.read(horsLigneProvider).value ?? false) return;
    setState(() {
      _envoi = true;
      _echec = null;
    });
    ResultatReprise resultat;
    try {
      resultat = await ref.read(portRepriseFoyerProvider).refuser(cle: _cle);
    } on CapaciteIndisponible {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _echec = _Echec.indisponible;
      });
      return;
    } on Object {
      resultat = const RepriseEchecReseau();
    }
    if (!mounted) return;
    switch (resultat) {
      case RepriseEnregistree():
        setState(() => _envoi = false);
        ref
          ..invalidate(demandeRepriseRecueProvider)
          ..invalidate(foyerTitulaireProvider);
        widget.onRefusee();
      case RepriseEchecReseau():
        setState(() {
          _envoi = false;
          _echec = _Echec.reseau;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<DemandeRepriseRecue> lecture = ref.watch(
      demandeRepriseRecueProvider,
    );
    final String titre = t.adulte.reprise.titre;
    if (lecture.error is CapaciteIndisponible) {
      return PageShell(
        titre: titre,
        onRetour: widget.onRetour,
        child: const EtatSysteme(
          nature: NatureEtat.indisponible,
          dependance: 'EA-BR-28',
        ),
      );
    }
    final DemandeRepriseRecue? demande = lecture.value;
    if (demande == null) {
      return PageShell(
        titre: titre,
        onRetour: widget.onRetour,
        child: BlocAsynchrone<DemandeRepriseRecue>(
          valeur: lecture,
          squelette: const Skeleton.texte(lignes: 2),
          onReessayer: () => ref.invalidate(demandeRepriseRecueProvider),
          construire: (DemandeRepriseRecue _) => const SizedBox.shrink(),
        ),
      );
    }
    return PopScope(
      canPop: !_envoi,
      child: PageShell(
        titre: titre,
        onRetour: _envoi ? null : widget.onRetour,
        child: _Colonne(
          auBordDeDebut: true,
          child: switch (demande) {
            // Doc section 12.5 accorde au titulaire : libelle provisoire,
            // lexique D4.
            RepriseRefuseeParVous() => _FocusALApparition(
              key: RepriseTitulairePage.refuseeKey,
              child: _Note(
                texte: t.adulte.reprise.titulaire.refusee,
                attenuee: true,
              ),
            ),
            RepriseARefuser() => _decision(context),
          },
        ),
      ),
    );
  }

  Widget _decision(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final r = t.adulte.reprise.titulaire;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Doc section 12.2, mot pour mot ; rien sur le demandeur (Q11).
        Text(
          r.notification,
          style: palette.inkStrong.applyTo(
            textes.titleMedium ?? const TextStyle(),
          ),
        ),
        Ecart.vXs,
        Text(
          r.consigne,
          style: palette.inkMuted.applyTo(
            textes.bodyLarge ?? const TextStyle(),
          ),
        ),
        // D5 : le refus n'est pas confirme, rien de plus.
        if (_echec == _Echec.reseau) ...<Widget>[
          Ecart.vLg,
          _FocusALApparition(
            key: InviterConjointPage.focusEchecKey,
            child: EtatSysteme(
              nature: NatureEtat.echecServeur,
              titre: r.refusEchecTitre,
              phrase: t.adulte.reprise.echecPhrase,
            ),
          ),
        ] else if (_echec == _Echec.indisponible) ...<Widget>[
          Ecart.vLg,
          const EtatSysteme(
            nature: NatureEtat.indisponible,
            dependance: 'EA-BR-28',
          ),
        ],
        // Rien ne part tout seul. Libelle provisoire, lexique D4.
        if (horsLigne) ...<Widget>[Ecart.vLg, _Note(texte: r.horsLigne)],
        Ecart.vLg,
        // Bouton principal : c'est la protection du titulaire, pas une
        // destruction (UX_REVIEW_07 ligne 18 a).
        _Actions(
          principale: ActionPrincipale(
            key: RepriseTitulairePage.refuserKey,
            libelle: r.refuser,
            onPress: horsLigne || _echec == _Echec.indisponible
                ? null
                : () => unawaited(_refuser()),
            enCours: _envoi,
            pleineLargeur: false,
          ),
        ),
      ],
    );
  }
}
