// Le flux de la Communaute enseignants (COM-M02, COM-W02 colonne « Flux » ;
// spec section 4, section 18 `CommunitySearch`, section 25).
//
// Une carte par publication : l'auteur (nom et fonction autorises, jamais un
// profil), le moment, le titre, un extrait, la categorie et le nombre de
// reponses. Pas de coeur, pas de « J'aime », pas de score : la spec refuse
// toute mesure de popularite (section 32 ; UX_REVIEW L0, point 11). La carte
// entiere ouvre la publication ; elle ne porte aucun autre bouton
// (« Enregistrer » et « Signaler » vivent dans la publication ouverte).
//
// Les categories passent par `SelecteurSection` (ONGLETS-1, jamais une rangee
// qui defile) ; la recherche est un etat du flux, jamais un ecran de plus.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibilite/sens_du_contenu.dart';
import '../../core/accessibilite/texte_agrandi.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/controle_segmente.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/pile_cartes.dart';
import '../../core/widgets/selecteur_section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/vue_etat_communication.dart';
import 'port_communaute.dart';
import 'regles_communaute.dart';

/// Le moment d'une publication ou d'une reponse, en mots : « A l'instant »,
/// « Il y a 12 min », « Il y a 2 h », « Il y a 3 j », puis la date.
String momentCommunaute(DateTime instant, DateTime maintenant) {
  final m = t.com.communaute.moment;
  final Duration ecart = maintenant.difference(instant);
  if (ecart.inMinutes < 1) return m.instant;
  if (ecart.inHours < 1) return m.minutes(n: ecart.inMinutes);
  if (ecart.inDays < 1) return m.heures(n: ecart.inHours);
  if (ecart.inDays < 7) return m.jours(n: ecart.inDays);
  final DateTime local = instant.toLocal();
  return m.date(
    jour: local.day.toString().padLeft(2, '0'),
    mois: local.month.toString().padLeft(2, '0'),
  );
}

/// La ligne de role d'un auteur : sa fonction autorisee et le moment
/// separes par « · » (« Enseignante, Classe An-Nour · Il y a 2 h », jamais
/// une majuscule au milieu d'une phrase, revue COM-R, R-14) ; le moment seul si le
/// serveur ne donne pas de fonction.
///
/// Lot K, point 6 (COM-CAPT tour 4, n. 3) : le moment ne se coupe jamais
/// (« Il y a » puis « 2 h » seul a la ligne, a 390) ; ses espaces sont
/// insecables, et l'espace avant « · » aussi : la ligne passe a la ligne
/// apres le separateur, le moment entier au debut de la suivante.
String ligneAuteurCommunaute(String? fonction, String moment) {
  final String insecable = moment.replaceAll(' ', _espaceInsecable);
  if (fonction == null || fonction.isEmpty) return insecable;
  final String ligne = t.com.communaute.publication.auteur(
    fonction: fonction,
    moment: insecable,
  );
  // Le DERNIER separateur, celui qui precede le moment : la fonction donnee
  // par le serveur peut porter son propre « · » (« Enseignante · Classe
  // An-Nour »), qui reste secable.
  final int separateur = ligne.lastIndexOf(' $_separateur ');
  if (separateur < 0) return ligne;
  return ligne.replaceRange(separateur, separateur + 1, _espaceInsecable);
}

const String _espaceInsecable = '\u00A0';
const String _separateur = '\u00B7';

/// Le nombre de reponses, en mots.
String libelleReponses(int nombre) {
  final f = t.com.communaute.flux;
  if (nombre == 0) return f.aucuneReponse;
  if (nombre == 1) return f.reponseUne;
  return f.reponses(nombre: nombre);
}

/// Le selecteur des categories : « Toutes », puis celles du port.
///
/// La valeur `null` est « Toutes ». Rendu seulement si le port a donne au
/// moins une categorie (deux sections au moins, `SelecteurSection`).
class SelecteurCategories extends ConsumerWidget {
  /// Cree le selecteur.
  const SelecteurCategories({
    required this.valeur,
    required this.onChange,
    super.key,
  });

  /// La categorie retenue ; `null` pour toutes.
  final String? valeur;

  /// Le choix d'une categorie.
  final ValueChanged<String?> onChange;

  /// La cle du selecteur, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('communaute-categories');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<CategorieCommunaute> categories =
        ref.watch(categoriesCommunauteProvider).value ??
        const <CategorieCommunaute>[];
    if (categories.isEmpty) return const SizedBox.shrink();
    final c = t.com.communaute;
    return SelecteurSection<String?>(
      key: cle,
      libelle: c.sections,
      valeur: valeur,
      onChange: onChange,
      sections: <Segment<String?>>[
        Segment<String?>(valeur: null, libelle: c.toutes),
        for (final CategorieCommunaute categorie in categories)
          Segment<String?>(valeur: categorie.id, libelle: categorie.libelle),
      ],
    );
  }
}

/// Les cles de la recherche des publications (`CommunitySearch`), pour les
/// tests. Le champ et la surface sont ceux du core (`ChampRecherche`,
/// `SurfaceRecherche`, revue COM-R, R-07), avec « Effacer la recherche »
/// comme partout.
abstract final class ClesRechercheCommunaute {
  /// Le champ de saisie.
  static const ValueKey<String> champ = ValueKey<String>(
    'communaute-recherche',
  );

  /// Le bouton qui efface.
  static const ValueKey<String> effacer = ValueKey<String>(
    'communaute-recherche-effacer',
  );

  /// La surface plein ecran du telephone.
  static const ValueKey<String> surface = ValueKey<String>(
    'communaute-recherche-surface',
  );

  /// Le bouton qui ferme la surface.
  static const ValueKey<String> fermer = ValueKey<String>(
    'communaute-fermer-recherche',
  );
}

/// Le flux : les publications du filtre, ou leur etat.
///
/// [compacte] : une seule colonne (telephone) ; le flux porte alors le
/// bandeau des regles, les categories et l'entree de la recherche, que
/// l'ecran pose au-dessus des colonnes ailleurs. [entreeComposer] est
/// l'entree unique « Nouvelle publication », posee en bas du flux.
class FluxPublications extends ConsumerWidget {
  /// Cree le flux.
  const FluxPublications({
    required this.filtre,
    required this.selection,
    required this.onOuvrir,
    super.key,
    this.compacte = false,
    this.avecBandeau = false,
    this.enTete,
    this.entreeComposer,
    this.videAuCentre = false,
  });

  /// La categorie et la recherche.
  final FiltreFlux filtre;

  /// La publication ouverte, marquee dans le flux.
  final String? selection;

  /// Ouvre une publication.
  final ValueChanged<String> onOuvrir;

  /// Vrai sur une seule colonne.
  final bool compacte;

  /// Vrai pour poser le bandeau « Partage pedagogique uniquement ».
  final bool avecBandeau;

  /// Ce qui se pose en tete du flux (categories, recherche), deja compose.
  final Widget? enTete;

  /// L'entree « Nouvelle publication », ou `null` sans capacite.
  final Widget? entreeComposer;

  /// Vrai quand la colonne centrale dit le vide (bureau, COM-RC tour 4,
  /// N-5) : le flux ne le repete pas, un seul etat vide a l'ecran.
  final bool videAuCentre;

  /// L'etat vide du flux pour [filtre] : le meme texte dans le flux
  /// (telephone) et au centre (bureau).
  static Widget vueVide(FiltreFlux filtre) {
    final c = t.com.communaute;
    final bool recherche = filtre.recherche.trim().isNotEmpty;
    return VueEtatCommunication(
      etat: EtatCommunication.vide,
      titreVide: recherche ? c.rechercheVideTitre : c.videTitre,
      // « Dans cette categorie » seulement quand une categorie est
      // retenue ; sur « Toutes », la Communaute entiere est vide.
      phraseVide: recherche
          ? c.rechercheVide
          : filtre.categorieId == null
          ? c.videToutes
          : c.vide,
    );
  }

  /// La cle de la zone qui defile, pour les tests.
  static const ValueKey<String> cleDefilement = ValueKey<String>(
    'communaute-flux-defilement',
  );

  /// La cle de la carte d'une publication, pour les tests.
  static ValueKey<String> cleCarte(String id) =>
      ValueKey<String>('communaute-carte-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La lecture ne depend que de la categorie : la recherche filtre la
    // liste deja lue, sans appel au port ni retour au squelette a chaque
    // frappe (revue COM-COMU-1). Quand COM-BR-05 donnera une recherche
    // serveur, la frappe sera temporisee avant d'interroger le port.
    final FiltreFlux lecture = (categorieId: filtre.categorieId, recherche: '');
    final AsyncValue<List<PublicationCommunaute>> lues = ref.watch(
      publicationsCommunauteProvider(lecture),
    );
    final bool horsLigne = ref.watch(horsLigneProvider).value ?? false;
    final DateTime maintenant = ref.watch(horlogeCommunauteProvider)();

    final Widget corps = BlocAsynchrone<List<PublicationCommunaute>>(
      valeur: lues.whenData(
        (List<PublicationCommunaute> liste) =>
            filtrerPublications(liste, filtre.recherche),
      ),
      squelette: const Skeleton.liste(),
      titreEchec: t.com.socle.composants.etats.erreurTitre,
      onReessayer: () =>
          ref.invalidate(publicationsCommunauteProvider(lecture)),
      vide: videAuCentre ? const SizedBox.shrink() : vueVide(filtre),
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
          VueEtatCommunication.depuisErreur(
            erreur,
            horsLigne: horsLigne,
            onReessayer: reessayer,
          ),
      construire: (List<PublicationCommunaute> publications) => PileCartes(
        children: <Widget>[
          for (final PublicationCommunaute p in publications)
            _CartePublication(
              key: cleCarte(p.id),
              publication: p,
              maintenant: maintenant,
              ouverte: p.id == selection,
              onOuvrir: () => onOuvrir(p.id),
            ),
        ],
      ),
    );

    final Widget? tete = enTete;
    final Widget? entree = lues.hasValue ? entreeComposer : null;
    // COM-RC tour 2 : le bandeau des regles, les categories et l'entree de
    // la recherche defilent avec les cartes (a 320 x 640, texte x2, fixes,
    // ils debordaient de 37). L'entree « Nouvelle publication » reste au
    // bas du flux, sauf quand la place manque (texte agrandi, vue basse) :
    // elle defile alors elle aussi, apres la derniere carte.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        final bool serre =
            SeuilsTexteAgrandi.texteAgrandi(context) ||
            contraintes.maxHeight < SeuilsTexteAgrandi.hauteurBasse;
        final bool entreeFixe = entree != null && !serre;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                key: cleDefilement,
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (avecBandeau) ...<Widget>[
                      const BandeauRegles(),
                      Ecart.vMd,
                    ],
                    if (tete != null) ...<Widget>[tete, Ecart.vLg],
                    corps,
                    if (entree != null && !entreeFixe) ...<Widget>[
                      Ecart.vLg,
                      entree,
                    ],
                  ],
                ),
              ),
            ),
            if (entreeFixe) ...<Widget>[Ecart.vMd, entree, Ecart.vLg],
          ],
        );
      },
    );
  }
}

/// La carte d'une publication : toute la carte ouvre la publication (K-58).
class _CartePublication extends StatelessWidget {
  const _CartePublication({
    required this.publication,
    required this.maintenant,
    required this.ouverte,
    required this.onOuvrir,
    super.key,
  });

  final PublicationCommunaute publication;
  final DateTime maintenant;
  final bool ouverte;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final PublicationCommunaute p = publication;
    final String moment = momentCommunaute(p.publieeLe, maintenant);
    return AppCard(
      onPress: onOuvrir,
      selectionnee: ouverte,
      libelleSemantique: t.com.communaute.flux.ouvrir(titre: p.titre),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AvatarNom.enLigne(
            prenom: p.auteur.nomAffiche,
            role: ligneAuteurCommunaute(p.auteur.fonction, moment),
            diametre: AppAvatar.petit,
          ),
          Ecart.vMd,
          Text(
            p.titre,
            // Le contenu garde le sens de sa langue (COM-RC tour 3).
            textDirection: sensDuContenu(context, p.titre),
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            p.texte,
            textDirection: sensDuContenu(context, p.texte),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Semantics(
                label: t.com.communaute.flux.categorie(
                  categorie: p.categorie.libelle,
                ),
                child: ExcludeSemantics(
                  child: StatusPill(
                    libelle: p.categorie.libelle,
                    ton: TonEtat.neutre,
                  ),
                ),
              ),
              Text(
                libelleReponses(p.nombreReponses),
                style: palette.inkMuted.applyTo(
                  textes.bodySmall ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// L'entree unique « Nouvelle publication » (`PostComposerEntry`). Rendue par
/// l'ecran seulement si la personne a la capacite de publier.
class EntreeNouvellePublication extends StatelessWidget {
  /// Cree l'entree.
  const EntreeNouvellePublication({
    required this.onOuvrir,
    super.key,
    this.pleineLargeur = true,
  });

  /// Ouvre le composer.
  final VoidCallback onOuvrir;

  /// Faux sur ordinateur : le bouton garde la largeur de son libelle.
  final bool pleineLargeur;

  /// La cle de l'entree, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>(
    'communaute-nouvelle-publication',
  );

  @override
  Widget build(BuildContext context) {
    final Widget bouton = ActionPrincipale(
      key: cle,
      libelle: t.com.communaute.composer.nouvelle,
      pleineLargeur: pleineLargeur,
      onPress: onOuvrir,
    );
    return pleineLargeur
        ? bouton
        : Align(alignment: AlignmentDirectional.centerEnd, child: bouton);
  }
}

/// L'entree de la recherche sur telephone : une ligne qui ouvre la surface de
/// recherche, temporaire et plein cadre (spec section 18).
class EntreeRechercheCommunaute extends StatelessWidget {
  /// Cree l'entree.
  const EntreeRechercheCommunaute({required this.onOuvrir, super.key});

  /// Ouvre la surface de recherche.
  final VoidCallback onOuvrir;

  /// La cle de l'entree, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>(
    'communaute-ouvrir-recherche',
  );

  @override
  Widget build(BuildContext context) => LienFleche(
    key: cle,
    libelle: t.com.communaute.recherche.ouvrir,
    icone: AppIcons.recherche,
    fleche: false,
    onPress: onOuvrir,
  );
}
