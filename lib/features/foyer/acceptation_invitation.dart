// Cote du second adulte (EA-7, sans planche, UX_REVIEW_07 ligne 10) : il
// recoit l'invitation dans SON propre compte, lit ce que le titulaire verra
// et ne verra pas (texte T1 d'UX_REVIEW_07, a valider par le directeur, Q1),
// puis accepte ou refuse, deux boutons de meme poids (derogation ecrite
// d'UX_REVIEW_07 ligne 10 et Q5 : la charte 09 section 3 prime ici sur le
// contrat B regle 1). Aucune case « J'ai lu » : la lecture et le bouton
// valent relecture (ligne 10 e).
//
// Etats du doc section 5.2 cote invite : a repondre ; inéligible et deja dans
// un autre foyer, sous la meme forme neutre (F4, doc section 11) ; acceptee ;
// « En attente de validation administrative » pour un remplacement (doc
// section 10.4, texte T2) ; perimee (expiree, ou annulee avant la reponse :
// une reponse tardive ne rattache personne) ; erreur reseau (D5) ; double
// envoi ; hors ligne. Sans compte : la page renvoie vers la connexion
// existante, qui cree le compte, sans la modifier.
//
// Rien de recree (K-51) : `PageEtape`, `PageShell`, `ActionPrincipale`,
// `EtatSysteme`, `BlocAsynchrone`, `Skeleton`, et les briques privees de
// l'invitation du titulaire (ce fichier en est une partie).
//
// **Aucune source serveur a ce jour** (EA-BR-20) : la lecture et la reponse
// rendent `CapaciteIndisponible`, la demonstration les surcharge (K-28).

part of 'invitation_conjoint.dart';

/// L'invitation recue par le second adulte, telle que le serveur la rend pour
/// le compte connecte (EA-BR-20).
sealed class EtatInvitationRecue {
  const EtatInvitationRecue();
}

/// L'invitation attend la reponse de la personne connectee.
final class InvitationARepondre extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationARepondre({
    required this.prenomTitulaire,
    required this.titulaireFeminin,
    this.validationRequise = false,
    this.dureeConservation,
  });

  /// Le prenom de la personne qui invite, titulaire du foyer.
  final String prenomTitulaire;

  /// Vrai quand la titulaire est une femme : « elle doit voir », « Elle
  /// saura » (T1, variante titulaire femme).
  final bool titulaireFeminin;

  /// Vrai pour un remplacement : le rattachement devra etre valide par
  /// l'administration (doc section 10, texte T2).
  final bool validationRequise;

  /// La duree de conservation de la trace du rattachement, deja redigee par
  /// le serveur (charte 09 section 8 point 8, Q14). `null` : la phrase n'est
  /// pas montree, aucune duree n'est inventee.
  final String? dureeConservation;
}

/// La personne a rejoint le forfait famille : son compte est rattache.
final class InvitationAcceptee extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationAcceptee(this.prenomTitulaire, {this.enregistreeLe});

  /// Le prenom du titulaire.
  final String prenomTitulaire;

  /// La date du choix, rendue par le serveur (recu date, charte 09 section
  /// 3, EA-BR-20). `null` : aucune date n'est montree, aucune n'est inventee.
  final DateTime? enregistreeLe;
}

/// L'invitation est acceptee et le rattachement attend la validation de
/// l'administration (remplacement, doc section 10.4).
final class InvitationEnValidation extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationEnValidation();
}

/// La personne a refuse l'invitation : rien ne change pour son compte.
final class InvitationRefuseeParVous extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationRefuseeParVous({this.enregistreeLe});

  /// La date du choix, rendue par le serveur (recu date, charte 09 section
  /// 3, EA-BR-20). `null` : aucune date n'est montree, aucune n'est inventee.
  final DateTime? enregistreeLe;
}

/// Le compte ne peut pas rejoindre ce forfait : inéligible, ou deja membre ou
/// titulaire d'un autre foyer. Une seule forme neutre, sans motif (F4, doc
/// section 11).
final class InvitationNonAcceptable extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationNonAcceptable();
}

/// L'invitation a expire, ou le titulaire l'a annulee : elle ne rattache plus
/// personne (doc section 5.2, reponse tardive).
final class InvitationPerimee extends EtatInvitationRecue {
  /// Cree l'etat.
  const InvitationPerimee();
}

/// La reponse du serveur a une acceptation ou a un refus.
sealed class ResultatReponseInvitation {
  const ResultatReponseInvitation();
}

/// Le serveur a repondu : l'etat de l'invitation apres la reponse.
final class ReponseRecue extends ResultatReponseInvitation {
  /// Cree la reponse.
  const ReponseRecue(this.etat);

  /// L'etat rendu.
  final EtatInvitationRecue etat;
}

/// La connexion a coupe : la reponse n'est pas confirmee (D5) ; la meme cle
/// rend une nouvelle tentative sure.
final class ReponseEchecReseau extends ResultatReponseInvitation {
  /// Cree la reponse.
  const ReponseEchecReseau();
}

/// La reponse du second adulte a l'invitation (EA-BR-20).
abstract interface class PortReponseInvitation {
  /// Accepte l'invitation, avec la cle d'idempotence de cette tentative.
  Future<ResultatReponseInvitation> accepter({required String cle});

  /// Refuse l'invitation, avec la cle d'idempotence de cette tentative.
  Future<ResultatReponseInvitation> refuser({required String cle});
}

/// **Aucune source serveur a ce jour** (EA-BR-20).
class _ReponseIndisponible implements PortReponseInvitation {
  const _ReponseIndisponible();

  @override
  Future<ResultatReponseInvitation> accepter({required String cle}) =>
      Future<ResultatReponseInvitation>.error(
        const CapaciteIndisponible('EA-BR-20'),
      );

  @override
  Future<ResultatReponseInvitation> refuser({required String cle}) =>
      Future<ResultatReponseInvitation>.error(
        const CapaciteIndisponible('EA-BR-20'),
      );
}

/// Le port de la reponse ; la demonstration le surcharge.
final Provider<PortReponseInvitation> portReponseInvitationProvider =
    Provider<PortReponseInvitation>((Ref _) => const _ReponseIndisponible());

/// L'invitation recue par le compte connecte. **Aucune source serveur a ce
/// jour** (EA-BR-20) : `CapaciteIndisponible`.
final FutureProvider<EtatInvitationRecue> invitationRecueProvider =
    FutureProvider<EtatInvitationRecue>(
      (Ref _) => throw const CapaciteIndisponible('EA-BR-20'),
    );

/// La reponse en cours ou manquee.
enum _Reponse { accepter, refuser }

/// L'invitation recue, cote second adulte : le texte T1, puis « Refuser
/// l'invitation » au bord de debut et « Accepter l'invitation » au bord de
/// fin, de meme poids ; ensuite, l'etat rendu seul.
class InvitationRecuePage extends ConsumerStatefulWidget {
  /// Cree la page.
  const InvitationRecuePage({
    required this.onRetour,
    required this.onMonEspace,
    this.onRetourApresReponse,
    super.key,
  });

  /// Retour a la page d'ou vient la personne (les notifications).
  final VoidCallback onRetour;

  /// Le retour une fois la reponse rendue, avec l'etat rendu : la page d'ou
  /// vient la personne doit alors lire ce nouvel etat, jamais l'invitation
  /// « a repondre » d'avant. Par defaut, [onRetour].
  final void Function(EtatInvitationRecue etat)? onRetourApresReponse;

  /// « Aller a Mon espace », avec l'etat rendu apres la reponse.
  final void Function(EtatInvitationRecue etat) onMonEspace;

  /// « Accepter l'invitation ».
  static const Key accepterKey = Key('acceptation.accepter');

  /// « Refuser l'invitation ».
  static const Key refuserKey = Key('acceptation.refuser');

  /// « Aller a Mon espace », sous l'etat rendu.
  static const Key monEspaceKey = Key('acceptation.monEspace');

  /// Le texte d'information T1.
  static const Key texteKey = Key('acceptation.texte');

  /// L'etat rendu apres une reponse, qui prend le focus.
  static const Key focusResultatKey = Key('acceptation.focusResultat');

  /// L'echec d'une reponse, qui prend le focus.
  static const Key focusEchecKey = Key('acceptation.focusEchec');

  /// Le recu date du choix, quand le serveur rend la date.
  static const Key recuKey = Key('acceptation.recu');

  @override
  ConsumerState<InvitationRecuePage> createState() =>
      _InvitationRecuePageState();
}

class _InvitationRecuePageState extends ConsumerState<InvitationRecuePage> {
  /// Une cle par reponse : une nouvelle tentative apres une coupure reprend
  /// la meme (doc section 17).
  final String _cleAccepter = const Uuid().v4();
  final String _cleRefuser = const Uuid().v4();

  _Reponse? _enCours;
  _Reponse? _echouee;
  bool _indisponible = false;
  EtatInvitationRecue? _resultat;

  Future<void> _repondre(_Reponse reponse) async {
    // Double envoi : une seule reponse part, l'autre bouton attend aussi.
    if (_enCours != null) return;
    // Hors ligne, rien ne part (revue EA-R m13).
    if (ref.read(horsLigneProvider).value ?? false) return;
    setState(() {
      _enCours = reponse;
      _echouee = null;
    });
    final PortReponseInvitation port = ref.read(portReponseInvitationProvider);
    ResultatReponseInvitation resultat;
    try {
      resultat = await (reponse == _Reponse.accepter
          ? port.accepter(cle: _cleAccepter)
          : port.refuser(cle: _cleRefuser));
    } on CapaciteIndisponible {
      if (!mounted) return;
      setState(() {
        _enCours = null;
        _indisponible = true;
      });
      return;
    } on Object {
      resultat = const ReponseEchecReseau();
    }
    if (!mounted) return;
    setState(() {
      _enCours = null;
      switch (resultat) {
        case ReponseRecue(:final EtatInvitationRecue etat):
          _resultat = etat;
        case ReponseEchecReseau():
          _echouee = reponse;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_resultat) {
      // Repli : si le serveur rendait encore l'invitation « a repondre »
      // apres une reponse, la page de reponse reste, jamais un etat vide.
      case final InvitationARepondre invitation:
        return _pageReponse(context, invitation);
      case final EtatInvitationRecue etat:
        final void Function(EtatInvitationRecue)? apres =
            widget.onRetourApresReponse;
        return _PageEtatInvitation(
          etat: etat,
          apresReponse: true,
          onRetour: apres == null ? widget.onRetour : () => apres(etat),
          onMonEspace: widget.onMonEspace,
        );
      case null:
        break;
    }
    final AsyncValue<EtatInvitationRecue> lecture = ref.watch(
      invitationRecueProvider,
    );
    // « Invitation au forfait famille », titre des etats neutres : libelle
    // provisoire, lexique D4.
    if (lecture.error is CapaciteIndisponible) {
      return PageShell(
        titre: t.adulte.acceptation.titreNeutre,
        onRetour: widget.onRetour,
        child: const EtatSysteme(
          nature: NatureEtat.indisponible,
          dependance: 'EA-BR-20',
        ),
      );
    }
    return switch (lecture.value) {
      final InvitationARepondre invitation => _pageReponse(context, invitation),
      final EtatInvitationRecue etat => _PageEtatInvitation(
        etat: etat,
        onRetour: widget.onRetour,
        onMonEspace: widget.onMonEspace,
      ),
      null => PageShell(
        titre: t.adulte.acceptation.titreNeutre,
        onRetour: widget.onRetour,
        child: BlocAsynchrone<EtatInvitationRecue>(
          valeur: lecture,
          squelette: const Skeleton.texte(lignes: 6),
          onReessayer: () => ref.invalidate(invitationRecueProvider),
          construire: (EtatInvitationRecue _) => const SizedBox.shrink(),
        ),
      ),
    };
  }

  Widget _pageReponse(BuildContext context, InvitationARepondre invitation) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final String p = invitation.prenomTitulaire;
    final bool f = invitation.titulaireFeminin;
    final a = t.adulte.acceptation;
    final bool bloque = horsLigne || _indisponible;
    // L'ecart entre sections du contrat A d'UX_REVIEW_07 : 24 sur telephone,
    // 32 a partir du gabarit tablette.
    final Widget ecartSection = AppGabarit.de(context).estLarge
        ? Ecart.vXxxl
        : Ecart.vXxl;
    // Le texte T1 d'UX_REVIEW_07, section par section (a valider, Q1).
    final List<(String, String)> sections = <(String, String)>[
      (a.faisonsTitre, a.faisons(prenom: p)),
      (
        a.pourquoiTitre,
        f ? a.pourquoiElle(prenom: p) : a.pourquoiLui(prenom: p),
      ),
      (a.verraTitre(prenom: p), f ? a.verraElle : a.verraLui),
      (a.verraPasTitre(prenom: p), a.verraPas),
      (a.vousTitre, a.vous(prenom: p)),
      (a.autresTitre, a.autres),
      (
        a.dureeTitre,
        <String>[
          a.duree(prenom: p),
          if (invitation.dureeConservation case final String d)
            a.conservation(duree: d),
        ].join(' '),
      ),
      (a.partirTitre, a.partir),
      (a.refusTitre, a.refus),
    ];
    final Widget? echec = switch (_echouee) {
      // D5 : l'ecran ne dit que ce qu'il sait, la reponse n'est pas
      // confirmee.
      _Reponse.accepter => EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: a.acceptationEchecTitre,
        phrase: a.echecPhrase,
      ),
      _Reponse.refuser => EtatSysteme(
        nature: NatureEtat.echecServeur,
        titre: a.refusEchecTitre,
        phrase: a.echecPhrase,
      ),
      null => null,
    };
    return PageEtape(
      numero: 1,
      total: 1,
      onRetour: _enCours == null ? widget.onRetour : null,
      child: _Colonne(
        child: Column(
          key: InvitationRecuePage.texteKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _TitreSection(titre: a.titre(prenom: p), principal: true),
            // Remplacement : le texte T2 s'ajoute au T1 (UX_REVIEW_07). C'est
            // l'information la plus importante du remplacement : au moins la
            // taille du corps de T1, en encre forte, lue dans l'ordre de la
            // page (pas d'annonce a l'ouverture).
            if (invitation.validationRequise) ...<Widget>[
              Ecart.vLg,
              Text(
                a.validation,
                style: AppPalette.of(context).inkStrong.applyTo(
                  Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
                ),
              ),
            ],
            for (final (String titre, String texte) in sections) ...<Widget>[
              ecartSection,
              _TitreSection(titre: titre),
              Ecart.vXs,
              _Note(texte: texte, attenuee: true),
            ],
            if (echec != null) ...<Widget>[
              Ecart.vLg,
              _FocusALApparition(
                key: InvitationRecuePage.focusEchecKey,
                child: echec,
              ),
            ],
            if (_indisponible) ...<Widget>[
              Ecart.vLg,
              const EtatSysteme(
                nature: NatureEtat.indisponible,
                dependance: 'EA-BR-20',
              ),
            ],
            // Hors ligne : rien ne part tout seul. Libelle provisoire,
            // lexique D4.
            if (horsLigne) ...<Widget>[Ecart.vLg, _Note(texte: a.horsLigne)],
            Ecart.vLg,
            _BoutonsMemePoids(
              refuser: ActionPrincipale(
                key: InvitationRecuePage.refuserKey,
                libelle: a.refuser,
                niveau: NiveauAction.secondaire,
                onPress: bloque || _enCours == _Reponse.accepter
                    ? null
                    : () => unawaited(_repondre(_Reponse.refuser)),
                enCours: _enCours == _Reponse.refuser,
              ),
              accepter: ActionPrincipale(
                key: InvitationRecuePage.accepterKey,
                libelle: a.accepter,
                niveau: NiveauAction.secondaire,
                onPress: bloque || _enCours == _Reponse.refuser
                    ? null
                    : () => unawaited(_repondre(_Reponse.accepter)),
                enCours: _enCours == _Reponse.accepter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Les deux reponses, meme niveau et meme largeur (charte 09 section 3) :
/// cote a cote quand la place le permet, refus au bord de debut ; l'une sous
/// l'autre sur telephone et a fort grossissement du texte, dans le meme
/// ordre de lecture.
class _BoutonsMemePoids extends StatelessWidget {
  const _BoutonsMemePoids({required this.refuser, required this.accepter});

  final Widget refuser;
  final Widget accepter;

  /// La largeur, a texte normal, sous laquelle les boutons s'empilent.
  static const double _seuil = 440;

  @override
  Widget build(BuildContext context) {
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) =>
          c.maxWidth / echelle >= _seuil
          ? Row(
              children: <Widget>[
                Expanded(child: refuser),
                Ecart.hSm,
                Expanded(child: accepter),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[refuser, Ecart.vSm, accepter],
            ),
    );
  }
}

/// Un titre de la page (en-tete) ou d'une section du texte T1.
class _TitreSection extends StatelessWidget {
  const _TitreSection({required this.titre, this.principal = false});

  final String titre;
  final bool principal;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      child: Text(
        titre,
        style: palette.inkStrong.applyTo(
          (principal ? textes.headlineMedium : textes.titleMedium) ??
              const TextStyle(),
        ),
      ),
    );
  }
}

/// L'etat de l'invitation, seul, sans bouton de reponse : rendu a la lecture
/// ou apres une reponse (UX_REVIEW_07 ligne 10 d). Jamais un succes fabrique
/// (doc section 5.2) : la phrase est celle de l'etat rendu.
class _PageEtatInvitation extends StatelessWidget {
  const _PageEtatInvitation({
    required this.etat,
    required this.onRetour,
    required this.onMonEspace,
    this.apresReponse = false,
  });

  final EtatInvitationRecue etat;
  final bool apresReponse;
  final VoidCallback onRetour;
  final void Function(EtatInvitationRecue etat) onMonEspace;

  @override
  Widget build(BuildContext context) {
    final a = t.adulte.acceptation;
    // « Invitation refusee », le titre des etats neutres et « Cette
    // invitation n'est plus valable » : libelles provisoires, lexique D4. Les
    // autres viennent du doc (sections 10.4 et 11) et d'UX_REVIEW_07 (T1, T2,
    // ligne 10 d).
    final (String titre, String phrase) = switch (etat) {
      InvitationAcceptee(:final String prenomTitulaire) => (
        t.adulte.famille.forfaitFamille,
        a.rejoint(prenom: prenomTitulaire),
      ),
      InvitationEnValidation() => (
        t.adulte.famille.place.validationEnAttente,
        a.validation,
      ),
      InvitationRefuseeParVous() => (a.refuseeTitre, a.refus),
      InvitationNonAcceptable() => (a.titreNeutre, a.impossible),
      InvitationPerimee() => (a.titreNeutre, a.perimee),
      // Impossible : `InvitationRecuePage` rend la page de reponse pour cet
      // etat, a la lecture comme apres une reponse.
      InvitationARepondre() => throw StateError(
        'InvitationARepondre se rend par la page de reponse.',
      ),
    };
    // Le recu date du choix (charte 09 section 3), seulement si le serveur
    // rend la date (EA-BR-20) : aucune date inventee. Libelle provisoire,
    // lexique D4.
    final DateTime? enregistreeLe = switch (etat) {
      InvitationAcceptee(:final DateTime? enregistreeLe) => enregistreeLe,
      InvitationRefuseeParVous(:final DateTime? enregistreeLe) => enregistreeLe,
      _ => null,
    };
    // La grammaire partagee `EcranResultat` (M4), comme la sortie (EA-8) :
    // ton neutre, aucune coche. Le recu date est son encart ; la cle
    // `recuKey` marque le resultat qui le porte (l'encart n'a pas de cle).
    final Widget resultat = KeyedSubtree(
      key: enregistreeLe == null ? null : InvitationRecuePage.recuKey,
      child: Semantics(
        liveRegion: apresReponse,
        child: EcranResultat(
          icone: AppIcons.foyer,
          ton: TonEtat.neutre,
          titre: titre,
          phrase: phrase,
          encart: enregistreeLe == null
              ? null
              : a.recu(date: dateLongue(enregistreeLe)),
          // Libelle provisoire, lexique D4.
          libelleAction: a.monEspace,
          onAction: () => onMonEspace(etat),
          cleAction: InvitationRecuePage.monEspaceKey,
        ),
      ),
    );
    // Le titre est celui de l'ecran resultat : la coquille ne garde que le
    // disque retour, pour qu'il ne soit pas dit deux fois.
    return PageShell(
      onRetour: onRetour,
      child: apresReponse
          ? _FocusALApparition(
              key: InvitationRecuePage.focusResultatKey,
              child: resultat,
            )
          : resultat,
    );
  }
}

/// L'invitation ouverte sans compte (lien du message, T3) : la connexion
/// existante cree le compte, puis l'invitation se reprend (doc section 5.1).
/// Sans session, rien n'est lu : ni le prenom de la personne qui invite, ni
/// l'etat de l'invitation.
class InvitationSansComptePage extends StatelessWidget {
  /// Cree la page.
  const InvitationSansComptePage({required this.onContinuer, super.key});

  /// Ouvre la connexion existante, sans la modifier.
  final VoidCallback onContinuer;

  /// « Me connecter ou creer mon compte ».
  static const Key continuerKey = Key('acceptation.sansCompte');

  @override
  Widget build(BuildContext context) => PageShell(
    // Titre, phrase (adaptee de T3 sans le prenom) et bouton : libelles
    // provisoires, lexique D4.
    titre: t.adulte.acceptation.sansCompteTitre,
    child: _Colonne(
      auBordDeDebut: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Note(texte: t.adulte.acceptation.sansCompte, attenuee: true),
          Ecart.vLg,
          _Actions(
            principale: ActionPrincipale(
              key: continuerKey,
              libelle: t.adulte.acceptation.sansCompteAction,
              onPress: onContinuer,
              fleche: true,
              pleineLargeur: false,
            ),
          ),
        ],
      ),
    ),
  );
}
