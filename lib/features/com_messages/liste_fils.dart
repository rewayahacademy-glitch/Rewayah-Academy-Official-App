// La liste des fils metier (COM-M01, COM-W01 ; spec section 3, section 14
// « Liste des fils metier », section 18 « Recherche »).
//
// Une seule surface a filets (`GroupeReglages`), jamais une carte par fil
// (K-55) : chaque ligne dit avec qui (identite autorisee), a propos de quoi
// (l'objet du fil) et ce qui attend (badge d'attention, en mots et en icone,
// jamais la couleur seule). Aucun bouton « Nouveau message » : un fil
// s'ouvre depuis son objet (spec section 3.1).
//
// La recherche est un etat de cette liste (`recherche_fils.dart`) : un
// champ en tete sur ordinateur et tablette, une surface plein ecran
// temporaire sur telephone.

import 'package:flutter/material.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/communications/badge_non_lu.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/lien_fleche.dart';
import '../accueil_famille/bloc_seance.dart' show heureDeLAppareil;
import 'entete_fil_contexte.dart';
import 'port_messages_metier.dart';
import 'recherche_fils.dart';

/// Le moment du dernier message, en court : l'heure s'il date du jour de
/// [maintenant], sinon le jour et le mois (« 12 novembre »). Lu a l'heure
/// locale de l'appareil.
String momentCourt(DateTime instant, DateTime maintenant) {
  final DateTime local = instant.toLocal();
  final DateTime ici = maintenant.toLocal();
  final bool memeJour =
      local.year == ici.year &&
      local.month == ici.month &&
      local.day == ici.day;
  if (memeJour) return heureDeLAppareil(local);
  return t.com.messages.ligne.dateCourte(
    numero: local.day,
    mois: t.commun.dates.mois[local.month - 1],
  );
}

/// La liste des fils, avec sa recherche.
class ListeFils extends StatefulWidget {
  /// Cree la liste.
  const ListeFils({
    required this.fils,
    required this.onOuvrir,
    super.key,
    this.filSelectionne,
    this.rechercheEnSurface = false,
    this.horloge = DateTime.now,
  });

  /// Les fils autorises, le plus recent d'abord.
  final List<ResumeFil> fils;

  /// Ouvre le fil d'identifiant donne.
  final ValueChanged<String> onOuvrir;

  /// Le fil ouvert a cote de la liste (maitre-detail), annonce comme
  /// selectionne ; `null` sur telephone, ou aucun fil n'est a cote.
  final String? filSelectionne;

  /// Vrai sur telephone : la recherche s'ouvre en surface plein ecran.
  final bool rechercheEnSurface;

  /// L'heure courante, pour dire « 10:24 » ou « 12 novembre ».
  final DateTime Function() horloge;

  /// La cle du lien qui ouvre la recherche sur telephone, pour les tests.
  static const ValueKey<String> cleOuvrirRecherche = ValueKey<String>(
    'liste-fils-ouvrir-recherche',
  );

  /// La cle de la ligne d'un fil, pour les tests.
  static ValueKey<String> cleLigne(String filId) =>
      ValueKey<String>('liste-fils-$filId');

  @override
  State<ListeFils> createState() => _ListeFilsState();
}

class _ListeFilsState extends State<ListeFils> {
  final TextEditingController _recherche = TextEditingController();
  bool _surfaceOuverte = false;

  @override
  void initState() {
    super.initState();
    _recherche.addListener(_auChangement);
  }

  @override
  void dispose() {
    _recherche
      ..removeListener(_auChangement)
      ..dispose();
    super.dispose();
  }

  void _auChangement() => setState(() {});

  void _fermerSurface() {
    _recherche.clear();
    setState(() => _surfaceOuverte = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = t.com.messages.recherche;
    if (widget.rechercheEnSurface) {
      if (_surfaceOuverte) {
        return SurfaceRechercheFils(
          controleur: _recherche,
          onFermer: _fermerSurface,
          resultats: _resultats(),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          LienFleche(
            key: ListeFils.cleOuvrirRecherche,
            libelle: r.champ,
            icone: AppIcons.recherche,
            fleche: false,
            onPress: () => setState(() => _surfaceOuverte = true),
          ),
          Ecart.vSm,
          Expanded(child: _resultats()),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChampRechercheFils(controleur: _recherche),
        Ecart.vLg,
        Expanded(child: _resultats()),
      ],
    );
  }

  /// La liste, filtree par la recherche. Les resultats d'une recherche sont
  /// annonces (region polie) ; un filtre sans resultat dit quoi essayer.
  Widget _resultats() {
    final r = t.com.messages.recherche;
    final String texte = _recherche.text.trim();
    final List<ResumeFil> vus = filtrerFils(widget.fils, texte);
    if (texte.isNotEmpty && vus.isEmpty) {
      return SingleChildScrollView(
        child: EtatSysteme(
          nature: NatureEtat.aucunResultat,
          titre: r.aucunTitre,
          phrase: r.aucun(texte: texte),
        ),
      );
    }
    final DateTime maintenant = widget.horloge();
    return ListView(
      // La position de lecture survit a l'aller-retour de la recherche.
      key: const PageStorageKey<String>('liste-fils'),
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      children: <Widget>[
        if (texte.isNotEmpty)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                vus.length == 1
                    ? r.resultatUn
                    : r.resultats(nombre: vus.length),
                style: AppPalette.of(context).inkMuted.applyTo(
                  Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
                ),
              ),
            ),
          ),
        GroupeReglages(
          lignes: <LigneRubrique>[
            for (final ResumeFil f in vus) _ligne(f, maintenant),
          ],
        ),
      ],
    );
  }

  LigneRubrique _ligne(ResumeFil f, DateTime maintenant) {
    final l = t.com.messages.ligne;
    final DateTime? dernier = f.dernierMessageLe;
    final String? selection = widget.filSelectionne;
    return LigneRubrique(
      meneur: KeyedSubtree(
        key: ListeFils.cleLigne(f.id),
        child: AvatarTile(
          prenom: f.interlocuteurs.isEmpty
              ? f.objet.libelle
              : f.interlocuteurs.first.nomAffiche,
          diametre: AppAvatar.petit,
        ),
      ),
      libelle: nomsInterlocuteurs(f.interlocuteurs),
      legende: l.legende(
        objet: f.objet.libelle,
        apercu: f.apercu ?? l.sansApercu,
      ),
      valeur: dernier == null ? null : momentCourt(dernier, maintenant),
      marque: f.attention.estVisible
          ? BadgeNonLu(indicateur: f.attention, compact: true)
          : null,
      selectionnee: selection == null ? null : f.id == selection,
      onPress: () => widget.onOuvrir(f.id),
    );
  }
}
