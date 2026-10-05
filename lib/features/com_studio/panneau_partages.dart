// Le panneau du canal (`StudioSharedAssetsPanel`, spec section 9.3 ;
// COM-W03, colonne de droite ; Enregistrer, spec section 8.3).
//
// Dans l'ordre de la maquette (la composition fait foi, pas son style) :
//
// - A propos : le canal, sa section, son statut de visibilite en toutes
//   lettres, son nombre de membres, et « Enregistrer » ;
// - Membres : nom et fonction deja rediges, jamais une coordonnee ni une
//   presence en ligne (aucun contrat) ;
// - Elements epingles, Fichiers recents, Liens utiles : rendus seulement
//   s'ils ont quelque chose a montrer (aucune section vide decorative) ;
// - Parametres du canal : seulement si le canal rendu porte la capacite
//   (COM-BR-16, forme b), jamais d'apres un role.
//
// Ce n'est PAS une Bibliotheque pedagogique (spec section 9.3) : pas de
// vignette, pas de catalogue, pas de filtre ; un fichier n'affiche que son
// nom, son type et sa taille, jamais une adresse (spec section 12).
// « Enregistrer » garde une reference vers l'objet (canal, element), jamais
// une copie (spec section 8.3) ; il n'est propose que si le service des
// elements enregistres repond (COM-BR-12), sinon il n'est pas rendu.
//
// Ce qu'on ne reprend pas de la maquette : les tuiles de compteurs colorees
// (« 28 fichiers », « 1 evenement »), « Voir tout », les menus a trois
// points, la presence en ligne et l'etiquette de role des membres
// (UX_REVIEW L0, ecarts 13 et 14).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/carte_piece_jointe.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/local_feedback.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'liste_canaux.dart';
import 'port_studio.dart';
import 'visibilite_canal.dart';

/// Ce que l'ecran sait des elements enregistres de la personne.
@immutable
class EtatEnregistrements {
  /// Le service repond : [objets] sont les references deja enregistrees.
  const EtatEnregistrements.disponibles(this.objets) : disponible = true;

  /// Le service ne repond pas (capacite absente ou echec) : aucune action
  /// « Enregistrer » n'est proposee.
  const EtatEnregistrements.indisponibles()
    : disponible = false,
      objets = const <ObjetLie>{};

  /// Vrai si l'action peut etre proposee.
  final bool disponible;

  /// Les objets deja enregistres.
  final Set<ObjetLie> objets;

  /// Vrai si [objet] est enregistre.
  bool contient(ObjetLie objet) => objets.contains(objet);
}

/// Le texte d'une taille de fichier, ou `null` si elle n'est pas connue.
String? _taille(PieceJointe? piece) => switch (piece?.tailleOctets) {
  final int octets => CartePieceJointe.libelleTaille(octets),
  null => null,
};

/// Le panneau d'un canal (`StudioSharedAssetsPanel`).
///
/// Un contenu a hauteur naturelle : l'espace de travail le fait defiler, en
/// colonne comme en feuille.
class PanneauPartages extends StatelessWidget {
  /// Cree le panneau du canal [canal].
  const PanneauPartages({
    required this.canal,
    required this.partages,
    required this.destinationCanal,
    required this.enregistrements,
    required this.onBasculerEnregistrement,
    required this.onOuvrir,
    super.key,
    this.retour,
    this.onReessayerPartages,
    this.horsLigne = false,
  });

  /// Le canal ouvert.
  final Canal canal;

  /// La lecture de ce que le canal partage.
  final AsyncValue<PartagesCanal> partages;

  /// Le chemin qui ouvre ce canal : la destination de ses references.
  final String destinationCanal;

  /// Ce que l'ecran sait des elements enregistres ; `null` tant que la
  /// lecture n'a pas repondu (aucune action n'est encore proposee).
  final EtatEnregistrements? enregistrements;

  /// Enregistre l'objet, ou le retire s'il l'est deja.
  final ValueChanged<ObjetLie> onBasculerEnregistrement;

  /// Ouvre un chemin interne (un lien utile).
  final ValueChanged<String> onOuvrir;

  /// Le retour de la derniere action « Enregistrer » ; `null` si aucun.
  final String? retour;

  /// Relance la lecture des partages.
  final VoidCallback? onReessayerPartages;

  /// Vrai si l'appareil est hors ligne.
  final bool horsLigne;

  /// La cle du bloc A propos, pour les tests.
  static const ValueKey<String> cleAPropos = ValueKey<String>(
    'studio-panneau-a-propos',
  );

  /// La cle du bloc des membres, pour les tests.
  static const ValueKey<String> cleMembres = ValueKey<String>(
    'studio-panneau-membres',
  );

  /// La cle du bloc des elements epingles, pour les tests.
  static const ValueKey<String> cleEpingles = ValueKey<String>(
    'studio-panneau-epingles',
  );

  /// La cle du bloc des fichiers, pour les tests.
  static const ValueKey<String> cleFichiers = ValueKey<String>(
    'studio-panneau-fichiers',
  );

  /// La cle du bloc des liens, pour les tests.
  static const ValueKey<String> cleLiens = ValueKey<String>(
    'studio-panneau-liens',
  );

  /// La cle du bloc des parametres, pour les tests.
  static const ValueKey<String> cleParametres = ValueKey<String>(
    'studio-panneau-parametres',
  );

  /// La cle de l'action « Enregistrer » d'un objet, pour les tests.
  static ValueKey<String> cleEnregistrer(ObjetLie objet) =>
      ValueKey<String>('studio-enregistrer-${objet.type.name}-${objet.id}');

  @override
  Widget build(BuildContext context) {
    final p = t.com.studio.panneau;
    final ResumeCanal r = canal.resume;
    final ObjetLie objetCanal = r.objet(destinationCanal);
    final String? retour = this.retour;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (retour != null) ...<Widget>[
          LocalFeedback(message: retour),
          Ecart.vLg,
        ],
        GroupeReglages(
          key: cleAPropos,
          titre: p.aPropos,
          lignes: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.discussion,
              libelle: r.nom,
              legende: r.description,
              controle: _enregistrer(objetCanal),
            ),
            LigneRubrique(
              icone: AppIcons.info,
              libelle: p.section,
              valeur: libelleSection(r.section),
            ),
            LigneRubrique(
              icone: AppIcons.oeil,
              libelle: p.visibilite,
              legende: phraseVisibilite(r.visibilite),
              valeur: libelleVisibilite(r.visibilite),
            ),
          ],
        ),
        Ecart.vXl,
        GroupeReglages(
          key: cleMembres,
          titre: libelleMembres(canal.membres.length),
          lignes: <LigneRubrique>[
            for (final Participant m in canal.membres)
              LigneRubrique(
                meneur: AvatarTile(
                  prenom: m.nomAffiche,
                  diametre: AppAvatar.petit,
                ),
                libelle: m.nomAffiche,
                legende: m.estSoi ? p.vous : m.fonction,
              ),
          ],
        ),
        ..._partages(context),
        if (canal.peut(CapaciteCanal.parametres)) ...<Widget>[
          Ecart.vXl,
          GroupeReglages(
            key: cleParametres,
            lignes: <LigneRubrique>[
              LigneRubrique(
                icone: AppIcons.reglages,
                libelle: p.parametres,
                legende: p.parametresDetail,
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _partages(BuildContext context) {
    final p = t.com.studio.panneau;
    if (partages.isLoading) {
      return const <Widget>[
        Ecart.vXl,
        VueEtatCommunication(etat: EtatCommunication.chargement),
      ];
    }
    if (partages.hasError) {
      final Object erreur = partages.error!;
      return <Widget>[
        Ecart.vXl,
        if (erreur is CapaciteIndisponible)
          VueEtatCommunication(
            etat: EtatCommunication.indisponible,
            dependance: erreur.dependance,
          )
        else
          VueEtatCommunication(
            etat: horsLigne
                ? EtatCommunication.horsLigne
                : EtatCommunication.erreur,
            onReessayer: onReessayerPartages,
          ),
      ];
    }
    final PartagesCanal tout = partages.value ?? PartagesCanal.aucun;
    if (tout.estVide) {
      return <Widget>[
        Ecart.vXl,
        GroupeReglages(
          lignes: <LigneRubrique>[
            LigneRubrique(
              icone: AppIcons.rienAAfficher,
              libelle: p.aucunPartageTitre,
              legende: p.aucunPartage,
            ),
          ],
        ),
      ];
    }
    return <Widget>[
      if (tout.epingles.isNotEmpty) ...<Widget>[
        Ecart.vXl,
        GroupeReglages(
          key: cleEpingles,
          titre: p.epingles,
          lignes: <LigneRubrique>[
            for (final ElementPartage e in tout.epingles) _ligneElement(e),
          ],
        ),
      ],
      if (tout.fichiers.isNotEmpty) ...<Widget>[
        Ecart.vXl,
        GroupeReglages(
          key: cleFichiers,
          titre: p.fichiers,
          lignes: <LigneRubrique>[
            for (final ElementPartage e in tout.fichiers) _ligneElement(e),
          ],
        ),
      ],
      if (tout.liens.isNotEmpty) ...<Widget>[
        Ecart.vXl,
        GroupeReglages(
          key: cleLiens,
          titre: p.liens,
          lignes: <LigneRubrique>[
            for (final ElementPartage e in tout.liens) _ligneLien(e),
          ],
        ),
      ],
    ];
  }

  /// Un element epingle ou un fichier : nom, type et taille (jamais une
  /// adresse), la ligne de detail redigee par le serveur, et « Enregistrer ».
  LigneRubrique _ligneElement(ElementPartage e) {
    final PieceJointe? piece = e.piece;
    final List<String> morceaux = <String>[
      ?piece?.typeLisible,
      ?_taille(piece),
      ?e.detail,
    ];
    return LigneRubrique(
      icone: piece == null
          ? AppIcons.texteStructure
          : CartePieceJointe.iconeNature(piece.nature),
      libelle: e.titre,
      legende: morceaux.isEmpty ? null : morceaux.join(' · '),
      controle: _enregistrer(e.objet(destinationCanal)),
    );
  }

  /// Un lien utile : un lien interne s'ouvre a sa place ; un lien externe
  /// est nomme par son site, sans geste (aucun lien n'est suivi sans
  /// contrat).
  LigneRubrique _ligneLien(ElementPartage e) {
    final p = t.com.studio.panneau;
    final String? chemin = e.destination;
    final String? hote = e.hote;
    if (chemin == null) {
      return LigneRubrique(
        icone: AppIcons.flecheAction,
        libelle: e.titre,
        legende: hote == null ? e.detail : p.lienExterne(hote: hote),
      );
    }
    return LigneRubrique(
      icone: AppIcons.flecheAction,
      libelle: e.titre,
      legende: e.detail,
      libelleSemantique: p.ouvrir(titre: e.titre),
      onPress: () => onOuvrir(chemin),
    );
  }

  /// L'action « Enregistrer » (ou « Retirer ») d'un objet, seulement si le
  /// service des elements enregistres repond ; sinon rien n'est rendu.
  Widget? _enregistrer(ObjetLie objet) {
    final EtatEnregistrements? etat = enregistrements;
    if (etat == null || !etat.disponible) return null;
    return BoutonEnregistrer(
      key: cleEnregistrer(objet),
      titre: objet.libelle,
      enregistre: etat.contient(objet),
      onPress: () => onBasculerEnregistrement(objet),
    );
  }
}

/// Le titre du bloc des membres, avec leur nombre.
String libelleMembres(int nombre) {
  final c = t.com.studio.canal;
  return nombre == 1 ? c.membresUn : c.membres(nombre: nombre);
}

/// L'action « Enregistrer » d'un objet : un lien discret (`LienFleche`, sans
/// fleche), dont le lecteur d'ecran entend l'objet (« Enregistrer Planning du trimestre »),
/// et qui devient « Retirer » une fois l'objet enregistre.
class BoutonEnregistrer extends StatelessWidget {
  /// Cree l'action.
  const BoutonEnregistrer({
    required this.titre,
    required this.enregistre,
    required this.onPress,
    super.key,
  });

  /// Le nom de l'objet, pour le lecteur d'ecran.
  final String titre;

  /// Vrai si l'objet est deja enregistre.
  final bool enregistre;

  /// Enregistre ou retire.
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final e = t.com.studio.enregistrer;
    return LienFleche(
      libelle: enregistre ? e.retirer : e.enregistrer,
      libelleSemantique: enregistre
          ? e.semantiqueRetirer(titre: titre)
          : e.semantiqueEnregistrer(titre: titre),
      fleche: false,
      onPress: onPress,
    );
  }
}
