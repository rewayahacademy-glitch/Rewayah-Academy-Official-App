// Echanges (CTR-04, CT-6) : la troisieme destination de la coquille
// controleur (C13). La liste des fils, un par mission (C17), puis le fil
// ouvert : contexte de la visite epingle en haut, messages, champ de reponse
// et envoi honnete (composant generique `FilDiscussion`).
//
// Aucun serveur (K-28) : le port par defaut echoue, la demonstration le
// remplace. Titre d'un fil : « {Classe} · {date de la mission} », jamais un
// nom de personne (UX_REVIEW_08 question 7).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.g.dart';
import '../../core/icons/app_icons.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/bloc_asynchrone.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fil_discussion.dart';
import '../../core/widgets/groupe_reglages.dart';
import '../../core/widgets/ligne_cle_valeur.dart';
import '../../core/widgets/page_shell.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/status_pill.dart';
import '../accueil_famille/bloc_seance.dart'
    show dateDeLAppareil, heureDeLAppareil;
import 'echanges_controleur.dart';

/// Le titre humain d'un fil : la Classe et la date de la mission.
String titreFilEchange(FilEchange fil) => t.controleur.echanges.titreFil(
  classe: fil.classe,
  date: dateDeLAppareil(fil.debutMission),
);

/// La page Echanges du controleur : la liste des fils, ou le fil ouvert.
class EchangesControleurPage extends ConsumerStatefulWidget {
  /// Cree la page ; [missionOuverte] ouvre directement le fil de cette
  /// mission (« Ecrire a l'administration », P-CTR-06).
  const EchangesControleurPage({super.key, this.missionOuverte});

  /// La mission dont le fil s'ouvre a l'arrivee, ou nulle pour la liste.
  final String? missionOuverte;

  /// Le contexte de la visite en une phrase (en-tete compact, SUPERPOS-1).
  static const Key contexteCompactKey = ValueKey<String>(
    'echanges-contexte-compact',
  );

  @override
  ConsumerState<EchangesControleurPage> createState() =>
      _EchangesControleurPageState();
}

class _EchangesControleurPageState
    extends ConsumerState<EchangesControleurPage> {
  String? _mission;
  AsyncValue<List<FilEchange>> _liste =
      const AsyncValue<List<FilEchange>>.loading();
  AsyncValue<FilEchange> _fil = const AsyncValue<FilEchange>.loading();

  PortEchanges get _port => ref.read(portEchangesProvider);

  @override
  void initState() {
    super.initState();
    final String? m = widget.missionOuverte;
    if (m != null) {
      _ouvrir(m);
    } else {
      _chargerListe();
    }
  }

  Future<void> _chargerListe() async {
    setState(() => _liste = const AsyncValue<List<FilEchange>>.loading());
    final AsyncValue<List<FilEchange>> v = await AsyncValue.guard(_port.fils);
    if (mounted) setState(() => _liste = v);
  }

  Future<void> _ouvrir(String missionId) async {
    setState(() {
      _mission = missionId;
      _fil = const AsyncValue<FilEchange>.loading();
    });
    final AsyncValue<FilEchange> v = await AsyncValue.guard(
      () => _port.filDeMission(missionId),
    );
    if (mounted && _mission == missionId) setState(() => _fil = v);
  }

  void _fermer() {
    setState(() => _mission = null);
    _chargerListe();
  }

  @override
  Widget build(BuildContext context) {
    final String? mission = _mission;
    return mission == null ? _vueListe() : _vueFil(mission);
  }

  Widget _vueListe() {
    final e = t.controleur.echanges;
    return PageShell(
      titre: e.titre,
      child: _borne(
        BlocAsynchrone<List<FilEchange>>(
          valeur: _liste,
          squelette: const Skeleton.liste(),
          onReessayer: _chargerListe,
          estVide: (List<FilEchange> fils) => fils.isEmpty,
          vide: EmptyState(
            message: e.vide,
            icone: AppIcons.discussion,
            registre: RegistreVide.subi,
          ),
          construire: (List<FilEchange> fils) => GroupeReglages(
            lignes: <LigneRubrique>[
              for (final FilEchange f in fils)
                LigneRubrique(
                  icone: AppIcons.discussion,
                  libelle: titreFilEchange(f),
                  legende: e.derniereActivite(
                    date: dateDeLAppareil(f.derniereActivite),
                  ),
                  marque: _pastille(f.etat),
                  onPress: () => _ouvrir(f.missionId),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vueFil(String mission) {
    final e = t.controleur.echanges;
    final FilEchange? fil = _fil.value;
    return PageShell(
      titre: fil == null ? e.titre : titreFilEchange(fil),
      onRetour: _fermer,
      defilante: false,
      entete: fil == null ? null : _borne(_ContexteEpingle(fil: fil)),
      child: _borne(
        BlocAsynchrone<FilEchange>(
          valeur: _fil,
          squelette: const Skeleton.texte(),
          onReessayer: () => _ouvrir(mission),
          construire: (FilEchange f) => FilDiscussion(
            key: ValueKey<String>('fil-${f.id}'),
            messages: <MessageFil>[
              for (final MessageEchange m in f.messages)
                MessageFil(
                  id: m.id,
                  auteur: switch (m.auteur) {
                    AuteurEchange.controleur => e.auteurVous,
                    AuteurEchange.administration => e.auteurAdmin,
                  },
                  texte: m.texte,
                  // Meme cle que l'Historique (revue CT-R m9).
                  horodatage: t.controleur.historique.dateHeure(
                    date: dateDeLAppareil(m.date),
                    heure: heureDeLAppareil(m.date),
                  ),
                  deSoi: m.auteur == AuteurEchange.controleur,
                ),
            ],
            textes: TextesFilDiscussion(
              aideChamp: e.champ,
              libelleChamp: e.champLibelle,
              envoyer: e.envoyer,
              champVide: e.champVide,
              enCours: e.enCours,
              envoye: e.envoye,
              echec: e.echec,
              reessayer: e.reessayer,
              auteurSoi: e.auteurVous,
              annonce: (String auteur, String texte) =>
                  e.nouveauMessage(auteur: auteur, texte: texte),
            ),
            onEnvoyer: (String texte) => _port.envoyer(f.id, texte),
          ),
        ),
      ),
    );
  }

  /// Largeur de lecture sur ordinateur : un fil ne s'etire pas (K-42).
  static Widget _borne(Widget enfant) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppPage.largeurLecture),
      child: enfant,
    ),
  );

  static Widget _pastille(EtatFilEchange etat) => switch (etat) {
    EtatFilEchange.reponseRecue => StatusPill(
      libelle: t.controleur.echanges.reponseRecue,
      // Couleur neutre (decision du directeur C8 = a, 27/09).
      ton: TonEtat.neutre,
    ),
    EtatFilEchange.enAttente => StatusPill(
      libelle: t.controleur.echanges.enAttente,
      ton: TonEtat.neutre,
    ),
  };
}

/// Le contexte de la visite, joint automatiquement et non modifiable
/// (P-CTR-06, W-337) : Classe, date, heure.
class _ContexteEpingle extends StatelessWidget {
  const _ContexteEpingle({required this.fil});

  final FilEchange fil;

  /// Au-dela de cette echelle de texte, le contexte tient en une phrase.
  static const double echelleCompacte = 1.3;

  /// Sous cette hauteur de vue, aussi (telephone en paysage).
  static const double hauteurCompacte = 600;

  @override
  Widget build(BuildContext context) {
    final e = t.controleur.echanges;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    final Widget titre = Text(
      e.contexte,
      style: palette.inkMuted.applyTo(textes.labelLarge ?? const TextStyle()),
    );
    // SUPERPOS-1 : en-tete compact. A texte agrandi ou sur une vue basse,
    // les trois lignes cle / valeur poussaient le fil et sa saisie hors de
    // l'ecran (320 en texte double : la page entiere n'etait qu'en-tete) ;
    // le contexte tient alors en une phrase, sans rien retirer.
    final double echelle = MediaQuery.textScalerOf(context).scale(1);
    final bool compact =
        echelle > _ContexteEpingle.echelleCompacte ||
        MediaQuery.sizeOf(context).height < _ContexteEpingle.hauteurCompacte;
    if (compact) {
      return Semantics(
        key: EchangesControleurPage.contexteCompactKey,
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            titre,
            Ecart.vXs,
            Text(
              <String>[
                fil.classe,
                dateDeLAppareil(fil.debutMission),
                heureDeLAppareil(fil.debutMission),
              ].join(' · '),
              style: palette.inkStrong.applyTo(
                textes.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),
      );
    }
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          titre,
          Ecart.vSm,
          LigneCleValeur(cle: e.cleClasse, valeur: fil.classe),
          LigneCleValeur(
            cle: e.cleDate,
            valeur: dateDeLAppareil(fil.debutMission),
          ),
          LigneCleValeur(
            cle: e.cleHeure,
            valeur: heureDeLAppareil(fil.debutMission),
            chiffres: true,
          ),
        ],
      ),
    );
  }
}
