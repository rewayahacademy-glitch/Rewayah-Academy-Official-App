// Le dock de la salle de seance (I-4) et son bouton unique.
//
// Standard des commandes d'appel (directeur, 24/10/2026, docs/current/
// SALLE-PLAN-2026-10-24.md) : Google Meet sur Android et sur le web
// (Material 3). UNE pilule flottante translucide, une rangee de boutons ronds
// identiques (56 au telephone, 48 ailleurs ; ecart 12, 16 ailleurs), ICONES
// SEULES : le libelle vit dans l'infobulle et la semantique. Ordre fixe :
// micro, camera, tableau, plus, Quitter. Actif : rempli sombre ; coupe :
// rempli du violet de marque, icone barree (directeur, 25/10/2026, jamais
// rouge) ; tableau ouvert : sombre neutre comme toute bascule active ; Quitter : pilule rouge plus
// large, toujours confirmee, seul rouge de la pilule. Remplace dans la salle le mot
// d'etat sous le bouton (ETATS-BTN-1, ETATS-MA-1, MA-CMD-1).

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bouton_icone.dart';
import '../../core/widgets/commande_salle.dart'
    show SurfaceTuilesSalle, TonTuileSalle, TuileCommandeSalle;
import '../../core/widgets/confirm_destructive.dart';
import 'actions_seance.dart';
import 'barre_support.dart' show NomsFocus, nomsFocus;
import 'feuille_micro_bloque.dart';
import 'vue_seance.dart';

/// Le fond d'un [BoutonAppel].
enum FondBoutonAppel {
  /// Surface surelevee : Micro, Camera, Agrandir, Reseau.
  surface,

  /// Disque plein d'alerte : Quitter.
  alerte,

  /// Disque plein de la paire succes : Parler, en guidee (Q1).
  succes,

  /// Disque plein de la paire primaire : Camera, en guidee (Q1).
  primaire,

  /// Surface surelevee, icone a l'encre de succes : Reseau (image CLV-06).
  reseau,
}

/// Quitter la seance, apres confirmation : le dock (Quitter) et l'icone de
/// sortie de l'en-tete guide passent par la meme question.
///
/// Enseignant ([cahier]) : « Quitter et ouvrir le cahier », la suite est le
/// cahier de transmission (S l.861-863). Jamais « Terminer pour tous » ni
/// « Prolonger ». Le rail enseignant passe aussi par cette question.
Future<void> confirmerQuitterSeance(
  BuildContext context,
  VoidCallback quitter, {
  bool cahier = false,
}) async {
  final bool confirme = await ConfirmDestructive.demander(
    context,
    question: t.salle.seance.quitterQuestion,
    consequence: cahier
        ? t.salle.seance.quitterCahierConsequence
        : t.salle.seance.quitterConsequence,
    libelleConfirmer: cahier ? t.salle.seance.quitterCahier : t.salle.quitter,
    // Spec CLV-06, textes exacts : « Rester » et « Quitter et ouvrir le
    // cahier ».
    libelleAnnuler: cahier ? t.salle.seance.rester : null,
  );
  if (confirme) quitter();
}

/// Le diametre des boutons d'appel du standard : 56 au telephone, 48 sur
/// tablette et ordinateur.
double diametreBoutonAppel(BuildContext context) =>
    AppGabarit.de(context) == Gabarit.mobile
    ? AppTouchTarget.standard + AppSpacing.sm
    : AppTouchTarget.standard;

/// Un bouton de la pilule d'appel : rond, icone seule, rempli selon son etat
/// (standard Meet). Le dessin vit dans [BoutonIcone] (forme `appel`, core).
///
/// [bascule] renseigne : c'est une bascule (micro, camera, tableau) ; eteinte,
/// elle passe au violet de marque ([TonAppel.coupe]) ; active, sombre
/// neutre ([TonAppel.actif]), le tableau compris. [libelle] (l'etat, « Micro coupé ») est
/// l'infobulle ; le lecteur d'ecran lit l'acte puis l'etat.
class BoutonAppel extends StatelessWidget {
  const BoutonAppel({
    required this.icone,
    required this.libelle,
    required this.onPress,
    this.libelleSemantique,
    this.fond = FondBoutonAppel.surface,
    this.actif = true,
    this.bascule,
    this.ouvertPrimaire = false,
    this.focusNode,
    this.selectionne,
    this.nom,
    this.retenu,
    this.pastille,
    super.key,
  });

  /// Un nombre en pastille au coin de la tuile nommee (Eleves presents).
  final int? pastille;

  /// Plan de composition du 26/10/2026 (Q1) : sur ordinateur, le nom de la
  /// commande sous son icone ([TuileCommandeSalle], barre sombre) ; `null` : icone seule
  /// (standard du 24/10, telephone).
  final String? nom;

  /// Un outil ou un panneau (Bibliotheque, Pointeur, Ecrire, Eleves) : la
  /// regle des bascules du lot 3 (25/10/2026), comme le tableau : retenu ou
  /// ouvert, sombre neutre ; ferme, violet de marque. Jamais la couleur
  /// primaire seule, qui se confondait avec un micro coupe. `null` : bouton
  /// ordinaire.
  final bool? retenu;

  /// Le noeud de focus du bouton : la salle y rend le focus a la fermeture
  /// d'une feuille ouverte par ce bouton (micro bloque, W2 2.4.3).
  final FocusNode? focusNode;

  /// Le bouton se dit « selectionne » (son panneau est ouvert).
  final bool? selectionne;

  final AppIcon icone;
  final String libelle;
  final String? libelleSemantique;
  final VoidCallback onPress;
  final FondBoutonAppel fond;

  /// Faux : le bouton reste rendu mais ne repond pas (Micro et Camera
  /// pendant la reconnexion, lot CL-7, UX_REVIEW U1). Aucun gris (K-56) :
  /// sa couleur reste celle de son etat.
  final bool actif;

  /// `null` : bouton ordinaire. Sinon l'etat de la bascule (vrai : active).
  final bool? bascule;

  /// Sans effet depuis le lot salle 3 (pilote, 25/10/2026, « active =
  /// neutre ») : le tableau suit la regle des autres bascules, ouvert sombre
  /// neutre, ferme violet de marque (son icone ne change pas d'un etat a
  /// l'autre : la teinte et le libelle portent l'etat). Garde pour l'appelant.
  final bool ouvertPrimaire;

  @override
  Widget build(BuildContext context) {
    final double diametre = diametreBoutonAppel(context);
    final bool quitter = fond == FondBoutonAppel.alerte;
    final TonAppel ton = switch (bascule) {
      _ when quitter => TonAppel.quitter,
      // Un panneau ou un outil n'est jamais « coupe » : retenu, il prend
      // l'aplat lilas de la tuile ; sinon, la tuile au repos.
      _ when retenu != null => TonAppel.actif,
      false => TonAppel.coupe,
      _ => TonAppel.actif,
    };
    final String semantique = libelleSemantique ?? libelle;
    final String lu = bascule != null && semantique != libelle
        ? '$semantique, $libelle'
        : semantique;
    // Ordinateur (plan du 26/10/2026) : la tuile nommee de la barre sombre.
    final String? leNom = nom;
    if (leNom != null) {
      return TuileCommandeSalle(
        icone: icone.repos,
        nom: leNom,
        libelle: lu,
        infobulle: libelle,
        ton: switch (ton) {
          TonAppel.quitter => TonTuileSalle.quitter,
          TonAppel.coupe => TonTuileSalle.coupe,
          _ when retenu ?? false => TonTuileSalle.retenu,
          _ => TonTuileSalle.repos,
        },
        selectionne: selectionne,
        actif: actif,
        focusNode: focusNode,
        pastille: pastille,
        onPress: onPress,
      );
    }
    return BoutonIcone(
      forme: FormeBoutonIcone.appel,
      icone: icone,
      tonAppel: ton,
      diametre: diametre,
      largeur: quitter ? diametre + AppSpacing.lg : null,
      // L'acte puis l'etat pour une bascule (« Fermer le micro, Micro
      // ouvert ») ; l'infobulle dit l'etat.
      libelle: lu,
      infobulle: libelle,
      selectionne: selectionne,
      focusNode: focusNode,
      actif: actif,
      onPress: onPress,
    );
  }
}

/// Le dock : les commandes de [VueSeance.commandesDock], dans l'ordre.
///
/// Desktop : une pilule centree. Telephone et web etroit : un panneau sur
/// toute la largeur, boutons repartis.
class DockSeance extends StatelessWidget {
  const DockSeance({
    required this.vue,
    required this.actions,
    this.microOuvert = true,
    this.cameraAllumee = true,
    this.agrandi = false,
    this.plus,
    this.nommee = false,
    this.commandes,
    this.avant = const <Widget>[],
    this.avantQuitter = const <Widget>[],
    this.rond = false,
    super.key,
  });

  /// Plan de composition du 26/10/2026 (Q1) : sur ordinateur, chaque bouton
  /// porte son nom dessous ([BoutonAppel.nom]).
  final bool nommee;

  /// Fiche 1 (26/10/2026), ligne 4 : la pilule de l'enseignant au telephone,
  /// des disques nommes (Micro, Camera, Eleves, Quitter) sur la pilule
  /// sombre ; une bascule coupee porte son etat pour nom (« Micro coupé »).
  final bool rond;

  bool get _nommee => nommee || rond;

  /// Les commandes de cette pilule, a la place de [VueSeance.commandesDock]
  /// (ordinateur : deux groupes) ; toujours filtrees par la vue.
  final List<CommandeDock>? commandes;

  /// Les boutons poses en tete de la pilule (ordinateur : Bibliotheque,
  /// Pointeur, Ecrire).
  final List<Widget> avant;

  /// Les boutons poses juste avant Quitter (ordinateur : Eleves).
  final List<Widget> avantQuitter;

  /// Le bouton « Plus » ([BoutonPlusAppel]) quand il y a des Commandes a
  /// ouvrir, sinon `null`.
  final Widget? plus;

  final VueSeance vue;
  final ActionsSeance actions;
  final bool microOuvert;
  final bool cameraAllumee;

  /// Le support occupe l'ecran (focus local) : « Reduire » est rendu avant
  /// Quitter, pour en sortir (TB-2).
  final bool agrandi;

  Widget? _bouton(BuildContext context, CommandeDock commande) {
    // Guidee (Q1) : « Parler » et « Camera » en disques pleins.
    final bool colore = vue.dockColore;
    switch (commande) {
      case CommandeDock.micro:
        final VoidCallback? micro = actions.onMicro;
        if (micro == null) return null;
        return _BoutonMicro(
          vue: vue,
          actions: actions,
          microOuvert: microOuvert,
          onMicro: micro,
          nom: _nommee ? t.salle.micro : null,
          nomCoupe: rond ? t.salle.microCoupe : null,
        );
      case CommandeDock.camera:
        final VoidCallback? camera = actions.onCamera;
        if (camera == null) return null;
        return BoutonAppel(
          icone: (cameraAllumee ? AppIcons.camera : AppIcons.cameraCoupee),
          bascule: cameraAllumee,
          // Le mot d'etat sous l'icone (ETATS-BTN-1) ; la reconnexion garde
          // le nom de la commande, qu'elle dit indisponible.
          libelle: cameraAllumee ? t.salle.cameraAllumee : t.salle.cameraCoupee,
          libelleSemantique:
              vue.libelleIndisponible(t.salle.camera) ??
              (cameraAllumee ? t.salle.fermerCamera : t.salle.ouvrirCamera),
          actif: vue.commandesPublicationActives,
          fond: colore ? FondBoutonAppel.primaire : FondBoutonAppel.surface,
          nom: _nommee
              ? (rond && !cameraAllumee ? t.salle.cameraCoupee : t.salle.camera)
              : null,
          onPress: camera,
        );
      case CommandeDock.agrandir:
        final VoidCallback? agrandir = actions.onAgrandir;
        if (agrandir == null) return null;
        // Revue TB-R m1 : le nom du focus, le meme que dans les Commandes et
        // la barre du support ; jamais « Reduire », le mot d'un panneau.
        final NomsFocus noms = nomsFocus(context, agrandi: agrandi);
        return BoutonAppel(
          key: const ValueKey<String>('bouton-agrandir'),
          icone: noms.icone,
          // Bascule a deux etats comme micro et camera (ETATS-BTN-1) : plein
          // quand le support occupe l'ecran, contour seul sinon, mot d'etat.
          bascule: agrandi,
          libelle: noms.etat,
          libelleSemantique: noms.semantique,
          nom: _nommee ? noms.etat : null,
          onPress: agrandir,
        );
      case CommandeDock.reseau:
        final VoidCallback? reseau = actions.onReseau;
        if (reseau == null) return null;
        return BoutonAppel(
          key: const ValueKey<String>('bouton-reseau'),
          icone: AppIcons.reseau,
          libelle: t.salle.seance.reseau,
          fond: FondBoutonAppel.reseau,
          onPress: reseau,
        );
      case CommandeDock.tableau:
        final VoidCallback? tableau = actions.onTableau;
        if (tableau == null) return null;
        final bool ouvert = vue.tableauOuvert;
        // Une bascule comme micro et camera (ETATS-BTN-1) : disque plein
        // quand le tableau est ouvert, mot d'etat dessous.
        return BoutonAppel(
          key: const ValueKey<String>('bouton-tableau'),
          icone: AppIcons.annoter,
          ouvertPrimaire: true,
          bascule: ouvert,
          libelle: ouvert
              ? t.salle.seance.tableauOuvert
              : t.salle.seance.tableauFerme,
          libelleSemantique: ouvert
              ? t.salle.seance.fermerTableau
              : t.salle.seance.ouvrirTableau,
          nom: _nommee ? t.salle.seance.commandes.affichageTableau : null,
          onPress: tableau,
        );
      case CommandeDock.quitter:
        final VoidCallback? quitter = actions.onQuitter;
        if (quitter == null) return null;
        return BoutonAppel(
          icone: AppIcons.raccrocher,
          libelle: t.salle.quitter,
          libelleSemantique: t.salle.seance.sortir,
          fond: FondBoutonAppel.alerte,
          nom: _nommee ? t.salle.quitter : null,
          onPress: () => confirmerQuitterSeance(
            context,
            quitter,
            cahier: vue.quitterOuvreCahier,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final bool telephone = AppGabarit.de(context) == Gabarit.mobile;
    final String? texteCamera = vue.texteCameraInterdite;
    final Widget? statutCamera = texteCamera == null
        ? null
        : StatutCameraInterdite(texte: texteCamera);
    // TB-2 : tant que le focus local est actif ([agrandi]), sa sortie reste
    // dans la pilule, avant Quitter.
    final List<CommandeDock> voulues = <CommandeDock>[
      for (final CommandeDock c in commandes ?? vue.commandesDock)
        if (vue.commandesDock.contains(c)) c,
    ];
    final List<CommandeDock> commandesRendues = <CommandeDock>[
      for (final CommandeDock c in voulues) ...<CommandeDock>[
        if (c == CommandeDock.quitter &&
            agrandi &&
            !voulues.contains(CommandeDock.agrandir))
          CommandeDock.agrandir,
        c,
      ],
    ];
    final List<Widget> boutons = <Widget>[...avant];
    for (final CommandeDock commande in commandesRendues) {
      // Standard : « Plus » est DANS la pilule, juste avant Quitter, et ouvre
      // les Commandes (Bibliotheque, Outils, Eleves).
      if (commande == CommandeDock.quitter) {
        boutons.addAll(avantQuitter);
        if (plus != null) boutons.add(plus!);
      }
      final Widget? bouton = _bouton(context, commande);
      if (bouton != null) boutons.add(bouton);
    }
    if (!commandesRendues.contains(CommandeDock.quitter)) {
      boutons.addAll(avantQuitter);
      if (plus != null) boutons.add(plus!);
    }
    // Ordinateur (plan du 26/10/2026) : les tuiles nommees se posent dans la
    // barre sombre de la salle, sans pilule.
    if (rond) {
      // Fiche 1, ligne 4 : la pilule sombre de l'appel, les disques nommes
      // centres ; texte agrandi, elle passe sur deux rangees.
      return Center(
        heightFactor: 1,
        child: DecoratedBox(
          key: const ValueKey<String>('dock-seance'),
          decoration: palette.piluleSalle.decoration(
            borderRadius: AppRadius.arrondiLg,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: SurfaceTuilesSalle(
              surface: palette.piluleSalle,
              rond: true,
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: boutons,
              ),
            ),
          ),
        ),
      );
    }
    if (nommee) {
      return Wrap(
        key: const ValueKey<String>('dock-seance'),
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: boutons,
      );
    }
    final double ecart = telephone ? AppSpacing.md : AppSpacing.lg;
    final Widget dock = DecoratedBox(
      key: const ValueKey<String>('dock-seance'),
      decoration: palette.piluleSalle.decoration(
        borderRadius: AppRadius.arrondiFull,
      ),
      child: Padding(
        // Au telephone, 4 : les cinq boutons de l'enseignant (4 x 56, Quitter
        // 72, ecarts 12) tiennent en une rangee a 390 avec la marge de 16.
        padding: EdgeInsets.all(telephone ? AppSpacing.xs : AppSpacing.sm),
        // Les boutons gardent leur taille a toute echelle de texte ; si la
        // rangee ne tient plus en largeur, la pilule passe sur deux rangees,
        // toujours sans mot (directeur, 24/10/2026).
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: ecart,
          runSpacing: ecart,
          children: boutons,
        ),
      ),
    );
    final Widget pilule = Center(heightFactor: 1, child: dock);
    if (statutCamera == null) return pilule;
    // Q-S1 : le statut est une ligne de texte d'etat discret au-dessus de la
    // pilule, ecart 8.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[statutCamera, Ecart.vSm, pilule],
    );
  }
}

/// Le bouton « Plus » de la pilule d'appel : il ouvre les Commandes.
class BoutonPlusAppel extends StatelessWidget {
  const BoutonPlusAppel({
    required this.onPress,
    this.ouvert = false,
    this.focusNode,
    this.nom,
    super.key = cle,
  });

  /// Le nom sous le bouton, sur ordinateur ([BoutonAppel.nom]).
  final String? nom;

  /// La cle du bouton.
  static const Key cle = ValueKey<String>('bouton-plus-appel');

  final VoidCallback onPress;

  /// Le panneau des Commandes est ouvert.
  final bool ouvert;

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => BoutonAppel(
    icone: AppIcons.plusCommandes,
    libelle: t.salle.seance.commandes.declencheur,
    libelleSemantique: t.salle.seance.commandes.declencheurSemantique,
    selectionne: ouvert,
    focusNode: focusNode,
    nom: nom,
    retenu: nom == null ? null : ouvert,
    onPress: onPress,
  );
}

/// Le statut « Camera desactivee pour ce profil. » de l'eleve standard
/// (P10.3, [VueSeance.texteCameraInterdite]) : un **texte d'etat discret**
/// (encre `inkMuted`, `bodyMedium`), comme « La seance se poursuit. » de la
/// ligne d'etat. Non interactif (aucun `Pressable`, ni survol ni focus), lu
/// avant le dock. Une phrase de cinq mots : une `StatusPill` (deux mots au
/// plus) passait a la ligne ; le texte reflue librement a 320 et a 200 %.
class StatutCameraInterdite extends StatelessWidget {
  const StatutCameraInterdite({required this.texte, super.key});

  final String texte;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return ConstrainedBox(
      key: const ValueKey<String>('statut-camera-interdite'),
      constraints: const BoxConstraints(maxWidth: AppPage.largeurEtatVide),
      child: Text(
        texte,
        style: palette.inkMuted.applyTo(
          Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// Le bouton Micro du dock. Micro bloque par le systeme
/// ([VueSeance.microBloque], P09) : le geste ouvre la feuille « micro
/// bloque » au lieu de basculer le micro, le bouton reste « coupe » et, a la
/// fermeture, le focus revient ici (UX_REVIEW U5, W2 2.4.3).
class _BoutonMicro extends StatefulWidget {
  const _BoutonMicro({
    required this.vue,
    required this.actions,
    required this.microOuvert,
    required this.onMicro,
    this.nom,
    this.nomCoupe,
  });

  final VueSeance vue;
  final ActionsSeance actions;
  final bool microOuvert;
  final VoidCallback onMicro;
  final String? nom;

  /// Le nom peint quand le micro est coupe (telephone : « Micro coupé ») ;
  /// `null` : [nom].
  final String? nomCoupe;

  @override
  State<_BoutonMicro> createState() => _BoutonMicroState();
}

class _BoutonMicroState extends State<_BoutonMicro> {
  final FocusNode _focus = FocusNode(debugLabel: 'bouton-micro');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _ouvrirFeuille() async {
    await ouvrirFeuilleMicroBloque(
      context,
      vue: widget.vue,
      actions: widget.actions,
    );
    if (mounted) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final VueSeance vue = widget.vue;
    // Guidee (Q1) : « Parler » en disque plein.
    final bool colore = vue.dockColore;
    // Bloque : jamais montre ouvert (P09.6).
    final bool ouvert = widget.microOuvert && !vue.microBloque;
    // Le mot d'etat (ETATS-BTN-1) : « Micro ouvert » / « Micro coupe », en
    // standard comme en guidee ; le nom de la commande (« Micro », « Parler »
    // en guidee) reste dit par l'indisponibilite (reconnexion) et par l'acte
    // lu.
    final String libelle = ouvert ? t.salle.microOuvert : t.salle.microCoupe;
    return BoutonAppel(
      key: const ValueKey<String>('bouton-micro'),
      focusNode: _focus,
      icone: ouvert ? AppIcons.micro : AppIcons.microCoupe,
      bascule: ouvert,
      libelle: libelle,
      libelleSemantique:
          vue.libelleIndisponible(
            colore ? t.salle.seance.parler : t.salle.micro,
          ) ??
          (ouvert ? t.salle.fermerMicro : t.salle.ouvrirMicro),
      actif: vue.commandesPublicationActives,
      fond: colore ? FondBoutonAppel.succes : FondBoutonAppel.surface,
      nom: ouvert ? widget.nom : widget.nomCoupe ?? widget.nom,
      onPress: vue.microBloque ? _ouvrirFeuille : widget.onMicro,
    );
  }
}
