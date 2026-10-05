import 'package:flutter/material.dart';

import '../../core/accessibilite/texte_sans_coupure.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/tc_groupe/group_home_vm.dart';
import '../../core/tc_groupe/group_summary_vm.dart';
import '../../core/tc_groupe/libelles_tc_groupe.dart';
import '../../core/tc_horloge/emplacement_entree.dart';
import '../../core/tc_horloge/session_clock_vm.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pastille_etat_seance.dart';
import '../../core/widgets/skeleton.dart';

/// La Session Card : le bloc dominant de l'Espace Classe (CLV-01, CL-4.3).
///
/// Elle porte tout ce qui concerne le prochain rendez-vous, et **rien d'autre**
/// : la date, les deux horloges quand elles different, la duree, l'avis de
/// changement d'heure, le conseil d'appareil, puis **un seul emplacement
/// d'entree** (R4) calcule par [EmplacementEntree.pour].
///
/// - **aucun compte a rebours negatif** : en prolongation, « Temps prevu
///   ecoule » (R6) ;
/// - **aucune conversion de fuseau ici** : les heures arrivent deja rendues ;
/// - **aucune pastille de decompte en double, aucun bouton grise**.
class CarteSession extends StatefulWidget {
  /// Cree la Session Card.
  const CarteSession({
    required this.espace,
    super.key,
    this.onRejoindre,
    this.onReessayer,
    this.horsLigne = false,
    this.annulee = false,
    this.lectureEchouee = false,
    this.identite,
    this.actionHorsEntree,
    this.tutoiement = false,
  });

  /// Vrai pour l'eleve mineur en Mode Accessibilite (MA4) : « Ton heure »,
  /// « Tu es dans la salle ». Faux partout ailleurs : un adulte, un tuteur ou
  /// un enseignant est vouvoye.
  final bool tutoiement;

  /// L'identite de la Classe posee au-dessus des heures (Accueil du Mode
  /// Accessibilite, MA-3) ; nulle dans l'Espace Classe, qui la porte deja.
  final Widget? identite;

  /// Le seul bouton de la carte quand l'emplacement d'entree n'en est pas
  /// un (ligne d'etat sans « Reessayer ») : jamais a cote de « Rejoindre »
  /// (R4). Accueil du Mode Accessibilite : « Voir ma classe » (MA-3).
  final Widget? actionHorsEntree;

  /// L'Espace Groupe auquel elle appartient.
  final GroupHomeVM espace;

  /// Ce que fait « Rejoindre ». Nul tant qu'Agent Z ne l'a pas branche.
  final VoidCallback? onRejoindre;

  /// Relance la lecture quand l'emplacement propose « Reessayer ».
  final VoidCallback? onReessayer;

  /// Hors ligne : le texte de la spec et « Reessayer » occupent l'emplacement.
  final bool horsLigne;

  /// Seance annulee, selon le serveur.
  final bool annulee;

  /// L'horloge de seance n'a pas pu etre lue.
  final bool lectureEchouee;

  /// Le role de l'emplacement d'entree pour le role de l'Espace Groupe.
  static RoleEntree roleEntree(RoleEspaceGroupe role) => switch (role) {
    RoleEspaceGroupe.enseignant ||
    RoleEspaceGroupe.admin => RoleEntree.enseignant,
    RoleEspaceGroupe.eleve || RoleEspaceGroupe.tuteur => RoleEntree.eleve,
  };

  @override
  State<CarteSession> createState() => _CarteSessionState();
}

class _CarteSessionState extends State<CarteSession> {
  /// Le titre de la carte : il recoit le focus quand le bouton focalise
  /// laisse place a une ligne d'etat (revue UX n° 13, CL-4.7).
  final FocusNode _focusTitre = FocusNode(
    debugLabel: 'titre-carte-seance',
    skipTraversal: true,
  );

  @override
  void dispose() {
    _focusTitre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GroupHomeVM espace = widget.espace;
    final bool annulee = widget.annulee;
    final bool horsLigne = widget.horsLigne;
    final bool lectureEchouee = widget.lectureEchouee;
    final SessionClockVM? horloge = espace.horloge;
    final OccurrenceSeance? occurrence = espace.identite.prochaineSeance;

    if (horloge == null || occurrence == null) {
      return AppCard(
        dominante: true,
        child: EmptyState(
          message: LibellesGroupe.aucuneSeance,
          invitation: LibellesGroupe.aucuneSeanceDetail,
          icone: AppIcons.cours,
          registre: RegistreVide.subi,
        ),
      );
    }

    final EmplacementEntree emplacement = EmplacementEntree.pour(
      role: CarteSession.roleEntree(espace.role),
      horloge: horloge,
      nomClasse: espace.identite.libelle,
      annulee: annulee,
      horsLigne: horsLigne,
      lectureEchouee: lectureEchouee,
      // Le tuteur n'entre pas : sa ligne d'etat ne depend pas de la seance
      // materialisee (revue CL-4.R, m3).
      accesInverifiable:
          espace.role != RoleEspaceGroupe.tuteur &&
          horloge.sessionId == null &&
          occurrence.sessionId == null,
      tutoiement: widget.tutoiement,
    );
    final TextTheme textes = Theme.of(context).textTheme;

    return AppCard(
      dominante: true,
      // Une seance annulee attenue la carte par sa surface, jamais par une
      // opacite (ANNUL-VIS-1).
      surface: emplacement.etat == EtatEntree.annulee
          ? surfaceCarteSeance(AppPalette.of(context), annulee: true)
          : null,
      entete: Focus(
        focusNode: _focusTitre,
        child: Semantics(
          header: true,
          child: Text(
            horloge.horlogeUtilisateur.dateLocaleRendue,
            key: const ValueKey<String>('carte-seance-titre'),
            style: textes.titleMedium ?? const TextStyle(),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.identite != null) ...<Widget>[widget.identite!, Ecart.vLg],
          HeuresSeance(
            libelleContrepartie: _libelleContrepartie(espace),
            horloge: horloge,
            duree: occurrence.duree,
            tutoiement: widget.tutoiement,
            annulee: emplacement.etat == EtatEntree.annulee,
          ),
          // Une seance annulee dit pourquoi. Le serveur ne rend pas encore le
          // motif : la ligne le dit, elle n'en invente pas (BR-1).
          if (emplacement.etat == EtatEntree.annulee) ...<Widget>[
            Ecart.vMd,
            LigneRaisonSeance(raison: t.etat.motifNonCommunique),
          ],
          if (emplacement.avisDst != null) ...<Widget>[
            Ecart.vMd,
            NoticeChangementHeure(texte: emplacement.avisDst!),
          ],
          if (espace.afficheConseilAppareil) ...<Widget>[
            Ecart.vMd,
            const _ConseilAppareil(),
          ],
          // Entrer en avance prouve qu'on etait pret ; cela ne credite aucune
          // minute de presence academique. On le dit plutot que de le laisser
          // deviner.
          if (horloge.phase == PhaseSeance.attenteAvantT0) ...<Widget>[
            Ecart.vMd,
            Text(
              widget.tutoiement
                  ? t.accessibilite.tutoiement.attenteDetail
                  : LibellesGroupe.attenteAvantDebutDetail,
              style: AppPalette.of(context).inkMuted
                  .applyTo(textes.bodySmall ?? const TextStyle()),
            ),
          ],
          // Le bouton se pose 16 sous le contenu qu'il confirme (R20).
          Ecart.vLg,
          EmplacementEntreeVue(
            emplacement: emplacement,
            // Le tuteur ne rejoint pas la classe de son enfant : il l'observe
            // (lot C-obs, routes D8). Son emplacement reste une ligne d'etat.
            sansBouton: espace.role == RoleEspaceGroupe.tuteur,
            onEntrer: widget.onRejoindre,
            onReessayer: widget.onReessayer,
            focusRetour: _focusTitre,
          ),
          if (widget.actionHorsEntree != null &&
              !emplacement.estBouton &&
              !emplacement.reessayer) ...<Widget>[
            Ecart.vLg,
            widget.actionHorsEntree!,
          ],
        ],
      ),
    );
  }
}

/// Les heures de la seance : « Votre heure », la contrepartie quand elle
/// differe, la duree. Partageable avec l'Espace Classe enseignant (CL-4.4).
class HeuresSeance extends StatelessWidget {
  /// Cree le bloc d'heures.
  const HeuresSeance({
    required this.libelleContrepartie,
    required this.horloge,
    required this.duree,
    super.key,
    this.tutoiement = false,
    this.annulee = false,
  });

  /// Vrai quand la seance est annulee : les heures sont barrees (ANNUL-VIS-1).
  final bool annulee;

  /// Vrai pour l'eleve mineur en Mode Accessibilite : « Ton heure ».
  final bool tutoiement;

  /// « Chez Sayyida Amina » ou « Heure du groupe ».
  final String libelleContrepartie;

  /// L'horloge, heures deja rendues.
  final SessionClockVM horloge;

  /// La duree de l'occurrence.
  final Duration duree;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _LigneHorloge(
          libelle: tutoiement
              ? t.accessibilite.tutoiement.tonHeure
              : LibellesGroupe.votreHeure,
          horloge: horloge.horlogeUtilisateur,
          annulee: annulee,
        ),
        if (horloge.horlogeContrepartie != null) ...<Widget>[
          Ecart.vSm,
          _LigneHorloge(
            libelle: libelleContrepartie,
            horloge: horloge.horlogeContrepartie!,
            annulee: annulee,
            // Une seule annonce « Annulee » par carte : la premiere heure.
            annoncer: false,
          ),
        ],
        Ecart.vSm,
        _LigneValeur(
          libelle: LibellesGroupe.dureeLibelle,
          valeur: LibellesGroupe.dureeSeule(duree),
        ),
      ],
    );
  }
}

/// L'avis de changement d'heure, sous les heures et au-dessus de
/// l'emplacement (revue UX n° 15). **Le widget ne calcule rien** : le texte
/// arrive resolu par [EmplacementEntree] depuis la notice du serveur.
class NoticeChangementHeure extends StatelessWidget {
  /// Cree l'avis.
  const NoticeChangementHeure({required this.texte, super.key});

  /// Le texte.
  final String texte;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(AppIcons.horloge.repos, size: AppSpacing.xl),
          Ecart.hSm,
          Expanded(
            child: Text(texte, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// L'emplacement d'entree unique (R4) : une ligne d'etat ou un bouton, au
/// meme endroit, avec la hauteur du bouton (52) reservee dans tous les etats.
///
/// - La ligne d'etat est un texte avec son icone : ni focalisable, ni
///   annoncee comme desactivee. Jamais de bouton grise.
/// - Le bouton est trailing et a sa largeur naturelle des la tablette, en
///   pleine largeur sur mobile.
/// - Seuls les changements d'etat sont annonces
///   ([EmplacementEntree.annonceDepuis]) ; le decompte ne l'est pas.
///
/// Partageable avec l'Espace Classe enseignant (CL-4.4) : le libelle
/// (« Rejoindre » ou « Preparer l'entree ») vient de l'[EmplacementEntree].
class EmplacementEntreeVue extends StatefulWidget {
  /// Cree l'emplacement.
  const EmplacementEntreeVue({
    required this.emplacement,
    super.key,
    this.onEntrer,
    this.onReessayer,
    this.sansBouton = false,
    this.focusRetour,
  });

  /// Recoit le focus quand le bouton focalise disparait (revue UX n° 13) ;
  /// en general le titre de la carte de seance.
  final FocusNode? focusRetour;

  /// Ce qu'il faut montrer.
  final EmplacementEntree emplacement;

  /// « Rejoindre » ou « Preparer l'entree ».
  final VoidCallback? onEntrer;

  /// « Reessayer ».
  final VoidCallback? onReessayer;

  /// Vrai pour un role qui n'entre pas (tuteur) : le bouton devient la ligne.
  final bool sansBouton;

  @override
  State<EmplacementEntreeVue> createState() => _EmplacementEntreeVueState();
}

class _EmplacementEntreeVueState extends State<EmplacementEntreeVue> {
  late String _annonce = widget.emplacement.annonce;
  final FocusNode _focusBouton = FocusNode(
    debugLabel: 'emplacement-entree',
    skipTraversal: true,
  );

  @override
  void dispose() {
    _focusBouton.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EmplacementEntreeVue ancien) {
    super.didUpdateWidget(ancien);
    final String? nouvelle = widget.emplacement.annonceDepuis(
      ancien.emplacement,
    );
    if (nouvelle != null) _annonce = nouvelle;
    // Le bouton focalise laisse place a une ligne d'etat : le focus revient
    // au titre de la carte. Le bouton qui apparait ne le prend jamais.
    final bool avaitBouton = ancien.emplacement.estBouton && !ancien.sansBouton;
    final bool aBouton = widget.emplacement.estBouton && !widget.sansBouton;
    final FocusNode? retour = widget.focusRetour;
    if (avaitBouton && !aBouton && _focusBouton.hasFocus && retour != null) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && retour.context != null) retour.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final EmplacementEntree e = widget.emplacement;
    final bool mobile = AppGabarit.de(context) == Gabarit.mobile;
    final bool bouton = e.estBouton && !widget.sansBouton;
    final String? detail = e.detail;

    final List<Widget> contenu;
    if (bouton) {
      final Widget action = Focus(
        focusNode: _focusBouton,
        child: Semantics(
          label: e.libelleLecteur,
          button: true,
          excludeSemantics: true,
          onTap: widget.onEntrer,
          child: ActionPrincipale(
            libelle: e.libelle,
            onPress: widget.onEntrer,
            pleineLargeur: mobile,
          ),
        ),
      );
      contenu = <Widget>[
        if (detail != null) ...<Widget>[
          _LigneEtat(etat: e.etat, texte: detail),
          Ecart.vLg,
        ],
        if (mobile) action else _EnFin(child: action),
      ];
    } else {
      contenu = <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppPage.hauteurBouton),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: _LigneEtat(
              etat: e.etat,
              texte: widget.sansBouton && detail != null ? detail : e.libelle,
            ),
          ),
        ),
        if (e.reessayer)
          if (mobile)
            ActionPrincipale(
              libelle: t.classe.entree.reessayer,
              niveau: NiveauAction.secondaire,
              onPress: widget.onReessayer,
            )
          else
            _EnFin(
              child: ActionPrincipale(
                libelle: t.classe.entree.reessayer,
                niveau: NiveauAction.secondaire,
                pleineLargeur: false,
                onPress: widget.onReessayer,
              ),
            ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // La region live : le seul texte des changements d'etat.
        Semantics(
          liveRegion: true,
          label: _annonce,
          child: const SizedBox.shrink(),
        ),
        ...contenu,
      ],
    );
  }
}

/// Une ligne d'etat : icone et texte, lus d'un bloc, jamais focalisable.
class _LigneEtat extends StatelessWidget {
  const _LigneEtat({required this.etat, required this.texte});

  final EtatEntree etat;
  final String texte;

  @override
  Widget build(BuildContext context) {
    // « En direct » et « Annulee » : le composant partage d'etat de seance
    // (ON-AIR-1, ANNUL-VIS-1), avec le mot de l'emplacement.
    if (etat == EtatEntree.enDirect) {
      return PastilleEtatSeance(
        etat: EtatPastilleSeance.enDirect,
        libelle: texte,
      );
    }
    if (etat == EtatEntree.annulee) {
      return PastilleEtatSeance(
        etat: EtatPastilleSeance.annulee,
        libelle: texte,
      );
    }
    final TextTheme textes = Theme.of(context).textTheme;
    final AppIcon icone = switch (etat) {
      EtatEntree.aVenir || EtatEntree.attente => AppIcons.horloge,
      EtatEntree.fenetreOuverte ||
      EtatEntree.enDirect ||
      EtatEntree.preparation => AppIcons.cours,
      EtatEntree.terminee => AppIcons.succes,
      EtatEntree.annulee => AppIcons.annuler,
      EtatEntree.aucune => AppIcons.info,
      EtatEntree.indisponible => AppIcons.horsLigne,
    };
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icone.repos, size: AppSpacing.xxl),
          Ecart.hSm,
          Flexible(
            // Aucun mot coupe a 320 px texte x2 (lecon 8, DASH-MA-PROD-b :
            // « une conn / exion » hors ligne sur l'Accueil MA).
            child: TexteSansCoupure(
              texte,
              // Un decompte : chiffres tabulaires (revue phase 0, jetons D4).
              style: AppTypography.tabulaire(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le squelette fidele a la carte de seance : date, heures, emplacement de
/// 52. Un seul noeud lu, les os exclus (revue UX n° 10).
class SqueletteCarteSession extends StatelessWidget {
  /// Cree le squelette.
  const SqueletteCarteSession({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: t.classe.entree.chargementSeance,
      child: const ExcludeSemantics(
        child: AppCard(
          dominante: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Skeleton(hauteur: AppSpacing.xl),
              Ecart.vLg,
              Skeleton.texte(),
              Ecart.vLg,
              Skeleton(hauteur: AppPage.hauteurBouton),
            ],
          ),
        ),
      ),
    );
  }
}

/// Le libelle de la seconde horloge, selon qui regarde.
///
/// L'eleve et le tuteur lisent « Chez Sayyida Amina » ; l'enseignant lit
/// « Heure du groupe ». Le voyage d'un enseignant ne deplace jamais l'horaire
/// institutionnel du groupe.
String _libelleContrepartie(GroupHomeVM espace) => espace.estCoteFamille
    ? LibellesGroupe.chezEnseignant(
        LibellesGroupe.enseignantNomme(espace.identite.enseignant),
      )
    : LibellesGroupe.heureGroupe;

/// Une heure deja rendue, avec sa ville.
class _LigneHorloge extends StatelessWidget {
  const _LigneHorloge({
    required this.libelle,
    required this.horloge,
    this.annulee = false,
    this.annoncer = true,
  });

  final String libelle;
  final HorlogeAffichee horloge;
  final bool annulee;
  final bool annoncer;

  @override
  Widget build(BuildContext context) {
    return _LigneValeur(
      libelle: libelle,
      annulee: annulee,
      annoncer: annoncer,
      valeur: LibellesGroupe.heureEtVille(
        heure: horloge.heureLocaleRendue,
        ville: horloge.libelleVille,
      ),
    );
  }
}

/// Un libelle et sa valeur, lus d'un bloc. En paire qui s'empile : a 320 de
/// large et a 200 % de texte, rien ne deborde (revue UX n° 14).
class _LigneValeur extends StatelessWidget {
  const _LigneValeur({
    required this.libelle,
    required this.valeur,
    this.annulee = false,
    this.annoncer = true,
  });

  final String libelle;
  final String valeur;

  /// Faux pour la seconde heure barree de la carte (une seule annonce).
  final bool annoncer;

  /// Vrai quand la valeur est l'heure d'une seance annulee : barree.
  final bool annulee;

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return MergeSemantics(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: AppSpacing.md,
        children: <Widget>[
          Text(
            libelle,
            style: palette.inkMuted.applyTo(
              textes.bodySmall ?? const TextStyle(),
            ),
          ),
          TexteHeureSeance(
            heure: valeur,
            annulee: annulee,
            annoncer: annoncer,
            // Une heure : chiffres tabulaires (revue phase 0, jetons D4).
            style: AppTypography.tabulaire(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Le conseil d'appareil, discret : une ligne, sans modale ni blocage.
class _ConseilAppareil extends StatelessWidget {
  const _ConseilAppareil();

  @override
  Widget build(BuildContext context) {
    final TextTheme textes = Theme.of(context).textTheme;
    final AppPalette palette = AppPalette.of(context);

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconTheme(
            data: IconThemeData(
              color: palette.inkMuted.applyTo(const TextStyle()).color,
              size: AppSpacing.xl,
            ),
            child: Icon(AppIcons.tabletteOuOrdinateur.repos),
          ),
          Ecart.hSm,
          Expanded(
            child: Text(
              LibellesGroupe.conseilAppareil,
              style: palette.inkMuted.applyTo(
                textes.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pose une action au bord de fin, a sa largeur naturelle.
///
/// Une `Row` et non un `Align` : `ActionPrincipale` est un `Container`
/// aligne, qui s'etire sur toute contrainte bornee ; la `Row` lui donne une
/// largeur libre, donc sa largeur naturelle (rectification 9).
class _EnFin extends StatelessWidget {
  const _EnFin({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `Align` et non `Row` : une rangee donne une largeur sans borne a son
    // enfant, un libelle long (texte agrandi) deborderait de la carte. Ici le
    // bouton garde sa largeur naturelle, borne par celle de la carte (K-54).
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: IntrinsicWidth(child: child),
    );
  }
}
