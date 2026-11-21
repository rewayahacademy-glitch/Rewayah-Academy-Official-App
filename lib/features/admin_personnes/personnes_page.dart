// PERSONNES-UNE-PAGE, etape (b) (directeur, 20/11/2026 : « J'aime bien les
// onglets qui les affichent toutes comme dans la nouvelle page "Comptes" [...]
// Ajoute des icones sur les onglets pour etre plus reconnaissable, car il y a
// desormais un risque de faire quelque chose sur la liste des enseignants alors
// qu'on voulait les familles »).
//
// Une seule page « Personnes », la racine de la rubrique : quatre onglets avec
// icone (Eleves, Familles, Enseignants, Direction et equipe), chacun avec son
// nombre. L'onglet et la personne choisie vivent dans l'adresse (`onglet`,
// `element`, `page`) : recharger rend le meme ecran.
//
// Disposition « liste + apercu » (pilote, 21/11/2026, comme la messagerie) : a
// partir de 1024 points de fenetre, la liste a gauche (environ 40 %, colonnes
// reduites : la personne, son etat, UNE colonne utile a l'onglet) et l'apercu a
// droite ; toucher une ligne remplit l'apercu sans quitter la page ; les
// fleches haut et bas passent a la personne voisine. En dessous de 1024, la
// ligne ouvre le dossier (enseignant) ou l'apercu en feuille (les autres),
// comme dans Comptes depuis l'etape (a).
//
// Aucune regle ici : les comptes viennent de `comptesProvider`, les
// enseignants de `pageEnseignantsProvider` (phase, « qui attend » decides par
// le serveur), l'apercu d'un enseignant de `lire_candidature`
// (`ApercuProfilCandidat`). Aucune donnee de contact dans l'apercu. Les
// anciennes pages gardent leur adresse.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/admin/admin_domaine.dart';
import '../../core/admin/service_comptes.dart';
import '../../core/domain/enums.dart';
import '../../core/enseignants/modeles_enseignants.dart';
import '../../core/enseignants/port_enseignants.dart';
import '../../core/i18n/identifiant_insecable.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_gabarit.dart';
import '../../core/theme/app_metriques.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/barre_precedent_suivant.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/data_collection.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/menu_actions.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/pied_de_liste.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../admin_candidatures/libelles_candidatures.dart' show nomAffiche;
import '../admin_comptes/apercu_compte.dart';
import '../admin_comptes/liste_comptes.dart';
import '../admin_enseignants/enseignants_page.dart'
    show libellePhase, motAttend;
import '../com_messages/apercu_profil_candidat.dart'
    show apercuCandidatureProvider;
import '../foyer/photo_eleve.dart';
import 'apercu_candidat.dart';

/// Les onglets de la page, un par population.
enum OngletPersonnes {
  /// Les eleves (un tuteur qui apprend pour lui-meme y est aussi).
  eleves('eleves'),

  /// Les familles : les tuteurs.
  familles('familles'),

  /// Les enseignants, candidats compris.
  enseignants('enseignants'),

  /// La direction et l'equipe.
  equipe('equipe');

  const OngletPersonnes(this.cle);

  /// La valeur ecrite dans l'adresse (`onglet=`).
  final String cle;

  /// L'onglet de l'adresse ; sans valeur lisible, les enseignants (la
  /// population qui attend le plus de decisions aujourd'hui).
  static OngletPersonnes depuis(String? cle) => values.firstWhere(
    (OngletPersonnes o) => o.cle == cle,
    orElse: () => OngletPersonnes.enseignants,
  );

  /// La vue des comptes de cet onglet, ou `null` pour les enseignants.
  VueComptes? get vue => switch (this) {
    OngletPersonnes.eleves => VueComptes.eleves,
    OngletPersonnes.familles => VueComptes.familles,
    OngletPersonnes.equipe => VueComptes.direction,
    OngletPersonnes.enseignants => null,
  };
}

/// La largeur de fenetre a partir de laquelle la liste et l'apercu se posent
/// cote a cote (pilote, 21/11/2026).
const double largeurListeEtApercu = 1024;

/// L'echelle du texte au-dela de laquelle la page reste en une colonne.
const double echelleMaxCoteACote = 1.3;

/// La part de la liste dans la disposition cote a cote.
const double _partListe = 0.4;

/// Une ligne de la page : une personne, quel que soit l'onglet.
@immutable
class LignePersonne {
  const LignePersonne._({
    required this.cle,
    required this.nom,
    required this.prenom,
    required this.profilId,
    required this.colonne,
    this.etat,
    this.ton = TonEtat.neutre,
    this.compte,
    this.enseignant,
  });

  /// Ce qui designe la personne dans l'adresse : son matricule, ou la
  /// reference de son dossier (jamais un nom).
  final String cle;

  /// Le nom affiche.
  final String nom;

  /// Le prenom, pour le cercle.
  final String prenom;

  /// Le profil, pour la photo ; `null` pour un dossier sans compte.
  final String? profilId;

  /// La colonne utile a l'onglet.
  final String colonne;

  /// L'etat qui sort de l'ordinaire, ou `null`.
  final String? etat;

  /// Le ton de la pastille de [etat].
  final TonEtat ton;

  /// Le compte, pour un eleve, une famille, un membre de l'equipe.
  final CompteAdmin? compte;

  /// La ligne du serveur, pour un enseignant.
  final LigneEnseignant? enseignant;
}

/// L'ecran « Personnes ».
class PersonnesPage extends ConsumerWidget {
  /// Cree l'ecran. [requete] : les parametres de l'adresse.
  const PersonnesPage({
    super.key,
    this.requete = const <String, String>{},
    this.ouvrirDossier,
  });

  /// `onglet`, `element`, `page`.
  final Map<String, String> requete;

  /// Ouvre le dossier complet d'un enseignant ; par defaut, le routeur.
  final void Function(String chemin, String identifiant)? ouvrirDossier;

  /// La cle des onglets.
  static const Key cleOnglets = ValueKey<String>('personnes-onglets');

  /// La cle de l'apercu de droite.
  static const Key cleApercu = ValueKey<String>('personnes-apercu');

  /// La cle de la barre precedent / suivant de l'apercu.
  static const Key cleVoisins = ValueKey<String>('personnes-voisins');

  /// La cle du menu des anciennes pages de la rubrique.
  static const Key cleAutresPages = ValueKey<String>('personnes-autres-pages');

  /// La cle du nom de l'onglet ouvert, ecrit en toutes lettres au telephone.
  static const Key cleNomOnglet = ValueKey<String>('personnes-nom-onglet');

  /// L'icone d'un onglet. Quatre dessins sans parente : un livre (l'eleve
  /// apprend), une maison (la famille), la toque (l'enseignant), la mallette
  /// (l'equipe). Jamais deux groupes de personnes cote a cote (directeur,
  /// 20/11/2026 : le risque d'agir sur la mauvaise liste).
  static AppIcon iconeOnglet(OngletPersonnes o) => switch (o) {
    OngletPersonnes.eleves => AppIcons.livreOuvert,
    OngletPersonnes.familles => AppIcons.maison,
    OngletPersonnes.enseignants => AppIcons.pedagogie,
    OngletPersonnes.equipe => AppIcons.studio,
  };

  /// La cle de la liste.
  static const Key cleListe = ValueKey<String>('personnes-liste');

  OngletPersonnes get _onglet => OngletPersonnes.depuis(requete['onglet']);

  int get _page => (int.tryParse(requete['page'] ?? '') ?? 1).clamp(1, 100000);

  void _aller(
    BuildContext context, {
    OngletPersonnes? onglet,
    String? element,
    int? page,
    bool sansHistorique = false,
  }) {
    final OngletPersonnes o = onglet ?? _onglet;
    final int p = onglet == null ? (page ?? _page) : 1;
    final String adresse = Uri(
      path: Routes.adminPersonnes,
      queryParameters: <String, String>{
        'onglet': o.cle,
        if (p > 1) 'page': '$p',
        'element': ?element,
      },
    ).toString();
    final GoRouter routeur = GoRouter.of(context);
    // Choisir une personne ne remplit pas l'historique du navigateur : le
    // retour ramene a ce qu'on faisait avant, pas a chaque ligne regardee.
    if (sansHistorique) {
      Router.neglect(context, () => routeur.go(adresse));
    } else {
      routeur.go(adresse);
    }
  }

  void _ouvrirDossier(BuildContext context, LigneEnseignant l) {
    final String chemin = Routes.adminPersonnesCandidaturePour(
      l.dossier.reference,
    );
    final void Function(String, String)? ouvrir = ouvrirDossier;
    if (ouvrir != null) {
      ouvrir(chemin, l.dossier.id);
    } else {
      unawaited(GoRouter.of(context).push<void>(chemin, extra: l.dossier.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = t.admin.personnesPage;
    final OngletPersonnes onglet = _onglet;
    final AsyncValue<List<CompteAdmin>> comptes = ref.watch(comptesProvider);
    final RequeteEnseignants requeteEns = RequeteEnseignants(page: _page);
    final AsyncValue<PageEnseignants> enseignants = ref.watch(
      pageEnseignantsProvider(requeteEns),
    );
    // Texte agrandi au-dela de 130 % : une seule colonne qui defile en
    // entier (les onglets agrandis ne tiennent plus au-dessus de deux cadres ;
    // garde de reflow AD-11).
    final bool coteACote =
        MediaQuery.sizeOf(context).width >= largeurListeEtApercu &&
        MediaQuery.textScalerOf(context).scale(1) <= echelleMaxCoteACote;

    int? nombre(OngletPersonnes o) => switch (o.vue) {
      null => enseignants.value?.total,
      final VueComptes vue =>
        comptes.value
            ?.where((CompteAdmin c) => VueComptes.de(c).contains(vue))
            .length,
    };
    String court(OngletPersonnes o) => switch (o) {
      OngletPersonnes.eleves => t.admin.comptes.vueEleves,
      OngletPersonnes.familles => t.admin.comptes.vueFamilles,
      OngletPersonnes.enseignants => t.admin.comptes.vueEnseignants,
      OngletPersonnes.equipe => p.ongletEquipeCourt,
    };
    String libelle(OngletPersonnes o) {
      final String nom = o == OngletPersonnes.equipe
          ? p.ongletEquipe
          : court(o);
      final int? n = nombre(o);
      return n == null ? nom : p.ongletAvecNombre(nom: nom, n: n);
    }

    final Widget selecteur = SelecteurSection<OngletPersonnes>(
      key: cleOnglets,
      libelle: p.choix,
      menuAuContenu: true,
      valeur: onglet,
      onChange: (OngletPersonnes o) => _aller(context, onglet: o),
      sections: <Segment<OngletPersonnes>>[
        for (final OngletPersonnes o in OngletPersonnes.values)
          Segment<OngletPersonnes>(
            valeur: o,
            libelle: libelle(o),
            // Au telephone, le mot court sous l'icone (pilote, 21/11/2026).
            libelleCourt: court(o),
            icone: iconeOnglet(o),
          ),
      ],
    );
    // Au telephone, le nom de l'onglet ouvert et son nombre en toutes
    // lettres, sous les onglets : on sait toujours quelle liste on regarde,
    // meme quand les onglets se reduisent a leurs icones.
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget onglets =
        MediaQuery.sizeOf(context).width >= AppGabarit.seuilTablette
        ? selecteur
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              selecteur,
              Ecart.vSm,
              Semantics(
                header: true,
                child: Text(
                  libelle(onglet),
                  key: cleNomOnglet,
                  style: AppPalette.of(context).inkStrong
                      .applyTo(textes.titleMedium ?? const TextStyle()),
                ),
              ),
              Ecart.vSm,
            ],
          );

    // Autant de lignes que la hauteur en tient (comme Comptes) : a 320 x 256
    // (reflow a 400 %), huit lignes deborderaient.
    final Widget squelette = LayoutBuilder(
      builder: (BuildContext contexte, BoxConstraints contraintes) {
        final double pas =
            AppMetriques.of(contexte).cibleTactile + AppSpacing.sm;
        return Skeleton.tableDense(
          lignes: contraintes.hasBoundedHeight
              ? (contraintes.maxHeight / pas).floor().clamp(2, 10)
              : 6,
        );
      },
    );
    final VueComptes? vue = onglet.vue;
    final Widget corps = vue == null
        ? BlocAsynchrone<PageEnseignants>(
            valeur: enseignants,
            squelette: squelette,
            titreEchec: t.admin.listeEnseignants.lectureEchec,
            onReessayer: () =>
                ref.invalidate(pageEnseignantsProvider(requeteEns)),
            construire: (PageEnseignants page) => _contenu(
              context,
              ref,
              onglets: onglets,
              coteACote: coteACote,
              lignes: <LignePersonne>[
                for (final LigneEnseignant l in page.lignes) _deEnseignant(l),
              ],
              vide: t.admin.comptes.videEnseignants,
              relire: () => ref.invalidate(pageEnseignantsProvider(requeteEns)),
              decalage: (page.page - 1) * page.taillePage,
              total: page.total,
              pied: page.total > page.lignes.length
                  ? PiedDeListe(
                      debut: (page.page - 1) * page.taillePage + 1,
                      fin:
                          (page.page - 1) * page.taillePage +
                          page.lignes.length,
                      total: page.total,
                      onPrecedent: page.page > 1
                          ? () => _aller(context, page: page.page - 1)
                          : null,
                      onSuivant: page.page * page.taillePage < page.total
                          ? () => _aller(context, page: page.page + 1)
                          : null,
                    )
                  : null,
            ),
          )
        : BlocAsynchrone<List<CompteAdmin>>(
            valeur: comptes,
            squelette: squelette,
            titreEchec: t.admin.comptes.erreur,
            onReessayer: () => ref.invalidate(comptesProvider),
            construire: (List<CompteAdmin> tous) => _contenu(
              context,
              ref,
              onglets: onglets,
              coteACote: coteACote,
              lignes: <LignePersonne>[
                for (final CompteAdmin c in tous)
                  if (VueComptes.de(c).contains(vue)) _deCompte(c, vue),
              ],
              relire: () => ref.invalidate(comptesProvider),
              vide: switch (vue) {
                VueComptes.eleves => t.admin.comptes.videEleves,
                VueComptes.familles => t.admin.comptes.videFamilles,
                VueComptes.enseignants => t.admin.comptes.videEnseignants,
                VueComptes.direction => t.admin.comptes.videDirection,
              },
            ),
          );

    return PageShell(
      titre: t.nav.admin.personnes,
      listeBureau: true,
      // Les anciennes pages restent atteignables d'ici, au telephone aussi
      // (son tiroir ne montre pas les sous-liens), jusqu'a l'etape (e).
      actionsEntete: <Widget>[
        MenuActions(
          key: cleAutresPages,
          libelle: p.autresPages,
          icone: AppIcons.reglages,
          actions: <EntreeAction>[
            for (final SousLien lien in ongletsPersonnes())
              EntreeAction(
                libelle: lien.libelle,
                onChoix: () => GoRouter.of(context).go(lien.chemin),
              ),
          ],
        ),
      ],
      defilante: false,
      child: corps,
    );
  }

  Widget _contenu(
    BuildContext context,
    WidgetRef ref, {
    required Widget onglets,
    required bool coteACote,
    required List<LignePersonne> lignes,
    required String vide,
    required VoidCallback relire,
    Widget? pied,
    int decalage = 0,
    int? total,
  }) {
    final String? element = requete['element'];
    final int rang = lignes.indexWhere((LignePersonne l) => l.cle == element);
    final LignePersonne? choisie = rang < 0 ? null : lignes[rang];

    void toucher(LignePersonne l) {
      if (coteACote) {
        _aller(context, element: l.cle, sansHistorique: true);
        return;
      }
      if (l.enseignant case final LigneEnseignant e) {
        _ouvrirDossier(context, e);
      } else if (l.compte case final CompteAdmin c) {
        unawaited(
          ouvrirApercuCompte(
            context,
            nom: l.nom,
            informations: informationsDuCompte(c, _onglet.vue!),
            gestes: const [],
          ),
        );
      }
    }

    final Widget liste = lignes.isEmpty
        ? EmptyState(
            message: vide,
            registre: RegistreVide.subi,
            icone: AppIcons.rienAAfficher,
          )
        : DataCollection<LignePersonne>(
            key: cleListe,
            lignes: lignes,
            cle: (LignePersonne l) => ValueKey<String>(l.cle),
            // Rendu par tranches (LISTES-2) : des lignes, jamais de grandes
            // cartes ; table quand les colonnes tiennent, lignes denses sinon.
            // La collection porte les onglets (ils defilent avec elle) et son
            // propre defilement.
            tete: coteACote ? const SizedBox.shrink() : onglets,
            densiteTelephone: true,
            lignesCartes: true,
            onSelectionner: toucher,
            estSelectionnee: coteACote
                ? (LignePersonne l) => l.cle == element
                : null,
            piedCollant: pied,
            colonnes: <ColonneDonnees<LignePersonne>>[
              ColonneDonnees<LignePersonne>(
                titre: t.admin.comptes.colonnePersonne,
                role: RoleColonne.identifiante,
                flex: 3,
                texte: (LignePersonne l) => l.nom,
                rendu: DataCollection.enTableau(context)
                    ? (BuildContext _, LignePersonne l) => AvatarNom.enLigne(
                        prenom: l.prenom,
                        avatar: PhotoEleve(
                          prenom: l.prenom,
                          cleAvatar: null,
                          personneId: l.profilId,
                          diametre: AppAvatar.petit,
                        ),
                        nom: l.nom,
                        diametre: AppAvatar.petit,
                        roleWidget: l.etat == null
                            ? null
                            : StatusPill(libelle: l.etat!, ton: l.ton),
                      )
                    : null,
              ),
              if (!DataCollection.enTableau(context))
                ColonneDonnees<LignePersonne>(
                  titre: t.admin.comptes.colonneEtat,
                  texte: (LignePersonne l) => l.etat ?? '',
                  rendu: (BuildContext _, LignePersonne l) => l.etat == null
                      ? const SizedBox.shrink()
                      : StatusPill(libelle: l.etat!, ton: l.ton),
                ),
              ColonneDonnees<LignePersonne>(
                titre: switch (_onglet) {
                  OngletPersonnes.eleves => t.admin.comptes.colonneClasse,
                  OngletPersonnes.familles =>
                    t.admin.comptes.colonneElevesRattaches,
                  OngletPersonnes.enseignants =>
                    t.admin.listeEnseignants.colonnes.attend,
                  OngletPersonnes.equipe => t.admin.comptes.colonneRole,
                },
                flex: 2,
                texte: (LignePersonne l) => l.colonne,
              ),
            ],
          );

    if (!coteACote) {
      // Une liste vide n'a pas de collection : les onglets restent au-dessus.
      return lignes.isEmpty
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[onglets, Ecart.vMd, liste],
              ),
            )
          : liste;
    }

    // Le voisin suivant se lit pendant qu'on regarde celui-ci.
    final LignePersonne? suivante = rang >= 0 && rang + 1 < lignes.length
        ? lignes[rang + 1]
        : null;
    final String? aPrecharger = suivante?.enseignant?.dossier.id;

    void voisin(int pas) {
      if (lignes.isEmpty) return;
      final int cible = (rang < 0 ? 0 : rang + pas).clamp(0, lignes.length - 1);
      if (cible != rang) {
        _aller(context, element: lignes[cible].cle, sansHistorique: true);
      }
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => voisin(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => voisin(-1),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Les onglets sur toute la largeur : les quatre restent visibles.
            onglets,
            Ecart.vMd,
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext _, BoxConstraints c) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: c.maxWidth * _partListe,
                      child: lignes.isEmpty
                          ? SingleChildScrollView(child: liste)
                          : liste,
                    ),
                    Ecart.hLg,
                    Expanded(
                      child: SingleChildScrollView(
                        key: cleApercu,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (choisie != null) ...<Widget>[
                              // Precedent / suivant, sans revenir a la liste.
                              BarrePrecedentSuivant(
                                key: cleVoisins,
                                position: t.recrutement.suivant.position(
                                  rang: decalage + rang + 1,
                                  total: total ?? lignes.length,
                                ),
                                libellePrecedent:
                                    t.admin.personnesPage.precedente,
                                libelleSuivant: t.admin.personnesPage.suivante,
                                onPrecedent: rang > 0 ? () => voisin(-1) : null,
                                onSuivant: rang + 1 < lignes.length
                                    ? () => voisin(1)
                                    : null,
                              ),
                              Ecart.vMd,
                            ],
                            _apercu(context, choisie, relire),
                          ],
                        ),
                      ),
                    ),
                    if (aPrecharger != null)
                      Consumer(
                        builder: (BuildContext _, WidgetRef r, Widget? _) {
                          r.watch(apercuCandidatureProvider(aPrecharger));
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _apercu(BuildContext context, LignePersonne? l, VoidCallback relire) {
    final p = t.admin.personnesPage;
    if (l == null) {
      return EmptyState(
        message: p.apercuVide,
        registre: RegistreVide.subi,
        icone: AppIcons.profil,
      );
    }
    if (l.enseignant case final LigneEnseignant e) {
      return AppCard(
        // Une cle par dossier : l'apercu du voisin ne garde rien du precedent.
        key: ValueKey<String>('apercu-${e.dossier.id}'),
        child: ApercuCandidatPersonnes(
          ligne: e.dossier,
          onOuvrirDossier: () => _ouvrirDossier(context, e),
          onChange: relire,
        ),
      );
    }
    final CompteAdmin c = l.compte!;
    final TextTheme textes = Theme.of(context).textTheme;
    return AppCard(
      key: ValueKey<String>('apercu-${l.cle}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AvatarNom.enLigne(
            prenom: l.prenom,
            avatar: PhotoEleve(
              prenom: l.prenom,
              cleAvatar: null,
              personneId: l.profilId,
              diametre: AppAvatar.moyen,
            ),
            nom: l.nom,
            diametre: AppAvatar.moyen,
            roleWidget: l.etat == null
                ? null
                : StatusPill(libelle: l.etat!, ton: l.ton),
          ),
          Ecart.vLg,
          for (final InformationCompte i in informationsDuCompte(
            c,
            _onglet.vue!,
          ))
            if (i.valeur.trim().isNotEmpty)
              LigneCleValeur(cle: i.titre, valeur: i.valeur),
          if (c.admissionATraiter) ...<Widget>[
            Ecart.vMd,
            Text(
              p.demandeATraiter,
              style: AppPalette.of(context).inkMuted
                  .applyTo(textes.bodyMedium ?? const TextStyle()),
            ),
          ],
        ],
      ),
    );
  }
}

LignePersonne _deEnseignant(LigneEnseignant l) => LignePersonne._(
  cle: l.dossier.reference,
  nom: nomAffiche(l.dossier),
  prenom: nomAffiche(l.dossier),
  profilId: null,
  colonne: motAttend(l) ?? '',
  etat: libellePhase(l.phase),
  ton: switch (l.phase) {
    PhaseEnseignant.enPoste || PhaseEnseignant.disponible => TonEtat.succes,
    PhaseEnseignant.accueil => TonEtat.accent,
    _ => TonEtat.neutre,
  },
  enseignant: l,
);

LignePersonne _deCompte(CompteAdmin c, VueComptes vue) {
  final EtatAffiche e = EtatAffiche.de(c);
  return LignePersonne._(
    cle: c.identifiant.isEmpty ? c.profilId : c.identifiant,
    nom: c.libelle == c.identifiant
        ? identifiantInsecable(c.identifiant)
        : c.libelle,
    prenom: c.prenom ?? '',
    profilId: c.profilId,
    colonne: switch (vue) {
      VueComptes.eleves => nomClasseEleve(c) ?? t.admin.comptes.classeAucune,
      VueComptes.familles => '${c.enfantsDuFoyer}',
      VueComptes.direction || VueComptes.enseignants => nomDuRole(c.role),
    },
    etat: e == EtatAffiche.actif ? null : libelleEtatAffiche(e),
    ton: switch (e) {
      EtatAffiche.attente => TonEtat.avertissement,
      EtatAffiche.suspendu => TonEtat.alerte,
      _ => TonEtat.neutre,
    },
    compte: c,
  );
}

/// Le mot d'un etat de compte.
String libelleEtatAffiche(EtatAffiche e) => switch (e) {
  EtatAffiche.attente => t.admin.comptes.etatEnAttente,
  EtatAffiche.sansDecision => t.admin.comptes.etatSansDecision,
  EtatAffiche.actif => t.admin.comptes.etatActif,
  EtatAffiche.provisoire => t.admin.comptes.etatProvisoire,
  EtatAffiche.suspendu => t.admin.comptes.etatSuspendu,
  EtatAffiche.inconnu => t.admin.comptes.etatInconnu,
};

/// Le nom d'un role, pour la direction.
String nomDuRole(AppRole? role) => switch (role) {
  null => t.admin.comptes.roleInconnu,
  AppRole.admin => t.admin.comptes.roleAdmin,
  AppRole.accountant => t.admin.comptes.roleComptable,
  AppRole.controller => t.admin.comptes.roleControleur,
  AppRole.teacher => t.admin.comptes.roleEnseignant,
  AppRole.guardian => t.admin.comptes.roleTuteur,
  AppRole.student => t.admin.comptes.roleEleve,
  AppRole.associe => t.admin.comptes.roleAssocie,
};

/// Ce que l'apercu d'un compte dit, par onglet : bref, sans donnee de contact.
List<InformationCompte> informationsDuCompte(CompteAdmin c, VueComptes vue) {
  final k = t.admin.comptes;
  final int jours = c.joursDAttente(DateTime.now());
  return <InformationCompte>[
    (titre: k.colonneIdentifiant, valeur: identifiantInsecable(c.identifiant)),
    if (vue == VueComptes.eleves) ...<InformationCompte>[
      (
        titre: k.colonneTranche,
        valeur: switch (c.tranche) {
          TrancheAge.enfant => k.trancheEnfant,
          TrancheAge.adulte => k.trancheAdulte,
          null => k.trancheInconnue,
        },
      ),
      (titre: k.colonneClasse, valeur: nomClasseEleve(c) ?? k.classeAucune),
      (titre: k.colonneTuteur, valeur: c.tuteurLibelle ?? k.tuteurAucun),
    ],
    if (vue == VueComptes.familles)
      (titre: k.colonneElevesRattaches, valeur: '${c.enfantsDuFoyer}'),
    if (vue == VueComptes.direction)
      (titre: k.colonneRole, valeur: nomDuRole(c.role)),
    (titre: k.colonneEtat, valeur: libelleEtatAffiche(EtatAffiche.de(c))),
    (
      titre: k.colonneAttente,
      valeur: switch (jours) {
        0 => k.attendAujourdhui,
        1 => k.attendUnJour,
        _ => k.attendJours(jours: jours),
      },
    ),
  ];
}
