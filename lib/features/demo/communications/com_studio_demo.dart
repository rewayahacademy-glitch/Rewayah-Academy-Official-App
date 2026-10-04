// La demonstration de la voie COM-STU (Le Studio) :
// `/demo/communications?voie=studio&situation=...`.
//
// Hors production : la route n'existe que si `environnementAutoriseDemo`
// l'autorise (DEMO-ENV-1), et rien ici n'est un port reel (K-28). Les
// fixtures (spec section 26 et section 9.1) : cinq canaux ranges dans la
// taxonomie du Studio, dont un restreint autorise et un prive autorise, un
// canal prive ABSENT pour la personne (jamais rendu, R-COM-08), un canal en
// lecture seule, un vocal, des pieces jointes, des elements epingles, des
// liens utiles (un interne, un externe), un echec d'envoi (R-COM-13) et un
// etat hors ligne.
//
// Le Studio n'est ouvert qu'a la direction en V1 (QUESTIONS Q1) : la
// demonstration ne met donc en scene que ce point de vue, et le `?role=` de
// l'adresse est ignore.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../../core/communications/port_elements_enregistres.dart';
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../com_studio/elements_enregistres_studio.dart';
import '../../com_studio/port_studio.dart';
import '../../com_studio/recherche_studio.dart';
import '../../com_studio/studio_page.dart';
import 'demo_communications_page.dart';

/// Les situations que la demonstration sait mettre en scene.
enum SituationDemoStudio {
  /// Tout repond.
  normale,

  /// Le premier envoi de chaque message n'est pas confirme ; « Reessayer »
  /// rejoue la meme cle et aboutit (R-COM-13).
  echecEnvoi,

  /// L'appareil est hors ligne : le contenu deja lu reste, aucun envoi
  /// n'aboutit.
  horsLigne,

  /// L'adresse demande un canal prive qui n'est pas ouvert a la personne :
  /// il n'est pas rendu (R-COM-08).
  canalPrive,

  /// Aucun canal n'est ouvert a la personne.
  sansCanaux,
}

/// L'identifiant du canal prive que la personne ne voit jamais (R-COM-08).
const String canalPriveAbsentDemo = 'direction-strategie';

/// L'adresse de la demonstration du Studio dans [situation].
String adresseDemoStudio({
  SituationDemoStudio situation = SituationDemoStudio.normale,
}) => Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{
    'voie': VoieDemoCommunications.studio.name,
    'situation': situation.name,
  },
).toString();

/// Le libelle d'une situation de la demonstration.
String libelleSituationDemoStudio(SituationDemoStudio situation) {
  final d = t.com.studio.demo;
  return switch (situation) {
    SituationDemoStudio.normale => d.normale,
    SituationDemoStudio.echecEnvoi => d.echec,
    SituationDemoStudio.horsLigne => d.horsLigne,
    SituationDemoStudio.canalPrive => d.canalPrive,
    SituationDemoStudio.sansCanaux => d.sansCanaux,
  };
}

/// La demonstration de la voie Le Studio.
class ComStudioDemo extends StatelessWidget {
  /// Cree la demonstration de la voie.
  const ComStudioDemo({super.key, this.role, this.situation});

  /// Le role mis en scene (`?role=`) : ignore, Le Studio n'a qu'un point de
  /// vue en V1 (la direction).
  final RoleDemoCommunications? role;

  /// La situation ; nulle, celle de l'adresse (`?situation=`), sinon le
  /// choix des situations.
  final SituationDemoStudio? situation;

  SituationDemoStudio? _situation(BuildContext context) {
    final SituationDemoStudio? donnee = situation;
    if (donnee != null) return donnee;
    if (GoRouter.maybeOf(context) == null) return null;
    final String? nom = GoRouterState.of(context)
        .uri
        .queryParameters['situation'];
    for (final SituationDemoStudio s in SituationDemoStudio.values) {
      if (s.name == nom) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final SituationDemoStudio? s = _situation(context);
    if (s == null) return const _ChoixSituation();
    return _DemoStudio(
      key: ValueKey<String>('demo-studio-${s.name}'),
      situation: s,
    );
  }
}

class _ChoixSituation extends StatelessWidget {
  const _ChoixSituation();

  @override
  Widget build(BuildContext context) {
    final d = t.com.studio.demo;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    void aller(String adresse) => GoRouter.of(context).go(adresse);
    return PageShell(
      titre: t.com.studio.titre,
      sousTitre: t.com.socle.navigation.demo.detail,
      onRetour: () => aller(Routes.demoCommunications),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            d.choisir,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          for (final SituationDemoStudio s in SituationDemoStudio.values)
            LienFleche(
              key: ValueKey<String>('demo-studio-situation-${s.name}'),
              libelle: libelleSituationDemoStudio(s),
              onPress: () => aller(adresseDemoStudio(situation: s)),
            ),
        ],
      ),
    );
  }
}

class _DemoStudio extends StatefulWidget {
  const _DemoStudio({required this.situation, super.key});

  final SituationDemoStudio situation;

  @override
  State<_DemoStudio> createState() => _DemoStudioState();
}

class _DemoStudioState extends State<_DemoStudio> {
  late final StudioDemo _port = StudioDemo(situation: widget.situation);
  final ElementsEnregistresMemoire _enregistres = ElementsEnregistresMemoire();
  VueStudio _vue = VueStudio.canaux;
  late String? _canalId = widget.situation == SituationDemoStudio.canalPrive
      ? canalPriveAbsentDemo
      : null;

  /// Ouvre un chemin interne : un canal du Studio s'ouvre dans la
  /// demonstration ; tout autre chemin quitterait la demonstration, il est
  /// ignore.
  void _ouvrir(String chemin) {
    final String? id = canalDuChemin(chemin);
    if (id == null) return;
    setState(() {
      _vue = VueStudio.canaux;
      _canalId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[
        portStudioProvider.overrideWithValue(_port),
        portElementsEnregistresProvider.overrideWithValue(_enregistres),
        if (widget.situation == SituationDemoStudio.horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      child: CoquilleStudio(
        vue: _vue,
        sousTitre: t.com.studio.demo.vue(
          situation: libelleSituationDemoStudio(widget.situation),
        ),
        onAllerVue: (VueStudio v) => setState(() {
          _vue = v;
          _canalId = null;
        }),
        onRetourListe: _canalId == null
            ? null
            : () => setState(() => _canalId = null),
        onQuitter: () =>
            GoRouter.of(context)
                .go(adresseDemoCommunications(VoieDemoCommunications.studio)),
        child: switch (_vue) {
          VueStudio.canaux => EspaceStudio(
            canalId: _canalId,
            onOuvrirCanal: (String id) => setState(() => _canalId = id),
            onOuvrir: _ouvrir,
          ),
          VueStudio.enregistres => VueElementsEnregistres(onOuvrir: _ouvrir),
        },
      ),
    );
  }
}

/// L'identifiant du canal qu'ouvre [chemin] (`/admin/studio/canaux/:id`),
/// ou `null` si le chemin mene ailleurs.
String? canalDuChemin(String chemin) {
  const String prefixe = '${Routes.adminStudioCanaux}/';
  if (!chemin.startsWith(prefixe)) return null;
  final String reste = chemin.substring(prefixe.length);
  if (reste.isEmpty || reste.contains('/')) return null;
  return Uri.decodeComponent(reste);
}

/// Un canal de la demonstration, avec ce qu'il partage.
class _CanalDemo {
  _CanalDemo(this.canal, this.partages);

  Canal canal;
  final PartagesCanal partages;
}

/// Les membres de l'equipe de la demonstration (noms fictifs).
abstract final class _Equipe {
  static const Participant soi = Participant(
    id: 'p-soi',
    nomAffiche: 'Nadia',
    fonction: 'Direction',
    estSoi: true,
  );
  static const Participant mariam = Participant(
    id: 'p-mariam',
    nomAffiche: 'Mariam',
    fonction: 'Coordination générale',
  );
  static const Participant youssef = Participant(
    id: 'p-youssef',
    nomAffiche: 'Youssef',
    fonction: 'Produit et technique',
  );
  static const Participant amina = Participant(
    id: 'p-amina',
    nomAffiche: 'Amina',
    fonction: 'Pédagogie',
  );
  static const Participant samira = Participant(
    id: 'p-samira',
    nomAffiche: 'Samira',
    fonction: 'Admissions',
  );
  static const Participant ibrahim = Participant(
    id: 'p-ibrahim',
    nomAffiche: 'Ibrahim',
    fonction: 'Planning',
  );
}

PieceJointe _pdf(String id, String nom, int octets) => PieceJointe(
  reference: ReferencePieceJointe(id),
  nom: nom,
  nature: NaturePieceJointe.document,
  typeLisible: 'PDF',
  tailleOctets: octets,
);

/// Les canaux de la demonstration (spec section 9.1 et section 26), le canal
/// prive absent compris : c'est le port qui le retire, jamais l'ecran seul.
List<(Canal, PartagesCanal)> fixturesStudioDemo(DateTime maintenant) {
  final DateTime m = maintenant.toUtc();
  DateTime il(int minutes) => m.subtract(Duration(minutes: minutes));
  final PieceJointe planning = _pdf('pj-planning', 'Planning_T3.pdf', 1153434);
  final PieceJointe moderation = _pdf(
    'pj-moderation',
    'Guide_de_moderation.pdf',
    819200,
  );
  final PieceJointe vocal = PieceJointe(
    reference: ReferencePieceJointe('pj-vocal-youssef'),
    nom: 'vocal-youssef.m4a',
    nature: NaturePieceJointe.vocal,
    typeLisible: 'Audio',
    duree: const Duration(seconds: 42),
  );
  final PieceJointe compteRendu = _pdf(
    'pj-compte-rendu',
    'Compte_rendu_visites.pdf',
    245760,
  );
  return <(Canal, PartagesCanal)>[
    (
      Canal(
        resume: ResumeCanal(
          id: 'organisation',
          nom: 'Organisation générale',
          section: SectionStudio.organisation,
          visibilite: VisibiliteCanal.visible,
          description: "Coordination de toute l'équipe",
          attention: const IndicateurAttention(
            nonLus: 2,
            niveau: NiveauAttention.aLire,
          ),
          dernierMessageLe: il(20),
        ),
        membres: const <Participant>[
          _Equipe.soi,
          _Equipe.mariam,
          _Equipe.youssef,
          _Equipe.amina,
          _Equipe.samira,
          _Equipe.ibrahim,
        ],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-org-1',
            auteur: _Equipe.mariam,
            texte:
                "Bonjour à toute l'équipe. Voici le planning du prochain "
                'trimestre, dites-moi si quelque chose ne va pas.',
            envoyeLe: il(95),
            piecesJointes: <PieceJointe>[planning],
          ),
          MessageCommunication(
            id: 'm-org-2',
            auteur: _Equipe.youssef,
            texte: '',
            envoyeLe: il(70),
            piecesJointes: <PieceJointe>[vocal],
          ),
          MessageCommunication(
            id: 'm-org-3',
            auteur: _Equipe.amina,
            texte:
                'Je mets à jour les supports du niveau 2 et on fait le '
                'point demain.',
            envoyeLe: il(40),
          ),
          MessageCommunication(
            id: 'm-org-4',
            auteur: _Equipe.samira,
            texte: 'Merci à tous pour la semaine.',
            envoyeLe: il(20),
            mentionneSoi: true,
          ),
        ],
        capacites: const <CapaciteCanal>{
          CapaciteCanal.ecrire,
          CapaciteCanal.parametres,
        },
      ),
      PartagesCanal(
        epingles: <ElementPartage>[
          ElementPartage(
            id: 'ep-planning',
            titre: 'Planning du trimestre',
            nature: NaturePartage.epingle,
            piece: planning,
            detail: 'Épinglé par Mariam',
          ),
          ElementPartage(
            id: 'ep-moderation',
            titre: 'Guide de modération',
            nature: NaturePartage.epingle,
            piece: moderation,
            detail: 'Épinglé par Youssef',
          ),
        ],
        fichiers: <ElementPartage>[
          ElementPartage(
            id: 'fi-planning',
            titre: 'Planning_T3.pdf',
            nature: NaturePartage.fichier,
            piece: planning,
            detail: 'Partagé par Mariam',
          ),
        ],
        liens: <ElementPartage>[
          ElementPartage(
            id: 'li-remplacements',
            titre: 'Remplacements de la semaine',
            nature: NaturePartage.lien,
            destination: Routes.canalStudioPour('remplacements'),
          ),
          ElementPartage(
            id: 'li-charte',
            titre: "Charte de l'équipe",
            nature: NaturePartage.lien,
            hote: 'rewayah.org',
          ),
        ],
      ),
    ),
    (
      Canal(
        resume: ResumeCanal(
          id: 'admissions',
          nom: 'Admissions',
          section: SectionStudio.admissionsFamilles,
          visibilite: VisibiliteCanal.visible,
          description: "Suivi des demandes d'inscription",
          attention: const IndicateurAttention(
            nonLus: 1,
            niveau: NiveauAttention.actionRequise,
            mention: true,
          ),
          dernierMessageLe: il(55),
        ),
        membres: const <Participant>[
          _Equipe.soi,
          _Equipe.samira,
          _Equipe.mariam,
        ],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-adm-1',
            auteur: _Equipe.samira,
            texte:
                'Trois dossiers attendent une décision avant vendredi. '
                'Nadia, peux-tu regarder le dossier de la famille Karim ?',
            envoyeLe: il(55),
            mentionneSoi: true,
          ),
        ],
        capacites: const <CapaciteCanal>{CapaciteCanal.ecrire},
      ),
      PartagesCanal(),
    ),
    (
      Canal(
        resume: ResumeCanal(
          id: 'qualite',
          nom: 'Suivi qualité',
          section: SectionStudio.pedagogieQualite,
          visibilite: VisibiliteCanal.restreint,
          description: 'Retours des visites de contrôle',
          dernierMessageLe: il(60 * 26),
        ),
        membres: const <Participant>[
          _Equipe.soi,
          _Equipe.amina,
          _Equipe.mariam,
        ],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-qua-1',
            auteur: _Equipe.amina,
            texte: 'Le compte rendu des visites du mois est prêt.',
            envoyeLe: il(60 * 26),
            piecesJointes: <PieceJointe>[compteRendu],
          ),
        ],
        capacites: const <CapaciteCanal>{CapaciteCanal.ecrire},
      ),
      PartagesCanal(
        fichiers: <ElementPartage>[
          ElementPartage(
            id: 'fi-compte-rendu',
            titre: 'Compte_rendu_visites.pdf',
            nature: NaturePartage.fichier,
            piece: compteRendu,
            detail: 'Partagé par Amina',
          ),
        ],
      ),
    ),
    (
      Canal(
        resume: ResumeCanal(
          id: 'remplacements',
          nom: 'Remplacements',
          section: SectionStudio.planningRemplacements,
          visibilite: VisibiliteCanal.visible,
          description: 'Absences et remplacements de la semaine',
          dernierMessageLe: il(60 * 3),
        ),
        membres: const <Participant>[_Equipe.soi, _Equipe.ibrahim],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-rem-1',
            auteur: _Equipe.ibrahim,
            texte:
                'Mardi, la Classe An-Nour est assurée par un remplaçant. '
                'Le planning est à jour.',
            envoyeLe: il(60 * 3),
          ),
        ],
      ),
      PartagesCanal(),
    ),
    (
      Canal(
        resume: ResumeCanal(
          id: 'cloture',
          nom: 'Clôture du mois',
          section: SectionStudio.finance,
          visibilite: VisibiliteCanal.priveAutorise,
          description: 'Préparation de la clôture mensuelle',
          dernierMessageLe: il(60 * 50),
        ),
        membres: const <Participant>[_Equipe.soi, _Equipe.mariam],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-clo-1',
            auteur: _Equipe.mariam,
            texte: 'Les justificatifs de septembre sont rassemblés.',
            envoyeLe: il(60 * 50),
          ),
        ],
        capacites: const <CapaciteCanal>{CapaciteCanal.ecrire},
      ),
      PartagesCanal(),
    ),
    // Le canal prive dont la personne n'est pas membre : le serveur ne le
    // rendrait pas. Le port de demonstration le garde pour prouver qu'il
    // ne sort jamais (R-COM-08).
    (
      Canal(
        resume: ResumeCanal(
          id: canalPriveAbsentDemo,
          nom: 'Direction stratégique',
          section: SectionStudio.direction,
          visibilite: VisibiliteCanal.absent,
          description: 'Orientations de la direction',
          dernierMessageLe: il(10),
        ),
        membres: const <Participant>[_Equipe.mariam],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'm-dir-1',
            auteur: _Equipe.mariam,
            texte: 'Budget confidentiel du trimestre.',
            envoyeLe: il(10),
          ),
        ],
        capacites: const <CapaciteCanal>{CapaciteCanal.ecrire},
      ),
      PartagesCanal(
        fichiers: <ElementPartage>[
          ElementPartage(
            id: 'fi-budget',
            titre: 'Budget_confidentiel.pdf',
            nature: NaturePartage.fichier,
            piece: _pdf('pj-budget', 'Budget_confidentiel.pdf', 40960),
          ),
        ],
      ),
    ),
  ];
}

/// Le port du Studio de la demonstration : en memoire, sans serveur. Jamais
/// branche hors de `environnementAutoriseDemo`.
///
/// Comme le ferait le serveur, il ne rend JAMAIS un canal absent : ni dans
/// `canaux()`, ni par `canal(id)`, ni par `partages`, ni dans `rechercher`.
class StudioDemo implements PortStudio {
  /// Cree le port dans [situation]. [maintenant] fixe l'heure des fixtures
  /// (les tests la donnent).
  StudioDemo({
    this.situation = SituationDemoStudio.normale,
    DateTime? maintenant,
  }) : _canaux = <String, _CanalDemo>{
         for (final (Canal c, PartagesCanal p) in fixturesStudioDemo(
           maintenant ?? DateTime.now(),
         ))
           c.id: _CanalDemo(c, p),
       };

  /// La situation mise en scene.
  final SituationDemoStudio situation;

  final Map<String, _CanalDemo> _canaux;
  final Set<String> _clesEnEchec = <String>{};

  /// Les cles d'idempotence recues, dans l'ordre (pour les tests).
  final List<String> clesRecues = <String>[];

  /// Les canaux que la personne voit : jamais un canal absent.
  Iterable<_CanalDemo> get _autorises =>
      situation == SituationDemoStudio.sansCanaux
      ? const <_CanalDemo>[]
      : _canaux.values.where(
          (_CanalDemo c) => c.canal.resume.visibilite.estRendu,
        );

  _CanalDemo? _autorise(String id) {
    for (final _CanalDemo c in _autorises) {
      if (c.canal.id == id) return c;
    }
    return null;
  }

  /// Le canal [id] tel qu'il est en memoire, absent compris (pour les
  /// tests).
  Canal? canalEnMemoire(String id) => _canaux[id]?.canal;

  @override
  Future<List<ResumeCanal>> canaux() async => <ResumeCanal>[
    for (final _CanalDemo c in _autorises) c.canal.resume,
  ];

  @override
  Future<Canal?> canal(String canalId) async => _autorise(canalId)?.canal;

  @override
  Future<PartagesCanal> partages(String canalId) async =>
      _autorise(canalId)?.partages ?? PartagesCanal.aucun;

  @override
  Future<ResultatsStudio> rechercher(String texte) async {
    final List<String> mots = motsRecherche(texte);
    if (mots.isEmpty) return ResultatsStudio();
    final List<ResumeCanal> canaux = <ResumeCanal>[];
    final List<MessageTrouve> messages = <MessageTrouve>[];
    final List<FichierTrouve> fichiers = <FichierTrouve>[];
    for (final _CanalDemo c in _autorises) {
      final ResumeCanal r = c.canal.resume;
      if (contientTousLesMots('${r.nom} ${r.description ?? ''}', mots)) {
        canaux.add(r);
      }
      for (final MessageCommunication m in c.canal.messages) {
        if (m.texte.isNotEmpty &&
            contientTousLesMots('${m.texte} ${m.auteur.nomAffiche}', mots)) {
          messages.add(MessageTrouve(canal: r, message: m));
        }
      }
      for (final ElementPartage e in <ElementPartage>[
        ...c.partages.epingles,
        ...c.partages.fichiers,
      ]) {
        if (e.piece != null && contientTousLesMots(e.titre, mots)) {
          fichiers.add(FichierTrouve(canal: r, element: e));
        }
      }
    }
    return ResultatsStudio(
      canaux: canaux,
      messages: messages,
      fichiers: fichiers,
    );
  }

  @override
  Future<void> marquerLu(String canalId) async {
    final _CanalDemo? c = _autorise(canalId);
    if (c == null) return;
    final ResumeCanal r = c.canal.resume;
    c.canal = _copie(
      c.canal,
      resume: ResumeCanal(
        id: r.id,
        nom: r.nom,
        section: r.section,
        visibilite: r.visibilite,
        description: r.description,
        dernierMessageLe: r.dernierMessageLe,
      ),
    );
  }

  @override
  Future<void> envoyer(String canalId, String texte, String cle) async {
    clesRecues.add(cle);
    final _CanalDemo? c = _autorise(canalId);
    if (c == null || !c.canal.peut(CapaciteCanal.ecrire)) {
      throw StateError('Canal non autorise');
    }
    switch (situation) {
      case SituationDemoStudio.horsLigne:
        throw StateError('Hors ligne');
      case SituationDemoStudio.echecEnvoi:
        // Le premier essai d'une cle echoue ; le nouvel essai, meme cle,
        // aboutit.
        if (_clesEnEchec.add(cle)) throw StateError('Envoi non confirme');
      case SituationDemoStudio.normale ||
          SituationDemoStudio.canalPrive ||
          SituationDemoStudio.sansCanaux:
        break;
    }
    final DateTime maintenant = DateTime.now().toUtc();
    final ResumeCanal r = c.canal.resume;
    c.canal = _copie(
      c.canal,
      resume: ResumeCanal(
        id: r.id,
        nom: r.nom,
        section: r.section,
        visibilite: r.visibilite,
        description: r.description,
        attention: r.attention,
        dernierMessageLe: maintenant,
      ),
      messages: <MessageCommunication>[
        ...c.canal.messages,
        MessageCommunication(
          id: 'envoye-$cle',
          auteur: _Equipe.soi,
          texte: texte,
          envoyeLe: maintenant,
        ),
      ],
    );
  }

  static Canal _copie(
    Canal c, {
    ResumeCanal? resume,
    List<MessageCommunication>? messages,
  }) => Canal(
    resume: resume ?? c.resume,
    membres: c.membres,
    messages: messages ?? c.messages,
    capacites: c.capacites,
  );
}
