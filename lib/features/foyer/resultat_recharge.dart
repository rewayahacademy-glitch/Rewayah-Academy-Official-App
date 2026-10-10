// Le resultat d'une recharge (FI-8 : guide Finance V4 §1.6 et §5.4,
// maquette 01, K-59, D5), sur `/tuteur/foyer/recharge/result?commande=`.
//
// L'ecran lit l'etat de la commande par le port (`suivre`) et rend l'un des
// huit etats, tel quel :
//
// - preparation : « Verifiez la repartition avant de payer. », et
//   « Verifier la recharge » qui rouvre la recharge (une seule page, R3-01)
//   avec la meme selection, son recapitulatif et son moyen de paiement ;
// - attente de confirmation : « Paiement en cours de confirmation » et le
//   bandeau « Ne payez pas une seconde fois. » ; aucun bouton « Payer » ;
// - confirme puis allocation en cours : « Paiement confirme », « Mise a jour
//   des soldes... » ;
// - termine, **seul etat de reussite** : montant total, reference, moyen,
//   date, repartition exacte et nouveau solde par profil (maquette 01) ;
// - echec : le motif rendu, la selection gardee, « Reessayer »,
//   « Changer de moyen de paiement » (la recharge, ou se choisit le moyen) et
//   le retour (« Retour aux soldes » dans tous les etats, E-15, R3-06) ;
// - annule, perime : ce qui s'est passe, rien de credite, recommencer avec
//   la meme selection.
//
// **Jamais « paiement confirme » au retour d'un ecran externe** (FI9) : seul
// l'etat rendu par la source fait foi. Une adresse rouverte relit l'etat,
// elle ne rejoue jamais le paiement. Aucune minuterie : l'etat se relit par
// « Actualiser » (geste de la personne), jamais en boucle.
//
// Rien de recree (K-51) : `EcranResultat` (le heros), `BandeauAttention`,
// `LigneAllocation`, `MontantArgent`, `LigneMoyenPaiement` (en lecture),
// `LigneCleValeur`, `CarteLignes`, `EtatSysteme`, `BlocAsynchrone`,
// `Skeleton`, `LienFleche`, `ActionPrincipale`, et les briques privees de
// cette bibliotheque (titre de groupe, note, carte, actions, colonne, focus).
//
// **Aucun chiffre calcule ici** (FI6) : total, parts et nouveaux soldes
// viennent du port.

part of 'invitation_conjoint.dart';

/// L'etat d'une commande, relu a chaque « Actualiser ». Aucune relance
/// automatique : une capacite absente ne revient pas en insistant.
final suiviRechargeProvider = FutureProvider.autoDispose
    .family<SuiviPaiement, String>(
      (Ref ref, String commandeId) =>
          ref.watch(portRechargeFoyerProvider).suivre(commandeId),
      retry: (int retryCount, Object error) => null,
    );

/// Le resultat de la commande [commandeId].
class ResultatRechargePage extends ConsumerWidget {
  /// Cree la page.
  const ResultatRechargePage({
    required this.commandeId,
    required this.onRevenir,
    required this.onReprendre,
    super.key,
  });

  /// La commande suivie (`?commande=`) ; vide : aucune commande a suivre.
  final String commandeId;

  /// Revenir aux paiements du foyer (soldes).
  final VoidCallback onRevenir;

  /// Revenir a la recharge avec la meme selection : les profils et le
  /// montant de chacun, tels que la commande les rend. La recharge est une
  /// seule page : « Reessayer », « Changer de moyen de paiement » et
  /// « Verifier la recharge » y menent tous.
  final ValueChanged<Map<String, Montant>> onReprendre;

  /// Le heros de l'etat [etat].
  static Key etatKey(EtatPaiement etat) => Key('resultat.etat.${etat.name}');

  /// Le bandeau de l'etat (attente, motif d'echec, soldes mis a jour).
  static const Key bandeauKey = Key('resultat.bandeau');

  /// Les details du paiement (reference, date, total).
  static const Key detailsKey = Key('resultat.details');

  /// La repartition par profil.
  static const Key repartitionKey = Key('resultat.repartition');

  /// « Actualiser ».
  static const Key actualiserKey = Key('resultat.actualiser');

  /// « Reessayer » (echec).
  static const Key reessayerKey = Key('resultat.reessayer');

  /// « Changer de moyen de paiement » (echec).
  static const Key changerMoyenKey = Key('resultat.changerMoyen');

  /// « Verifier la recharge » (preparation).
  static const Key verifierKey = Key('resultat.verifier');

  /// « Recommencer la recharge » (annule, perime).
  static const Key recommencerKey = Key('resultat.recommencer');

  /// Le retour aux paiements du foyer.
  static const Key revenirKey = Key('resultat.revenir');

  /// La ligne d'un profil dans la repartition.
  static Key allocationDe(String profil) => Key('resultat.allocation.$profil');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final Widget corps;
    if (commandeId.isEmpty) {
      // Le vide : une adresse sans commande ne montre rien d'invente.
      corps = EtatSysteme(
        nature: NatureEtat.aucunResultat,
        titre: t.adulte.recharge.resultat.videTitre,
        phrase: t.adulte.recharge.resultat.videPhrase,
        libelleAction: t.adulte.recharge.resultat.retourSoldes,
        onAction: onRevenir,
      );
    } else {
      final AsyncValue<SuiviPaiement> lecture = ref.watch(
        suiviRechargeProvider(commandeId),
      );
      void relire() => ref.invalidate(suiviRechargeProvider(commandeId));
      final Object? erreur = lecture.hasError ? lecture.error : null;
      if (erreur is CapaciteIndisponible) {
        corps = EtatSysteme(
          nature: NatureEtat.indisponible,
          titre: t.adulte.recharge.resultat.indisponibleTitre,
          phrase: t.adulte.recharge.resultat.indisponiblePhrase,
          dependance: erreur.dependance,
          libelleAction: t.adulte.recharge.resultat.retourSoldes,
          onAction: onRevenir,
        );
      } else if (erreur != null && horsLigne) {
        corps = EtatSysteme(nature: NatureEtat.horsLigne, onAction: relire);
      } else {
        corps = BlocAsynchrone<SuiviPaiement>(
          valeur: lecture,
          squelette: const Skeleton.liste(),
          onReessayer: relire,
          // D5 : une lecture manquee ne dit jamais que rien n'est paye.
          erreurVersEtat: (Object _, VoidCallback? reessayer) => EtatSysteme(
            nature: NatureEtat.echecServeur,
            titre: t.adulte.recharge.resultat.lectureEchecTitre,
            phrase: t.adulte.recharge.resultat.lectureEchecPhrase,
            onAction: reessayer,
          ),
          construire: (SuiviPaiement suivi) => _ContenuResultat(
            suivi: suivi,
            horsLigne: horsLigne,
            onActualiser: relire,
            onRevenir: onRevenir,
            onReprendre: onReprendre,
          ),
        );
      }
    }
    // Le retour du systeme mene aux paiements du foyer, jamais a la page qui
    // portait « Payer ».
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool fait, Object? _) {
        if (!fait) onRevenir();
      },
      child: PageShell(actionsCoquille: false, child: _Colonne(child: corps)),
    );
  }
}

/// Le rendu d'un etat rendu par la source.
class _ContenuResultat extends ConsumerWidget {
  const _ContenuResultat({
    required this.suivi,
    required this.horsLigne,
    required this.onActualiser,
    required this.onRevenir,
    required this.onReprendre,
  });

  final SuiviPaiement suivi;
  final bool horsLigne;
  final VoidCallback onActualiser;
  final VoidCallback onRevenir;
  final ValueChanged<Map<String, Montant>> onReprendre;

  /// La selection de la commande : chaque profil et SA part.
  Map<String, Montant> get _selection => <String, Montant>{
    for (final AllocationProfil a in suivi.allocations) a.profilId: a.montant,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final r = t.adulte.recharge.resultat;
    final EtatPaiement etat = suivi.etat;
    final ({AppIcon icone, TonEtat ton, String titre, String phrase}) heros =
        switch (etat) {
          EtatPaiement.preparation => (
            icone: AppIcons.horloge,
            ton: TonEtat.accent,
            titre: r.preparationTitre,
            phrase: r.preparationPhrase,
          ),
          EtatPaiement.attenteConfirmation => (
            icone: AppIcons.attente,
            ton: TonEtat.accent,
            titre: r.attenteTitre,
            phrase: r.attentePhrase,
          ),
          EtatPaiement.confirme => (
            icone: AppIcons.attente,
            ton: TonEtat.accent,
            titre: r.confirmeTitre,
            phrase: r.confirmePhrase,
          ),
          EtatPaiement.allocationEnCours => (
            icone: AppIcons.attente,
            ton: TonEtat.accent,
            titre: r.confirmeTitre,
            phrase: r.allocationPhrase,
          ),
          // Le seul etat de reussite (FI9).
          EtatPaiement.termine => (
            icone: AppIcons.succes,
            ton: TonEtat.succes,
            titre: r.confirmeTitre,
            phrase: r.terminePhrase(montant: formaterMontant(suivi.total)),
          ),
          EtatPaiement.echec => (
            icone: AppIcons.avertissement,
            ton: TonEtat.alerte,
            titre: r.echecTitre,
            phrase: r.echecPhrase,
          ),
          EtatPaiement.annule => (
            icone: AppIcons.annuler,
            ton: TonEtat.neutre,
            titre: r.annuleTitre,
            phrase: r.annulePhrase,
          ),
          EtatPaiement.perime => (
            icone: AppIcons.horloge,
            ton: TonEtat.avertissement,
            titre: r.perimeTitre,
            phrase: r.perimePhrase,
          ),
        };
    final bool termine = etat == EtatPaiement.termine;
    final bool enCours = switch (etat) {
      EtatPaiement.preparation ||
      EtatPaiement.attenteConfirmation ||
      EtatPaiement.confirme ||
      EtatPaiement.allocationEnCours => true,
      _ => false,
    };
    Widget titre(String texte) => Semantics(
      header: true,
      child: Text(
        texte,
        style: palette.inkStrong.applyTo(
          textes.titleMedium ?? const TextStyle(),
        ),
      ),
    );
    // « Actualiser » : un lien, seulement tant que l'etat peut changer et que
    // la relecture peut aboutir (jamais un bouton grise, K-56).
    final Widget? actualiser = enCours && !horsLigne
        ? LienFleche(
            key: ResultatRechargePage.actualiserKey,
            libelle: r.actualiser,
            fleche: false,
            icone: AppIcons.reconnexion,
            onPress: onActualiser,
          )
        : null;
    final Widget? bandeau = switch (etat) {
      EtatPaiement.attenteConfirmation => BandeauAttention(
        key: ResultatRechargePage.bandeauKey,
        ton: TonEtat.accent,
        titre: r.attenteBandeauTitre,
        message: r.attenteBandeauPhrase,
        action: actualiser,
      ),
      EtatPaiement.echec => switch (suivi.motif) {
        final String motif => BandeauAttention(
          key: ResultatRechargePage.bandeauKey,
          ton: TonEtat.alerte,
          titre: r.echecMotif,
          message: motif,
        ),
        null => null,
      },
      EtatPaiement.termine => BandeauAttention(
        key: ResultatRechargePage.bandeauKey,
        ton: TonEtat.succes,
        titre: r.soldesTitre,
        message: r.soldesPhrase,
      ),
      _ => null,
    };
    void reprendre() => onReprendre(_selection);
    // Un seul bouton plein par etat (K-56) : son geste, et au plus une
    // action secondaire a filet.
    final ({Key cle, String libelle, VoidCallback geste}) principale =
        switch (etat) {
          EtatPaiement.termine => (
            cle: ResultatRechargePage.revenirKey,
            libelle: r.retourSoldes,
            geste: onRevenir,
          ),
          // La selection n'est jamais perdue (guide §5.4).
          EtatPaiement.echec => (
            cle: ResultatRechargePage.reessayerKey,
            libelle: r.reessayer,
            geste: reprendre,
          ),
          EtatPaiement.annule || EtatPaiement.perime => (
            cle: ResultatRechargePage.recommencerKey,
            libelle: r.recommencer,
            geste: reprendre,
          ),
          // Rien n'est encore paye : la phrase demande de verifier, le
          // geste y mene, la selection gardee (K-59).
          EtatPaiement.preparation => (
            cle: ResultatRechargePage.verifierKey,
            libelle: t.adulte.recharge.verifier,
            geste: reprendre,
          ),
          // En cours : aucun « Payer », seulement le retour (ne pas payer
          // deux fois).
          _ => (
            cle: ResultatRechargePage.revenirKey,
            libelle: t.adulte.recharge.resultat.retourSoldes,
            geste: onRevenir,
          ),
        };
    final ({Key cle, String libelle, VoidCallback geste})? secondaire =
        switch (etat) {
          // La recharge, ou le moyen se choisit, la selection gardee.
          EtatPaiement.echec => (
            cle: ResultatRechargePage.changerMoyenKey,
            libelle: r.changerMoyen,
            geste: reprendre,
          ),
          EtatPaiement.preparation ||
          EtatPaiement.annule ||
          EtatPaiement.perime => (
            cle: ResultatRechargePage.revenirKey,
            libelle: t.adulte.recharge.resultat.retourSoldes,
            geste: onRevenir,
          ),
          _ => null,
        };
    final Widget actions = _Actions(
      secondaire: switch (secondaire) {
        (:final Key cle, :final String libelle, :final VoidCallback geste) =>
          ActionPrincipale(
            key: cle,
            libelle: libelle,
            niveau: NiveauAction.secondaire,
            onPress: geste,
            pleineLargeur: false,
          ),
        null => null,
      },
      principale: ActionPrincipale(
        key: principale.cle,
        libelle: principale.libelle,
        onPress: principale.geste,
        pleineLargeur: false,
      ),
    );
    final RailPaiement? moyen = suivi.moyen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Le heros, lu d'abord a chaque changement d'etat.
        _FocusALApparition(
          key: ResultatRechargePage.etatKey(etat),
          child: Semantics(
            liveRegion: true,
            child: EcranResultat(
              icone: heros.icone,
              ton: heros.ton,
              titre: heros.titre,
              phrase: heros.phrase,
            ),
          ),
        ),
        if (bandeau != null) ...<Widget>[Ecart.vXl, bandeau],
        if (actualiser != null &&
            etat != EtatPaiement.attenteConfirmation) ...<Widget>[
          Ecart.vLg,
          Align(alignment: AlignmentDirectional.centerEnd, child: actualiser),
        ],
        if (horsLigne && enCours) ...<Widget>[
          Ecart.vLg,
          _Note(texte: r.horsLigne),
        ],
        Ecart.vXl,
        // Les details : reference, date, total (maquette 01). Le total est
        // celui que la source arrete, jamais une somme faite ici.
        _Carte(
          key: ResultatRechargePage.detailsKey,
          lignes: <Widget>[
            titre(r.details),
            Ecart.vSm,
            if (suivi.reference case final String reference)
              LigneCleValeur(
                cle: r.reference,
                valeur: reference,
                chiffres: true,
              ),
            if (suivi.date case final DateTime date)
              LigneCleValeur(cle: r.date, valeur: dateLongue(date)),
            Ecart.vSm,
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              children: <Widget>[
                Text(
                  r.total,
                  style: palette.inkStrong.applyTo(
                    textes.titleSmall ?? const TextStyle(),
                  ),
                ),
                MontantArgent(suivi.total, taille: TailleMontant.titre),
              ],
            ),
          ],
        ),
        // Le moyen rendu par la source, en lecture : rien ne se choisit ici.
        if (moyen != null && LigneMoyenPaiement.estMontre(moyen)) ...<Widget>[
          Ecart.vLg,
          titre(r.moyen),
          Ecart.vSm,
          LigneMoyenPaiement(rail: moyen, retenu: true),
        ],
        Ecart.vLg,
        titre(r.repartition),
        Ecart.vSm,
        // On voit toujours a qui va chaque montant (guide §5.3) ; le nouveau
        // solde, seulement quand la source le rend (`termine`).
        KeyedSubtree(
          key: ResultatRechargePage.repartitionKey,
          child: CarteLignes(
            lignes: <Widget>[
              for (final AllocationProfil a in suivi.allocations)
                LigneAllocation(
                  key: ResultatRechargePage.allocationDe(a.profilId),
                  prenom: a.prenom,
                  montant: a.montant,
                  detail: switch ((termine, a.nouveauSolde)) {
                    (true, final Montant solde) => r.nouveauSolde(
                      montant: formaterMontant(solde),
                    ),
                    _ => null,
                  },
                  // Credite, avec son « + », seulement quand la source rend
                  // `termine` (maquette 01, R3-04).
                  credite: termine,
                  avatar: BandeauProfil(
                    avatar: PhotoEleve(
                      prenom: a.prenom,
                      cleAvatar: null,
                      diametre: AppAvatar.moyen,
                    ),
                    diametre: AppAvatar.moyen,
                    accent: accentLu(
                      ref.watch(accentsProfilsProvider),
                      a.profilId,
                    ),
                    // Le bandeau remonte dans la marge de la ligne, le cercle
                    // reste en haut : l'avatar a cote du prenom, rien ne
                    // depasse la ligne (R3-03, FI12-E07).
                    remontee: LigneCleValeur.margeVerticale,
                  ),
                ),
            ],
          ),
        ),
        if (etat == EtatPaiement.echec) ...<Widget>[
          Ecart.vLg,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: LienFleche(
              key: ResultatRechargePage.revenirKey,
              libelle: t.adulte.recharge.resultat.retourSoldes,
              onPress: onRevenir,
            ),
          ),
        ],
        Ecart.vLg,
        actions,
      ],
    );
  }
}
