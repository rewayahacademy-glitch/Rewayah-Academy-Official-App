// La demonstration de la voie COM-MSG (Messages metier) :
// `/demo/communications?voie=messages&role=...&situation=...`.
//
// Hors production : la route n'existe que si `environnementAutoriseDemo`
// l'autorise (DEMO-ENV-1), et rien ici n'est un port reel (K-28). Les
// fixtures (spec section 26) : fils parent/enseignant, administration/
// famille, controleur/administration, un vocal, une piece jointe, un objet
// lie devenu inaccessible, un fil d'une autre famille refuse (R-COM-02), un
// echec d'envoi (R-COM-13) et un etat hors ligne.
//
// Le role mis en scene est un choix d'affichage de la demonstration, jamais
// un role de session : il ne sert qu'a choisir les fixtures.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Override` n'est pas exporte par l'entree principale de Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';

import '../../../core/communications/capacites_communication.dart';
import '../../../core/communications/lecture_fil_communication.dart'
    show texteDuMessage;
import '../../../core/i18n/strings.g.dart';
import '../../../core/reseau/service_reseau.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/lien_fleche.dart';
import '../../../core/widgets/page_shell.dart';
import '../../com_messages/messages_page.dart';
import '../../com_messages/port_messages_metier.dart';
import 'com_vocal_demo.dart';
import 'demo_communications_page.dart';

/// Les situations que la demonstration sait mettre en scene.
enum SituationDemoMessages {
  /// Tout repond.
  normale,

  /// Le premier envoi de chaque message n'est pas confirme ; « Reessayer »
  /// rejoue la meme cle et aboutit (R-COM-13).
  echecEnvoi,

  /// L'appareil est hors ligne : le contenu deja lu reste, aucun envoi
  /// n'aboutit.
  horsLigne,

  /// L'adresse demande le fil d'une autre famille : il n'est pas rendu
  /// (R-COM-02).
  filRefuse,
}

/// L'identifiant du fil d'une autre famille, que le port refuse toujours.
const String filAutreFamilleDemo = 'fil-autre-famille';

/// L'adresse de la demonstration des Messages pour [role] et [situation].
String adresseDemoMessages(
  RoleDemoCommunications role, {
  SituationDemoMessages situation = SituationDemoMessages.normale,
}) => Uri(
  path: Routes.demoCommunications,
  queryParameters: <String, String>{
    'voie': VoieDemoCommunications.messages.name,
    'role': role.name,
    if (situation != SituationDemoMessages.normale) 'situation': situation.name,
  },
).toString();

/// La demonstration de la voie Messages metier.
class ComMessagesDemo extends StatelessWidget {
  /// Cree la demonstration de la voie.
  const ComMessagesDemo({super.key, this.role, this.situation});

  /// Le role mis en scene (`?role=`), nul si l'adresse n'en donne pas.
  final RoleDemoCommunications? role;

  /// La situation (`?situation=`) ; nulle, celle de l'adresse, sinon la
  /// situation normale.
  final SituationDemoMessages? situation;

  SituationDemoMessages _situation(BuildContext context) {
    final SituationDemoMessages? donnee = situation;
    if (donnee != null) return donnee;
    if (GoRouter.maybeOf(context) == null) {
      return SituationDemoMessages.normale;
    }
    final String? nom = GoRouterState.of(context)
        .uri
        .queryParameters['situation'];
    for (final SituationDemoMessages s in SituationDemoMessages.values) {
      if (s.name == nom) return s;
    }
    return SituationDemoMessages.normale;
  }

  @override
  Widget build(BuildContext context) {
    final RoleDemoCommunications? r = role;
    if (r == null) return const _ChoixRole();
    final SituationDemoMessages s = _situation(context);
    return _DemoMessages(
      key: ValueKey<String>('demo-messages-${r.name}-${s.name}'),
      role: r,
      situation: s,
    );
  }
}

/// Le libelle d'un role de la demonstration.
String libelleRoleDemoMessages(RoleDemoCommunications role) {
  final x = t.com.messages.demo.roles;
  return switch (role) {
    RoleDemoCommunications.tuteur => x.tuteur,
    RoleDemoCommunications.enseignant => x.enseignant,
    RoleDemoCommunications.adulte => x.adulte,
    RoleDemoCommunications.admin => x.admin,
    RoleDemoCommunications.controleur => x.controleur,
  };
}

class _ChoixRole extends StatelessWidget {
  const _ChoixRole();

  @override
  Widget build(BuildContext context) {
    final d = t.com.messages.demo;
    final AppPalette palette = AppPalette.of(context);
    final TextTheme textes = Theme.of(context).textTheme;
    void aller(String adresse) => GoRouter.of(context).go(adresse);
    return PageShell(
      titre: t.com.messages.titre,
      sousTitre: t.com.socle.navigation.demo.detail,
      onRetour: () => aller(Routes.demoCommunications),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            d.choisirRole,
            style: palette.inkMuted.applyTo(
              textes.bodyMedium ?? const TextStyle(),
            ),
          ),
          Ecart.vMd,
          for (final RoleDemoCommunications r in RoleDemoCommunications.values)
            LienFleche(
              key: ValueKey<String>('demo-messages-role-${r.name}'),
              libelle: libelleRoleDemoMessages(r),
              onPress: () => aller(adresseDemoMessages(r)),
            ),
          Ecart.vXl,
          Semantics(
            header: true,
            child: Text(
              d.situations,
              style: palette.inkStrong.applyTo(
                textes.titleMedium ?? const TextStyle(),
              ),
            ),
          ),
          Ecart.vSm,
          LienFleche(
            key: const ValueKey<String>('demo-messages-echec'),
            libelle: d.echec,
            onPress: () => aller(
              adresseDemoMessages(
                RoleDemoCommunications.enseignant,
                situation: SituationDemoMessages.echecEnvoi,
              ),
            ),
          ),
          LienFleche(
            key: const ValueKey<String>('demo-messages-hors-ligne'),
            libelle: d.horsLigne,
            onPress: () => aller(
              adresseDemoMessages(
                RoleDemoCommunications.tuteur,
                situation: SituationDemoMessages.horsLigne,
              ),
            ),
          ),
          LienFleche(
            key: const ValueKey<String>('demo-messages-refuse'),
            libelle: d.refuse,
            onPress: () => aller(
              adresseDemoMessages(
                RoleDemoCommunications.tuteur,
                situation: SituationDemoMessages.filRefuse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoMessages extends StatefulWidget {
  const _DemoMessages({required this.role, required this.situation, super.key});

  final RoleDemoCommunications role;
  final SituationDemoMessages situation;

  @override
  State<_DemoMessages> createState() => _DemoMessagesState();
}

class _DemoMessagesState extends State<_DemoMessages> {
  late final MessagesMetierDemo _port = MessagesMetierDemo(
    role: widget.role,
    situation: widget.situation,
  );
  late String? _filId = widget.situation == SituationDemoMessages.filRefuse
      ? filAutreFamilleDemo
      : null;

  void _retour() {
    if (_filId != null) {
      setState(() => _filId = null);
    } else {
      GoRouter.of(context)
          .go(adresseDemoCommunications(VoieDemoCommunications.messages));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[
        portMessagesMetierProvider.overrideWithValue(_port),
        // Hors production seulement : la demonstration ouvre l'ecriture
        // (COM-BR-16) ; le fil decide encore par sa propre capacite. Le
        // provider lu par la page est surcharge lui-meme : sans
        // `dependencies`, il se resoudrait dans la portee racine, sur le
        // port neutre.
        capacitesCommunicationProvider.overrideWith(
          (Ref _) => const CapacitesCommunicationsFixes(<CapaciteCommunication>{
            CapaciteCommunication.ecrireDansFil,
            // COM-FUS : le composer vocal (faux micro, envoi accuse).
            CapaciteCommunication.envoyerVocal,
          }).capacites(),
        ),
        ...surchargesVocalDemo(),
        if (widget.situation == SituationDemoMessages.horsLigne)
          horsLigneProvider.overrideWith((Ref _) => Stream<bool>.value(true)),
      ],
      child: PageShell(
        titre: t.com.messages.titre,
        sousTitre: t.com.messages.demo.vue(
          role: libelleRoleDemoMessages(widget.role),
        ),
        onRetour: _retour,
        defilante: false,
        child: EspaceMessagesMetier(
          filId: _filId,
          onOuvrirFil: (String id) => setState(() => _filId = id),
        ),
      ),
    );
  }
}

/// Le port des Messages metier de la demonstration : en memoire, sans
/// serveur. Jamais branche hors de `environnementAutoriseDemo`.
class MessagesMetierDemo implements PortMessagesMetier {
  /// Cree le port pour [role], dans [situation]. [maintenant] fixe l'heure
  /// des fixtures (les tests la donnent).
  MessagesMetierDemo({
    required RoleDemoCommunications role,
    this.situation = SituationDemoMessages.normale,
    DateTime? maintenant,
  }) : _fils = <String, FilMetier>{
         for (final FilMetier f in fixturesMessagesDemo(
           role,
           maintenant ?? DateTime.now(),
         ))
           f.id: f,
       },
       _aOuvrir = conversationsAOuvrirDemo(role);

  /// La situation mise en scene.
  final SituationDemoMessages situation;

  final Map<String, FilMetier> _fils;
  final Set<String> _clesEnEchec = <String>{};

  /// Les conversations possibles sans fil encore ouvert, par objet de page
  /// (`type:id`) : `ouvrirConversation` en cree le fil a la demande.
  final Map<String, List<ConversationPossible>> _aOuvrir;

  /// Les cles d'idempotence recues, dans l'ordre (pour les tests).
  final List<String> clesRecues = <String>[];

  /// Le fil [id] tel qu'il est en memoire, pour les tests.
  FilMetier? filEnMemoire(String id) => _fils[id];

  @override
  Future<List<ResumeFil>> fils() async {
    final List<FilMetier> tries = _fils.values.toList()
      ..sort((FilMetier a, FilMetier b) => _dernier(b).compareTo(_dernier(a)));
    return <ResumeFil>[for (final FilMetier f in tries) _resume(f)];
  }

  @override
  Future<FilMetier?> fil(String filId) async => _fils[filId];

  @override
  Future<FilMetier?> filPourObjet(TypeObjetLie type, String objetId) async {
    // Le fil canonique de l'objet (COM-MSG-1) : la premiere conversation
    // possible sur cet objet. L'entree d'une page passe par
    // `ouvrirConversation`, qui tient compte de l'interlocuteur.
    for (final FilMetier f in _fils.values) {
      if (f.contexte.last.objet.type == type &&
          f.contexte.last.objet.id == objetId) {
        return f;
      }
    }
    for (final List<ConversationPossible> liste in _aOuvrir.values) {
      for (final ConversationPossible c in liste) {
        if (c.objet.type == type && c.objet.id == objetId) {
          return ouvrirConversation(c);
        }
      }
    }
    return null;
  }

  @override
  Future<FilMetier?> ouvrirConversation(
    ConversationPossible conversation,
  ) async {
    // Le fil existant de la PAIRE (objet, interlocuteur), jamais celui d'un
    // autre interlocuteur sur le meme objet (spec section 3.2).
    for (final FilMetier f in _fils.values) {
      if (_dePaire(f, conversation)) return f;
    }
    // Une conversation possible sans fil : le fil est cree, vide, comme le
    // ferait le serveur pour une paire autorisee (spec section 3.2).
    for (final List<ConversationPossible> liste in _aOuvrir.values) {
      for (final ConversationPossible c in liste) {
        if (c.cle != conversation.cle) continue;
        final String base = 'fil-${c.objet.id}';
        final FilMetier cree = FilMetier(
          id: _fils.containsKey(base) ? '$base-${c.interlocuteur.id}' : base,
          contexte: <ElementContexteFil>[ElementContexteFil(objet: c.objet)],
          participants: <Participant>[_soi(), c.interlocuteur],
          messages: const <MessageCommunication>[],
          capacites: const <CapaciteFil>{CapaciteFil.ecrire},
        );
        _fils[cree.id] = cree;
        return cree;
      }
    }
    return null;
  }

  static bool _dePaire(FilMetier f, ConversationPossible c) =>
      f.contexte.last.objet.type == c.objet.type &&
      f.contexte.last.objet.id == c.objet.id &&
      f.interlocuteurs.any((Participant p) => p.id == c.interlocuteur.id);

  @override
  Future<List<ConversationPossible>> conversationsPourObjet(
    TypeObjetLie type,
    String objetId,
  ) async {
    final List<ConversationPossible> existantes = <ConversationPossible>[
      for (final FilMetier f in _fils.values)
        if (f.contexte.any(
          (ElementContexteFil e) =>
              e.objet.type == type && e.objet.id == objetId,
        ))
          for (final Participant p in f.interlocuteurs)
            ConversationPossible(
              interlocuteur: p,
              nature: natureInterlocuteurDemo(p),
              objet: f.contexte.last.objet,
              filId: f.id,
              attention: f.attention,
            ),
    ];
    return <ConversationPossible>[
      ...existantes,
      for (final ConversationPossible c
          in _aOuvrir['${type.name}:$objetId'] ??
              const <ConversationPossible>[])
        // Une paire (objet, interlocuteur) deja ouverte n'est pas repetee ;
        // un autre interlocuteur sur le meme objet reste propose.
        if (!existantes.any((ConversationPossible e) => e.cle == c.cle)) c,
    ];
  }

  Participant _soi() {
    for (final FilMetier f in _fils.values) {
      for (final Participant p in f.participants) {
        if (p.estSoi) return p;
      }
    }
    return const Participant(id: 'p-soi', nomAffiche: 'Vous', estSoi: true);
  }

  @override
  Future<void> marquerLu(String filId) async {
    final FilMetier? f = _fils[filId];
    if (f == null) return;
    _fils[filId] = _copie(f, attention: IndicateurAttention.aucun);
  }

  @override
  Future<void> envoyer(String filId, String texte, String cle) async {
    clesRecues.add(cle);
    final FilMetier? f = _fils[filId];
    if (f == null || !f.peut(CapaciteFil.ecrire)) {
      throw StateError('Fil non autorise');
    }
    switch (situation) {
      case SituationDemoMessages.horsLigne:
        throw StateError('Hors ligne');
      case SituationDemoMessages.echecEnvoi:
        // Le premier essai d'une cle echoue ; le nouvel essai, meme cle,
        // aboutit.
        if (_clesEnEchec.add(cle)) throw StateError('Envoi non confirme');
      case SituationDemoMessages.normale || SituationDemoMessages.filRefuse:
        break;
    }
    final Participant soi = f.participants.firstWhere(
      (Participant p) => p.estSoi,
    );
    _fils[filId] = _copie(
      f,
      messages: <MessageCommunication>[
        ...f.messages,
        MessageCommunication(
          id: 'envoye-$cle',
          auteur: soi,
          texte: texte,
          envoyeLe: DateTime.now().toUtc(),
        ),
      ],
    );
  }

  static DateTime _dernier(FilMetier f) => f.messages.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
      : f.messages.last.envoyeLe;

  static ResumeFil _resume(FilMetier f) {
    final MessageCommunication? dernier = f.messages.isEmpty
        ? null
        : f.messages.last;
    final String? apercu = dernier == null
        ? null
        : texteDuMessage(dernier).split('\n').first;
    return ResumeFil(
      id: f.id,
      objet: f.objet,
      interlocuteurs: f.interlocuteurs,
      apercu: apercu == null || apercu.length <= 80
          ? apercu
          : '${apercu.substring(0, 79)}…',
      dernierMessageLe: dernier?.envoyeLe,
      attention: f.attention,
    );
  }

  static FilMetier _copie(
    FilMetier f, {
    IndicateurAttention? attention,
    List<MessageCommunication>? messages,
  }) => FilMetier(
    id: f.id,
    contexte: f.contexte,
    participants: f.participants,
    messages: messages ?? f.messages,
    attention: attention ?? f.attention,
    capacites: f.capacites,
  );
}

/// La nature d'un interlocuteur des fixtures (le serveur la rendra).
NatureInterlocuteur natureInterlocuteurDemo(Participant p) => switch (p.id) {
  'p-ahmed' || 'p-fatima' || 'p-karim' => NatureInterlocuteur.famille,
  'p-direction' => NatureInterlocuteur.administration,
  _ => NatureInterlocuteur.personne,
};

/// Les conversations possibles sans fil encore ouvert, vues par [role], par
/// objet de page (`type:id`) : la famille de Yusuf dans la Classe An-Nour
/// pour l'enseignante, l'Administration sur la Classe pour la famille.
Map<String, List<ConversationPossible>> conversationsAOuvrirDemo(
  RoleDemoCommunications role,
) => switch (role) {
  RoleDemoCommunications.enseignant => <String, List<ConversationPossible>>{
    'classe:classe-an-nour': <ConversationPossible>[
      ConversationPossible(
        interlocuteur: const Participant(
          id: 'p-karim',
          nomAffiche: 'Karim',
          fonction: 'Parent de Yusuf',
        ),
        nature: NatureInterlocuteur.famille,
        objet: ObjetLie(
          type: TypeObjetLie.eleve,
          id: 'eleve-yusuf',
          libelle: 'Yusuf',
        ),
      ),
    ],
  },
  RoleDemoCommunications.tuteur => <String, List<ConversationPossible>>{
    'classe:classe-an-nour': <ConversationPossible>[
      ConversationPossible(
        interlocuteur: const Participant(
          id: 'p-direction',
          nomAffiche: 'Administration',
          fonction: 'Direction de Rewayah',
        ),
        nature: NatureInterlocuteur.administration,
        objet: ObjetLie(
          type: TypeObjetLie.classe,
          id: 'classe-an-nour',
          libelle: 'Classe An-Nour',
        ),
      ),
    ],
  },
  RoleDemoCommunications.adulte ||
  RoleDemoCommunications.admin ||
  RoleDemoCommunications.controleur =>
    const <String, List<ConversationPossible>>{},
};

/// Les fils de demonstration vus par [role] (spec section 26), dates par
/// rapport a [maintenant].
List<FilMetier> fixturesMessagesDemo(
  RoleDemoCommunications role,
  DateTime maintenant,
) {
  final DateTime ici = maintenant.toUtc();
  DateTime il(Duration d) => ici.subtract(d);

  Participant ahmed({bool soi = false}) => Participant(
    id: 'p-ahmed',
    nomAffiche: 'Ahmed',
    fonction: "Parent d'Adam",
    estSoi: soi,
  );
  Participant mariam({bool soi = false}) => Participant(
    id: 'p-mariam',
    nomAffiche: 'Mme Mariam',
    fonction: 'Enseignante de la Classe An-Nour',
    estSoi: soi,
  );
  Participant fatima() => const Participant(
    id: 'p-fatima',
    nomAffiche: 'Fatima',
    fonction: 'Parent de Yasmine',
  );
  Participant direction({bool soi = false}) => Participant(
    id: 'p-direction',
    nomAffiche: 'Administration',
    fonction: 'Direction de Rewayah',
    estSoi: soi,
  );
  Participant rachid({bool soi = false}) => Participant(
    id: 'p-rachid',
    nomAffiche: 'M. Rachid',
    fonction: 'Contrôleur pédagogique',
    estSoi: soi,
  );
  Participant youssef() => const Participant(
    id: 'p-youssef',
    nomAffiche: 'Sayyid Youssef',
    fonction: 'Enseignant de la Classe Al-Fajr',
  );
  Participant khadija({bool soi = false}) => Participant(
    id: 'p-khadija',
    nomAffiche: 'Khadija',
    fonction: 'Élève de la Classe Al-Fajr',
    estSoi: soi,
  );

  final ObjetLie anNour = ObjetLie(
    type: TypeObjetLie.classe,
    id: 'classe-an-nour',
    libelle: 'Classe An-Nour',
  );
  final ObjetLie adam = ObjetLie(
    type: TypeObjetLie.eleve,
    id: 'eleve-adam',
    libelle: 'Adam',
  );
  final ObjetLie yasmine = ObjetLie(
    type: TypeObjetLie.eleve,
    id: 'eleve-yasmine',
    libelle: 'Yasmine',
  );
  final ObjetLie dossierAdam = ObjetLie(
    type: TypeObjetLie.dossier,
    id: 'dossier-adam',
    libelle: "Dossier d'inscription d'Adam",
  );
  final ObjetLie mission = ObjetLie(
    type: TypeObjetLie.mission,
    id: 'mission-12-11',
    libelle: 'Visite de contrôle, Classe An-Nour',
  );
  final ObjetLie alFajr = ObjetLie(
    type: TypeObjetLie.classe,
    id: 'classe-al-fajr',
    libelle: 'Classe Al-Fajr',
  );

  final PieceJointe devoir = PieceJointe(
    reference: ReferencePieceJointe('pj-devoir-3'),
    nom: 'Devoir_semaine_3.pdf',
    nature: NaturePieceJointe.document,
    typeLisible: 'PDF',
    tailleOctets: 2516582,
    peutOuvrir: true,
  );
  final PieceJointe vocal = PieceJointe(
    reference: ReferencePieceJointe('pj-vocal-28'),
    nom: 'vocal.m4a',
    nature: NaturePieceJointe.vocal,
    typeLisible: 'Audio',
    duree: const Duration(seconds: 28),
    // R-04 : le vocal recu de la demonstration se lit (lecture simulee).
    peutOuvrir: true,
  );
  final PieceJointe attestation = PieceJointe(
    reference: ReferencePieceJointe('pj-attestation'),
    nom: 'Attestation_ancienne.pdf',
    nature: NaturePieceJointe.document,
    typeLisible: 'PDF',
    etat: EtatPieceJointe.indisponible,
  );

  // Parent / enseignant, contexte Classe et eleve (R-COM-01).
  FilMetier filAdam({required bool vuParEnseignant}) {
    final Participant parent = ahmed(soi: !vuParEnseignant);
    final Participant enseignante = mariam(soi: vuParEnseignant);
    return FilMetier(
      id: 'fil-adam',
      contexte: <ElementContexteFil>[
        ElementContexteFil(objet: anNour),
        ElementContexteFil(objet: adam),
      ],
      participants: <Participant>[parent, enseignante],
      messages: <MessageCommunication>[
        MessageCommunication(
          id: 'adam-1',
          auteur: parent,
          texte:
              "Bonjour, je voulais savoir comment s'est passée la séance "
              "d'aujourd'hui pour Adam. Merci beaucoup.",
          envoyeLe: il(const Duration(hours: 2, minutes: 12)),
        ),
        MessageCommunication(
          id: 'adam-2',
          auteur: enseignante,
          texte:
              "Bonjour, la séance s'est très bien passée. Adam a été attentif "
              'et a bien participé.',
          envoyeLe: il(const Duration(hours: 2, minutes: 10)),
        ),
        MessageCommunication(
          id: 'adam-3',
          auteur: enseignante,
          texte: '',
          envoyeLe: il(const Duration(hours: 2, minutes: 8)),
          piecesJointes: <PieceJointe>[vocal],
        ),
        MessageCommunication(
          id: 'adam-4',
          auteur: enseignante,
          texte: 'Voici le devoir de la semaine prochaine.',
          envoyeLe: il(const Duration(hours: 2, minutes: 6)),
          piecesJointes: <PieceJointe>[devoir],
        ),
      ],
      attention: vuParEnseignant
          ? IndicateurAttention.aucun
          : const IndicateurAttention(nonLus: 3, niveau: NiveauAttention.aLire),
      capacites: const <CapaciteFil>{CapaciteFil.ecrire},
    );
  }

  // Administration / famille, contexte dossier.
  FilMetier filDossier({required bool vuParDirection}) {
    final Participant parent = ahmed(soi: !vuParDirection);
    final Participant admin = direction(soi: vuParDirection);
    return FilMetier(
      id: 'fil-dossier-adam',
      contexte: <ElementContexteFil>[ElementContexteFil(objet: dossierAdam)],
      participants: <Participant>[parent, admin],
      messages: <MessageCommunication>[
        MessageCommunication(
          id: 'dossier-1',
          auteur: admin,
          texte:
              "Il manque l'attestation de niveau d'Adam pour finaliser son "
              'inscription. Pouvez-vous la déposer dans son dossier ?',
          envoyeLe: il(const Duration(days: 1, hours: 3)),
          piecesJointes: <PieceJointe>[attestation],
        ),
      ],
      attention: vuParDirection
          ? IndicateurAttention.aucun
          : const IndicateurAttention(
              nonLus: 1,
              niveau: NiveauAttention.actionRequise,
            ),
      capacites: const <CapaciteFil>{CapaciteFil.ecrire},
    );
  }

  // Controleur / administration, contexte mission (sans prenom d'eleve).
  FilMetier filMission({required bool vuParControleur}) {
    final Participant controleur = rachid(soi: vuParControleur);
    final Participant admin = direction(soi: !vuParControleur);
    return FilMetier(
      id: 'fil-mission',
      contexte: <ElementContexteFil>[ElementContexteFil(objet: mission)],
      participants: <Participant>[controleur, admin],
      messages: <MessageCommunication>[
        MessageCommunication(
          id: 'mission-1',
          auteur: controleur,
          texte:
              'La séance a commencé avec huit minutes de retard. Le compte '
              'rendu est déposé.',
          envoyeLe: il(const Duration(days: 3)),
        ),
        MessageCommunication(
          id: 'mission-2',
          auteur: admin,
          texte: "Merci, nous en parlons avec l'enseignante cette semaine.",
          envoyeLe: il(const Duration(days: 2, hours: 20)),
        ),
      ],
      capacites: const <CapaciteFil>{CapaciteFil.ecrire},
    );
  }

  return switch (role) {
    RoleDemoCommunications.tuteur => <FilMetier>[
      filAdam(vuParEnseignant: false),
      filDossier(vuParDirection: false),
    ],
    RoleDemoCommunications.enseignant => <FilMetier>[
      filAdam(vuParEnseignant: true),
      FilMetier(
        id: 'fil-yasmine',
        contexte: <ElementContexteFil>[
          ElementContexteFil(objet: anNour),
          // L'eleve a quitte la Classe : nomme, mais plus accessible.
          ElementContexteFil(objet: yasmine, accessible: false),
        ],
        participants: <Participant>[fatima(), mariam(soi: true)],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'yasmine-1',
            auteur: fatima(),
            texte: 'Merci beaucoup pour ces explications.',
            envoyeLe: il(const Duration(days: 4)),
          ),
        ],
        attention: const IndicateurAttention(nonLus: 1),
        capacites: const <CapaciteFil>{CapaciteFil.ecrire},
      ),
      FilMetier(
        id: 'fil-affectation',
        contexte: <ElementContexteFil>[ElementContexteFil(objet: anNour)],
        participants: <Participant>[direction(), mariam(soi: true)],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'affectation-1',
            auteur: direction(),
            texte:
                'Votre Classe An-Nour passe au mardi 18 h a partir du mois '
                'prochain. Merci de confirmer.',
            envoyeLe: il(const Duration(days: 6)),
          ),
        ],
        attention: const IndicateurAttention(
          niveau: NiveauAttention.actionRequise,
        ),
        capacites: const <CapaciteFil>{CapaciteFil.ecrire},
      ),
    ],
    RoleDemoCommunications.adulte => <FilMetier>[
      FilMetier(
        id: 'fil-khadija',
        contexte: <ElementContexteFil>[ElementContexteFil(objet: alFajr)],
        participants: <Participant>[khadija(soi: true), youssef()],
        messages: <MessageCommunication>[
          MessageCommunication(
            id: 'khadija-1',
            auteur: youssef(),
            texte: 'Pensez à réviser la sourate Al-Mulk pour jeudi.',
            envoyeLe: il(const Duration(hours: 5)),
          ),
        ],
        attention: const IndicateurAttention(nonLus: 1),
        capacites: const <CapaciteFil>{CapaciteFil.ecrire},
      ),
    ],
    RoleDemoCommunications.admin => <FilMetier>[
      filDossier(vuParDirection: true),
      filMission(vuParControleur: false),
    ],
    RoleDemoCommunications.controleur => <FilMetier>[
      filMission(vuParControleur: true),
    ],
  };
}
