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

import '../../core/capacites/capacite_indisponible.dart';
import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/reseau/service_reseau.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/action_principale.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/avatar_nom.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/bouton_icone.dart';
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
  if (ecart.inHours < 1) return m.minutes(nombre: ecart.inMinutes);
  if (ecart.inDays < 1) return m.heures(nombre: ecart.inHours);
  if (ecart.inDays < 7) return m.jours(nombre: ecart.inDays);
  final DateTime local = instant.toLocal();
  return m.date(
    jour: local.day.toString().padLeft(2, '0'),
    mois: local.month.toString().padLeft(2, '0'),
  );
}

/// La ligne de role d'un auteur : sa fonction autorisee et le moment
/// (« Enseignante, Classe An-Nour, Il y a 2 h ») ; le moment seul si le
/// serveur ne donne pas de fonction.
String ligneAuteurCommunaute(String? fonction, String moment) =>
    fonction == null || fonction.isEmpty
    ? moment
    : t.com.communaute.publication.auteur(fonction: fonction, moment: moment);

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

/// Le champ de recherche des publications (`CommunitySearch`).
class ChampRechercheCommunaute extends StatefulWidget {
  /// Cree le champ.
  const ChampRechercheCommunaute({
    required this.valeur,
    required this.onChange,
    super.key,
    this.autofocus = false,
  });

  /// Le texte courant.
  final String valeur;

  /// Chaque changement du texte.
  final ValueChanged<String> onChange;

  /// Vrai pour prendre le focus a l'ouverture (surface de recherche mobile).
  final bool autofocus;

  /// La cle du champ, pour les tests.
  static const ValueKey<String> cle = ValueKey<String>('communaute-recherche');

  @override
  State<ChampRechercheCommunaute> createState() =>
      _ChampRechercheCommunauteState();
}

class _ChampRechercheCommunauteState extends State<ChampRechercheCommunaute> {
  late final TextEditingController _texte = TextEditingController(
    text: widget.valeur,
  );

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = t.com.communaute.recherche;
    return TextField(
      key: ChampRechercheCommunaute.cle,
      controller: _texte,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChange,
      decoration: InputDecoration(
        labelText: r.champ,
        hintText: r.aide,
        prefixIcon: Icon(AppIcons.recherche.repos),
      ),
    );
  }
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
    final c = t.com.communaute;
    final bool recherche = filtre.recherche.trim().isNotEmpty;

    final Widget corps = BlocAsynchrone<List<PublicationCommunaute>>(
      valeur: lues.whenData(
        (List<PublicationCommunaute> liste) =>
            filtrerPublications(liste, filtre.recherche),
      ),
      squelette: const Skeleton.liste(),
      titreEchec: t.com.socle.composants.etats.erreurTitre,
      onReessayer: () =>
          ref.invalidate(publicationsCommunauteProvider(lecture)),
      vide: VueEtatCommunication(
        etat: EtatCommunication.vide,
        titreVide: recherche ? c.rechercheVideTitre : c.videTitre,
        // « Dans cette categorie » seulement quand une categorie est
        // retenue ; sur « Toutes », la Communaute entiere est vide.
        phraseVide: recherche
            ? c.rechercheVide
            : filtre.categorieId == null
            ? c.videToutes
            : c.vide,
      ),
      erreurVersEtat: (Object erreur, VoidCallback? reessayer) =>
          erreur is CapaciteIndisponible
          ? VueEtatCommunication(
              etat: EtatCommunication.indisponible,
              dependance: erreur.dependance,
            )
          : VueEtatCommunication(
              etat: horsLigne
                  ? EtatCommunication.horsLigne
                  : EtatCommunication.erreur,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (avecBandeau) ...<Widget>[const BandeauRegles(), Ecart.vMd],
        if (tete != null) ...<Widget>[tete, Ecart.vLg],
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: corps,
          ),
        ),
        if (entree != null) ...<Widget>[Ecart.vMd, entree, Ecart.vLg],
      ],
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
            style: palette.inkStrong.applyTo(
              textes.titleSmall ?? const TextStyle(),
            ),
          ),
          Ecart.vXs,
          Text(
            p.texte,
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

/// La tete de la surface de recherche sur telephone : le champ et
/// « Fermer la recherche », qui rend le flux tel qu'il etait.
class TeteRechercheCommunaute extends StatelessWidget {
  /// Cree la tete.
  const TeteRechercheCommunaute({
    required this.valeur,
    required this.onChange,
    required this.onFermer,
    super.key,
  });

  /// Le texte courant.
  final String valeur;

  /// Chaque changement du texte.
  final ValueChanged<String> onChange;

  /// Ferme la recherche.
  final VoidCallback onFermer;

  /// La cle du bouton qui ferme la recherche, pour les tests.
  static const ValueKey<String> cleFermer = ValueKey<String>(
    'communaute-fermer-recherche',
  );

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: ChampRechercheCommunaute(
          valeur: valeur,
          onChange: onChange,
          autofocus: true,
        ),
      ),
      Ecart.hSm,
      BoutonIcone(
        key: cleFermer,
        icone: AppIcons.fermer,
        libelle: t.com.communaute.recherche.fermer,
        infobulle: t.com.communaute.recherche.fermer,
        onPress: onFermer,
      ),
    ],
  );
}
