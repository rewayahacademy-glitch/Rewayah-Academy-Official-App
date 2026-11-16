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
import '../../core/tc_horloge/mon_horloge.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/avatar_tile.dart';
import '../../core/widgets/badge_non_lu.dart';
import '../../core/widgets/carte_lignes.dart' show LigneDeCarte;
import '../../core/widgets/champ_recherche.dart';
import '../../core/widgets/etat_systeme.dart';
import '../../core/widgets/filter_pill.dart';
import '../../core/widgets/lien_fleche.dart';
import '../../core/widgets/ligne_conversation.dart';
import '../../core/widgets/rangee_filtres.dart';
import '../../core/widgets/surface_recherche.dart';
import '../accueil_famille/bloc_seance.dart' show heureDeLAppareil;
import 'avatar_participant.dart';
import 'entete_fil_contexte.dart';
import 'port_messages_metier.dart';
import 'recherche_fils.dart';

/// Le moment du dernier message, en court : l'heure s'il date du jour de
/// [maintenant], sinon le jour et le mois (« 12 novembre »). Lu a l'heure
/// du profil ([chezMoi], HEURES-PROFIL H1).
String momentCourt(DateTime instant, DateTime maintenant) {
  final DateTime local = chezMoi(instant);
  final DateTime ici = chezMoi(maintenant);
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
    this.recherche,
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

  /// L'etat de la recherche, tenu par l'appelant pour qu'il survive a un
  /// changement d'adresse ; `null` : la liste tient le sien.
  final RechercheFilsControleur? recherche;

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
  RechercheFilsControleur? _propre;
  late RechercheFilsControleur _etat;

  /// BULLES-MESSAGERIE : le filtre « Non lus ».
  bool _nonLusSeulement = false;

  TextEditingController get _recherche => _etat.texte;

  @override
  void initState() {
    super.initState();
    _etat = widget.recherche ?? (_propre = RechercheFilsControleur());
    _ecouter(_etat);
  }

  @override
  void didUpdateWidget(ListeFils ancien) {
    super.didUpdateWidget(ancien);
    final RechercheFilsControleur nouveau =
        widget.recherche ?? (_propre ??= RechercheFilsControleur());
    if (identical(nouveau, _etat)) return;
    _oublier(_etat);
    _etat = nouveau;
    _ecouter(_etat);
  }

  @override
  void dispose() {
    _oublier(_etat);
    _propre?.dispose();
    super.dispose();
  }

  void _ecouter(RechercheFilsControleur etat) {
    etat.addListener(_auChangement);
    etat.texte.addListener(_auChangement);
  }

  void _oublier(RechercheFilsControleur etat) {
    etat.removeListener(_auChangement);
    etat.texte.removeListener(_auChangement);
  }

  void _auChangement() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final r = t.com.messages.recherche;
    if (widget.rechercheEnSurface) {
      if (_etat.surfaceOuverte) {
        // La surface est temporaire : le retour du systeme (ou celui de la
        // page, qui passe par le meme chemin) la referme et rend la liste,
        // au lieu de quitter les Messages.
        return PopScope<Object?>(
          canPop: false,
          onPopInvokedWithResult: (bool sortie, Object? _) {
            if (!sortie) _etat.fermerSurface();
          },
          child: SurfaceRecherche(
            key: ClesRechercheFils.surface,
            controleur: _recherche,
            libelle: r.champ,
            aide: r.aide,
            cleChamp: ClesRechercheFils.champ,
            cleEffacer: ClesRechercheFils.effacer,
            cleFermer: ClesRechercheFils.fermer,
            onFermer: _etat.fermerSurface,
            resultats: _resultats(),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!_etat.loupeEnTete) ...<Widget>[
            LienFleche(
              key: ListeFils.cleOuvrirRecherche,
              libelle: r.champ,
              icone: AppIcons.recherche,
              fleche: false,
              onPress: _etat.ouvrirSurface,
            ),
            Ecart.vSm,
          ],
          Expanded(child: _resultats()),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ChampRecherche(
          controleur: _recherche,
          libelle: r.champ,
          aide: r.aide,
          cleChamp: ClesRechercheFils.champ,
          cleEffacer: ClesRechercheFils.effacer,
        ),
        Ecart.vLg,
        Expanded(child: _resultats()),
      ],
    );
  }

  /// La liste, filtree par la recherche et par « Non lus ». Les resultats
  /// d'une recherche sont annonces (region polie) ; un filtre sans resultat
  /// dit quoi essayer. Les lignes se construisent au fur et a mesure du
  /// defilement, chacune sous la cle de son fil, en une carte blanche peinte ligne a ligne.
  Widget _resultats() {
    final r = t.com.messages.recherche;
    final String texte = _recherche.text.trim();
    final List<ResumeFil> cherches = filtrerFils(widget.fils, texte);
    final List<ResumeFil> vus = _nonLusSeulement
        ? <ResumeFil>[
            for (final ResumeFil f in cherches)
              if (f.attention.nonLus > 0) f,
          ]
        : cherches;
    final Widget filtres = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: RangeeFiltres(
        filtres: <Widget>[
          FilterPill(
            libelle: t.com.messages.filtres.tous,
            retenue: !_nonLusSeulement,
            onPress: () => setState(() => _nonLusSeulement = false),
          ),
          FilterPill(
            libelle: t.com.messages.filtres.nonLus,
            retenue: _nonLusSeulement,
            onPress: () => setState(() => _nonLusSeulement = true),
          ),
        ],
      ),
    );
    if (vus.isEmpty && (texte.isNotEmpty || _nonLusSeulement)) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            filtres,
            EtatSysteme(
              nature: NatureEtat.aucunResultat,
              titre: r.aucunTitre,
              phrase: texte.isEmpty
                  ? t.com.messages.filtres.aucunNonLu
                  : r.aucun(texte: texte),
            ),
          ],
        ),
      );
    }
    final DateTime maintenant = widget.horloge();
    final int avant = 1 + (texte.isNotEmpty ? 1 : 0);
    // Construite A LA DEMANDE (le directeur a des centaines de conversations) :
    // chaque ligne peint son morceau de la carte blanche (`LigneDeCarte`).
    return ListView.builder(
      // La position de lecture survit a l'aller-retour de la recherche.
      key: const PageStorageKey<String>('liste-fils'),
      // BANDE-SUITE : la fin s'arrete au-dessus de la barre flottante.
      padding: EdgeInsets.only(
        bottom: AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: avant + vus.length,
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) return filtres;
        if (texte.isNotEmpty && i == 1) {
          return Semantics(
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
          );
        }
        final int k = i - avant;
        // MESSAGERIE-COULEURS (directeur, 16/11/2026) : l'aspect d'UNE carte
        // blanche a lignes fines posee sur la page, comme avant BULLES-
        // MESSAGERIE, sans perdre la construction ligne a ligne.
        return LigneDeCarte(
          premiere: k == 0,
          derniere: k == vus.length - 1,
          child: _ligne(vus[k], maintenant),
        );
      },
    );
  }

  /// Une conversation : photo de 48 (ou initiales), nom, apercu, heure et
  /// nombre de non lus (BULLES-MESSAGERIE, `LigneConversation`).
  Widget _ligne(ResumeFil f, DateTime maintenant) {
    final int nonLus = f.attention.nonLus;
    final DateTime? dernier = f.dernierMessageLe;
    final String titre = titreFil(f.interlocuteurs, f.objet.libelle);
    final String apercu = f.apercuPhoto
        ? t.com.messages.images.photoApercu
        : f.apercu ?? t.com.messages.ligne.sansApercu;
    final String? selection = widget.filSelectionne;
    return LigneConversation(
      key: ValueKey<String>('ligne-${f.id}'),
      // PHOTOS-2b et #Ra_staff : l'avatar du premier interlocuteur.
      meneur: KeyedSubtree(
        key: ListeFils.cleLigne(f.id),
        child: AvatarParticipant(
          participant: f.interlocuteurs.isEmpty ? null : f.interlocuteurs.first,
          repli: f.objet.libelle,
          diametre: AppAvatar.moyen,
        ),
      ),
      titre: titre,
      apercu: apercu,
      apercuPhoto: f.apercuPhoto,
      heure: dernier == null ? null : momentCourt(dernier, maintenant),
      nonLus: nonLus,
      libelleNonLus: nonLus > 0 ? BadgeNonLu.libelleNonLus(nonLus) : null,
      // Une attention sans nombre (mention, action requise) garde son badge.
      marque: nonLus == 0 && f.attention.estVisible
          ? BadgeNonLu(indicateur: f.attention, compact: true)
          : null,
      selectionnee: selection == null ? null : f.id == selection,
      onPress: () => widget.onOuvrir(f.id),
    );
  }
}
