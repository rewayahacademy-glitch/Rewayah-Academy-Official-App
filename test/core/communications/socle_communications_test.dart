import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/capacites/capacite_indisponible.dart';
import 'package:rewayah_academy/core/communications/modeles_communication.dart';
import 'package:rewayah_academy/core/communications/moderation.dart';
import 'package:rewayah_academy/core/communications/port_brouillons.dart';
import 'package:rewayah_academy/core/communications/port_elements_enregistres.dart';
import 'package:rewayah_academy/core/communications/port_pieces_jointes.dart';
import 'package:rewayah_academy/core/i18n/strings.g.dart';
import 'package:rewayah_academy/core/session/session_controleur.dart';
import 'package:rewayah_academy/core/session/session_state.dart';
import 'package:rewayah_academy/core/session/source_session.dart';

/// Une source de session pilotee par le test : chaque etat pousse change la
/// personne connectee.
class _SourcePilotee implements SourceSession {
  _SourcePilotee(this.flux);

  final StreamController<SessionState> flux;

  @override
  Stream<SessionState> etats() => flux.stream;

  @override
  Future<void> rafraichir() async {}
}

ProviderContainer _conteneur(_SourcePilotee source) => ProviderContainer(
  overrides: [sourceSessionProvider.overrideWithValue(source)],
);

Matcher _indisponible(String dependance) => throwsA(
  isA<CapaciteIndisponible>().having(
    (CapaciteIndisponible c) => c.dependance,
    'dependance',
    dependance,
  ),
);

ObjetLie _publication(String id) =>
    ObjetLie(type: TypeObjetLie.publication, id: id, libelle: 'Publication');

void main() {
  group('NiveauAttention et IndicateurAttention', () {
    test('les niveaux vont du plus calme au plus pressant', () {
      expect(NiveauAttention.values, <NiveauAttention>[
        NiveauAttention.information,
        NiveauAttention.aLire,
        NiveauAttention.actionRequise,
        NiveauAttention.urgent,
      ]);
      expect(
        NiveauAttention.urgent.estAuMoins(NiveauAttention.actionRequise),
        isTrue,
      );
      expect(NiveauAttention.aLire.estAuMoins(NiveauAttention.urgent), isFalse);
      expect(
        NiveauAttention.aLire.max(NiveauAttention.actionRequise),
        NiveauAttention.actionRequise,
      );
      expect(
        NiveauAttention.urgent.compareTo(NiveauAttention.information),
        greaterThan(0),
      );
    });

    test('rien a signaler : le badge n est pas rendu', () {
      expect(IndicateurAttention.aucun.estVisible, isFalse);
      expect(const IndicateurAttention(nonLus: 2).estVisible, isTrue);
      expect(const IndicateurAttention(mention: true).estVisible, isTrue);
      expect(
        const IndicateurAttention(niveau: NiveauAttention.actionRequise)
            .estVisible,
        isTrue,
      );
    });

    test('fusionner additionne et garde le plus pressant', () {
      const IndicateurAttention a = IndicateurAttention(
        nonLus: 2,
        niveau: NiveauAttention.aLire,
      );
      const IndicateurAttention b = IndicateurAttention(
        nonLus: 1,
        niveau: NiveauAttention.urgent,
        mention: true,
      );
      expect(
        a.fusionner(b),
        const IndicateurAttention(
          nonLus: 3,
          niveau: NiveauAttention.urgent,
          mention: true,
        ),
      );
    });
  });

  group('ObjetLie et Participant', () {
    test('une destination externe ou de stockage devient null', () {
      for (final String brut in <String>[
        'https://bucket.r2.cloudflarestorage.com/piece.pdf',
        '//exemple.org/x',
        r'\\serveur\partage',
        'r2://bucket/cle',
      ]) {
        expect(
          ObjetLie(
            type: TypeObjetLie.dossier,
            id: 'd1',
            libelle: 'Dossier',
            destination: brut,
          ).destination,
          isNull,
          reason: brut,
        );
      }
    });

    test('un chemin interne est garde tel quel', () {
      expect(
        ObjetLie(
          type: TypeObjetLie.classe,
          id: 'c1',
          libelle: 'Classe An-Nour',
          destination: '/tuteur/classes/c1',
        ).destination,
        '/tuteur/classes/c1',
      );
    });

    test('deux objets sont egaux par type et identifiant seulement', () {
      final ObjetLie a = ObjetLie(
        type: TypeObjetLie.classe,
        id: 'c1',
        libelle: 'Classe An-Nour',
      );
      final ObjetLie b = ObjetLie(
        type: TypeObjetLie.classe,
        id: 'c1',
        libelle: 'Autre libelle',
      );
      final ObjetLie c = ObjetLie(
        type: TypeObjetLie.eleve,
        id: 'c1',
        libelle: 'Classe An-Nour',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('un message de soi se lit sur son auteur', () {
      final MessageCommunication message = MessageCommunication(
        id: 'm1',
        auteur: const Participant(id: 'p1', nomAffiche: 'Vous', estSoi: true),
        texte: 'Bonjour',
        envoyeLe: DateTime.utc(2026, 10, 4),
      );
      expect(message.deSoi, isTrue);
      expect(message.etat, EtatEnvoiMessage.envoye);
      expect(message.piecesJointes, isEmpty);
    });
  });

  group('Pieces jointes : jamais d URL R2, jamais de chemin', () {
    test('une reference opaque est admise', () {
      expect(ReferencePieceJointe('pj_0123-abc.v2').valeur, 'pj_0123-abc.v2');
    });

    test('une adresse, un chemin ou un jeton sont refuses', () {
      for (final String brut in <String>[
        'https://bucket.r2.cloudflarestorage.com/a.pdf',
        'r2:bucket',
        'dossier/fichier.pdf',
        r'C:\fichier.pdf',
        'a?X-Amz-Signature=abc',
        'a b',
        '../secret',
        '',
      ]) {
        expect(
          () => ReferencePieceJointe(brut),
          throwsArgumentError,
          reason: brut,
        );
      }
    });

    test('la reference ne s ecrit jamais dans un journal', () {
      expect(
        ReferencePieceJointe('pj_secret').toString(),
        isNot(contains('pj_secret')),
      );
    });

    test('le nom affiche est le dernier segment, sans parametre', () {
      final PieceJointe piece = PieceJointe(
        reference: ReferencePieceJointe('pj1'),
        nom: 'interne/2026/plan-de-cours.pdf?token=abc',
        nature: NaturePieceJointe.document,
        typeLisible: 'PDF',
      );
      expect(piece.nom, 'plan-de-cours.pdf');
      expect(piece.peutOuvrir, isFalse);
      expect(piece.avecEtat(EtatPieceJointe.echec).etat, EtatPieceJointe.echec);
      expect(piece.avecEtat(EtatPieceJointe.echec).nom, 'plan-de-cours.pdf');
    });

    test('les sept etats de la section 12', () {
      expect(EtatPieceJointe.values, hasLength(7));
    });

    test('la politique evalue le type avant la taille', () {
      final PolitiquePiecesJointes politique = PolitiquePiecesJointes(
        tailleMaxOctets: 1000,
        typesAutorises: const <String>{'application/pdf', 'IMAGE/*'},
      );
      expect(
        politique.evaluer(typeMime: 'application/pdf', tailleOctets: 10),
        EtatPieceJointe.autorisee,
      );
      expect(
        politique.evaluer(typeMime: 'image/png', tailleOctets: 1000),
        EtatPieceJointe.autorisee,
      );
      expect(
        politique.evaluer(typeMime: 'application/pdf', tailleOctets: 1001),
        EtatPieceJointe.tropVolumineuse,
      );
      expect(
        politique.evaluer(typeMime: 'application/zip', tailleOctets: 5000),
        EtatPieceJointe.typeInterdit,
      );
    });
  });

  group('Ports de production : neutres, ils disent ce qui manque', () {
    late ProviderContainer conteneur;

    late StreamController<SessionState> flux;

    setUp(() {
      flux = StreamController<SessionState>.broadcast();
      conteneur = _conteneur(_SourcePilotee(flux));
    });
    tearDown(() {
      conteneur.dispose();
      unawaited(flux.close());
    });

    test('politique des pieces jointes : COM-BR-04', () {
      expect(
        conteneur.read(portPolitiquePiecesJointesProvider).politique(),
        _indisponible('COM-BR-04'),
      );
    });

    test('elements enregistres : COM-BR-12, sur chaque appel', () {
      final PortElementsEnregistres port = conteneur.read(
        portElementsEnregistresProvider,
      );
      expect(port.liste(), _indisponible('COM-BR-12'));
      expect(
        port.estEnregistre(_publication('p1')),
        _indisponible('COM-BR-12'),
      );
      expect(port.enregistrer(_publication('p1')), _indisponible('COM-BR-12'));
      expect(port.retirer(_publication('p1')), _indisponible('COM-BR-12'));
    });

    test('moderation : COM-BR-06, aucun signalement accepte en silence', () {
      final PortModeration port = conteneur.read(portModerationProvider);
      expect(port.capacites(), _indisponible('COM-BR-06'));
      expect(
        port.signaler(
          objet: _publication('p1'),
          motif: MotifSignalement.publicite,
        ),
        _indisponible('COM-BR-06'),
      );
      expect(port.file(), _indisponible('COM-BR-06'));
      expect(
        port.appliquer(signalementId: 's1', action: ActionModeration.masquer),
        _indisponible('COM-BR-06'),
      );
    });

    test('brouillons : memoire de session (V1), vide au depart', () async {
      expect(conteneur.read(portBrouillonsProvider), isA<BrouillonsMemoire>());
      expect(await conteneur.read(portBrouillonsProvider).tous(), isEmpty);
    });
  });

  group('BrouillonsMemoire', () {
    late DateTime horloge;
    late BrouillonsMemoire brouillons;
    const CleBrouillon fil1 = CleBrouillon(
      type: TypeObjetLie.message,
      objetId: 'fil-1',
    );
    const CleBrouillon fil2 = CleBrouillon(
      type: TypeObjetLie.message,
      objetId: 'fil-2',
    );
    const CleBrouillon canal1 = CleBrouillon(
      type: TypeObjetLie.canal,
      objetId: 'fil-1',
    );

    setUp(() {
      horloge = DateTime.utc(2026, 10, 4, 9);
      brouillons = BrouillonsMemoire(maintenant: () => horloge);
    });

    test('un brouillon survit et reste attache a son objet', () async {
      await brouillons.enregistrer(fil1, 'Bonjour');
      expect((await brouillons.lire(fil1))?.texte, 'Bonjour');
      expect(await brouillons.lire(fil2), isNull);
      // Meme identifiant, autre nature d'objet : autre brouillon.
      expect(await brouillons.lire(canal1), isNull);
    });

    test('un texte vide efface le brouillon', () async {
      await brouillons.enregistrer(fil1, 'Bonjour');
      await brouillons.enregistrer(fil1, '   ');
      expect(await brouillons.lire(fil1), isNull);
    });

    test('effacer, puis tous : le plus recent d abord', () async {
      await brouillons.enregistrer(fil1, 'Premier');
      horloge = horloge.add(const Duration(minutes: 1));
      await brouillons.enregistrer(fil2, 'Second');
      expect((await brouillons.tous()).map((Brouillon b) => b.texte), <String>[
        'Second',
        'Premier',
      ]);
      await brouillons.effacer(fil2);
      expect((await brouillons.tous()).map((Brouillon b) => b.texte), <String>[
        'Premier',
      ]);
      brouillons.vider();
      expect(await brouillons.tous(), isEmpty);
    });

    test('le provider oublie les brouillons d un autre compte', () async {
      final StreamController<SessionState> flux =
          StreamController<SessionState>.broadcast();
      addTearDown(flux.close);
      final _SourcePilotee source = _SourcePilotee(flux);
      final ProviderContainer conteneur = _conteneur(source);
      addTearDown(conteneur.dispose);
      final ProviderSubscription<PortBrouillons> abonnement = conteneur.listen(
        portBrouillonsProvider,
        (_, _) {},
      );
      addTearDown(abonnement.close);

      source.flux.add(const SessionState(resolue: true, profileId: 'compte-a'));
      await pumpEventQueue();
      final PortBrouillons premier = conteneur.read(portBrouillonsProvider);
      await premier.enregistrer(fil1, 'Texte du compte precedent');
      expect((await premier.lire(fil1))?.texte, 'Texte du compte precedent');

      source.flux.add(const SessionState(resolue: true, profileId: 'compte-b'));
      await pumpEventQueue();
      final PortBrouillons suivant = conteneur.read(portBrouillonsProvider);
      expect(identical(premier, suivant), isFalse);
      expect(await suivant.lire(fil1), isNull);
      // La memoire du compte precedent est videe, pas seulement remplacee.
      expect(await premier.lire(fil1), isNull);
    });

    test('le meme compte garde ses brouillons', () async {
      final StreamController<SessionState> flux =
          StreamController<SessionState>.broadcast();
      addTearDown(flux.close);
      final _SourcePilotee source = _SourcePilotee(flux);
      final ProviderContainer conteneur = _conteneur(source);
      addTearDown(conteneur.dispose);
      final ProviderSubscription<PortBrouillons> abonnement = conteneur.listen(
        portBrouillonsProvider,
        (_, _) {},
      );
      addTearDown(abonnement.close);

      source.flux.add(const SessionState(resolue: true, profileId: 'compte-a'));
      await pumpEventQueue();
      await conteneur.read(portBrouillonsProvider).enregistrer(fil1, 'Garde');
      source.flux.add(
        const SessionState(
          resolue: true,
          profileId: 'compte-a',
          lectureProfil: LectureProfil.presente,
        ),
      );
      await pumpEventQueue();
      expect(
        (await conteneur.read(portBrouillonsProvider).lire(fil1))?.texte,
        'Garde',
      );
    });
  });

  group('ElementsEnregistresMemoire (double de demonstration)', () {
    test('enregistre une reference, sans doublon, retire', () async {
      DateTime horloge = DateTime.utc(2026, 10, 4);
      final ElementsEnregistresMemoire port = ElementsEnregistresMemoire(
        maintenant: () => horloge,
      );
      await port.enregistrer(_publication('p1'));
      horloge = horloge.add(const Duration(minutes: 1));
      await port.enregistrer(_publication('p2'));
      await port.enregistrer(_publication('p1'));
      expect(
        (await port.liste()).map((ElementEnregistre e) => e.objet.id),
        <String>['p2', 'p1'],
      );
      expect(await port.estEnregistre(_publication('p1')), isTrue);
      await port.retirer(_publication('p1'));
      expect(await port.estEnregistre(_publication('p1')), isFalse);
    });
  });

  group('Moderation : les huit motifs de la section 5.5', () {
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.fr));
    tearDown(() => LocaleSettings.setLocaleSync(AppLocale.fr));

    test('huit motifs, dans l ordre de la spec, avec leur texte', () {
      expect(
        MotifSignalement.values.map((MotifSignalement m) => m.libelle),
        <String>[
          'Publicité',
          'Lien affilié',
          'Vente non autorisée',
          'Sollicitation commerciale',
          'Contenu sans rapport avec la communauté',
          'Harcèlement ou langage inapproprié',
          "Données personnelles d'un élève ou d'une famille",
          'Autre contenu à examiner',
        ],
      );
    });

    test(
      'chaque motif est traduit en arabe, sans retomber sur le francais',
      () async {
        final List<String> francais = MotifSignalement.values
            .map((MotifSignalement m) => m.libelle)
            .toList();
        await LocaleSettings.setLocale(AppLocale.ar);
        final List<String> arabe = MotifSignalement.values
            .map((MotifSignalement m) => m.libelle)
            .toList();
        expect(arabe.toSet(), hasLength(8));
        for (int i = 0; i < 8; i++) {
          expect(arabe[i], isNot(francais[i]));
        }
      },
    );

    test('les capacites decident des actions, jamais un role', () {
      expect(CapacitesModeration.aucune.voitLaFile, isFalse);
      expect(CapacitesModeration.aucune.peutSignaler, isFalse);
      final CapacitesModeration c = CapacitesModeration(
        peutSignaler: true,
        actions: const <ActionModeration>{ActionModeration.masquer},
      );
      expect(c.peut(ActionModeration.masquer), isTrue);
      expect(c.peut(ActionModeration.restaurer), isFalse);
      expect(c.voitLaFile, isTrue);
    });
  });

  group('i18n : le bloc com et ses six sous-blocs', () {
    Map<String, dynamic> lire(String langue) =>
        jsonDecode(File('assets/i18n/$langue.i18n.json').readAsStringSync())
            as Map<String, dynamic>;

    Map<String, String> aplatir(Map<String, dynamic> m, [String p = '']) =>
        <String, String>{
          for (final MapEntry<String, dynamic> e in m.entries)
            if (e.value is Map<String, dynamic>)
              ...aplatir(e.value as Map<String, dynamic>, '$p${e.key}.')
            else
              '$p${e.key}': e.value as String,
        };

    test('six sous-blocs, chacun avec au moins une cle, en fr et en ar', () {
      for (final String langue in <String>['fr', 'ar']) {
        final Map<String, dynamic> com =
            lire(langue)['com'] as Map<String, dynamic>;
        expect(com.keys, <String>[
          'socle',
          'messages',
          'vocal',
          'communaute',
          'studio',
          'annonces',
        ]);
        for (final String voie in com.keys) {
          expect(
            aplatir(com[voie] as Map<String, dynamic>),
            isNotEmpty,
            reason: '$langue $voie',
          );
        }
      }
    });

    test('memes cles en fr et en ar', () {
      final Map<String, String> fr = aplatir(
        lire('fr')['com'] as Map<String, dynamic>,
      );
      final Map<String, String> ar = aplatir(
        lire('ar')['com'] as Map<String, dynamic>,
      );
      expect(ar.keys.toSet(), fr.keys.toSet());
    });

    test('le lexique de la section 22 est present', () {
      LocaleSettings.setLocaleSync(AppLocale.fr);
      final Traductions$com$socle$lexique$fr l = t.com.socle.lexique;
      expect(
        <String>[
          l.messages,
          l.messagesMetier,
          l.communaute,
          l.studio,
          l.aujourdhui,
          l.notifications,
          l.annonce,
          l.publication,
          l.reponse,
          l.enregistrer,
          l.signaler,
          l.modeFocus,
          l.quitterFocus,
          l.aTraiter,
          l.actionRequise,
          l.brouillon,
          l.elementsEpingles,
          l.fichiersPartages,
        ],
        <String>[
          'Messages',
          'Messages métier',
          'Communauté enseignants',
          'Le Studio',
          "Aujourd'hui",
          'Notifications',
          'Annonce',
          'Publication',
          'Réponse',
          'Enregistrer',
          'Signaler',
          'Mode focus',
          'Quitter le focus',
          'À traiter',
          'Action requise',
          'Brouillon',
          'Éléments épinglés',
          'Fichiers partagés',
        ],
      );
    });
  });
}
