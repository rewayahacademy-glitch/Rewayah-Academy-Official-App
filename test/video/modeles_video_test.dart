import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/video/livekit_session_provider.dart';
import 'package:rewayah_academy/core/video/pre_vol.dart';
import 'package:rewayah_academy/core/video/video_session_provider.dart';

/// La reponse complete de `create-room-token`, telle que la fonction Edge la
/// rend reellement -- les noms de champs viennent de `autoriser_jeton_video()`,
/// pas d'une invention de ce test.
Map<String, dynamic> _reponse({
  String fournisseur = 'cloud',
  bool publier = true,
  bool video = true,
  bool donnees = false,
  bool invisible = false,
}) => <String, dynamic>{
  'ws_url': 'wss://exemple.invalid',
  'token': 'jeton.signe.par.le.backend',
  'room_name': 'r_0123456789abcdef0123456789abcdef',
  'provider': fournisseur,
  'role': 'student',
  'expire_le': '2026-09-12T18:30:00.000Z',
  'capabilities': <String, dynamic>{
    'can_publish': publier,
    'can_publish_video': video,
    'can_publish_data': donnees,
    'can_subscribe': true,
    'hidden': invisible,
  },
};

void main() {
  group('AccesSalle', () {
    test('lit la reponse du backend sans rien reinterpreter', () {
      final AccesSalle acces = AccesSalle.depuisJson(_reponse());

      expect(acces.urlServeur, 'wss://exemple.invalid');
      expect(acces.jeton, 'jeton.signe.par.le.backend');
      expect(acces.nomSalle, 'r_0123456789abcdef0123456789abcdef');
      expect(acces.fournisseur, FournisseurVideo.cloud);
      expect(acces.role, 'student');
      expect(acces.capacites.peutPublier, isTrue);
    });

    test('le nom de salle ne porte aucune donnee personnelle', () {
      // Section 10 de la specification : un nom de room opaque. Le backend le
      // derive du `session_id` par sha256 ; ce test verrouille la forme, pour
      // que personne ne « simplifie » un jour en y mettant le nom de l'eleve.
      final AccesSalle acces = AccesSalle.depuisJson(_reponse());
      expect(acces.nomSalle, matches(RegExp(r'^r_[0-9a-f]{32}$')));
    });

    test('reconnait le serveur auto-heberge', () {
      final AccesSalle acces = AccesSalle.depuisJson(
        _reponse(fournisseur: 'self_hosted'),
      );
      expect(acces.fournisseur, FournisseurVideo.autoHeberge);
    });

    test('un fournisseur inconnu retombe sur le Cloud, jamais sur rien', () {
      // Le jour ou un troisieme fournisseur apparaitra cote serveur, une
      // application non mise a jour doit continuer de fonctionner plutot que
      // de lever. Le Cloud est le repli sur, c'est lui qui fournit TURN.
      expect(
        FournisseurVideo.depuis('quelque_chose_de_neuf'),
        FournisseurVideo.cloud,
      );
      expect(FournisseurVideo.depuis(null), FournisseurVideo.cloud);
    });
  });

  group('CapacitesSalle, les defauts sont surs', () {
    test('une capacite absente vaut faux, jamais vrai', () {
      // **C'est le test le plus important du fichier.** Si une reponse
      // tronquee -- backend d'une version anterieure, champ renomme, reponse
      // partielle -- se lisait comme « tout est permis », un eleve dont la
      // politique camera vaut `forbidden` publierait son image. Le defaut doit
      // etre le refus.
      final CapacitesSalle vides = CapacitesSalle.depuisJson(
        const <String, dynamic>{},
      );

      expect(vides.peutPublier, isFalse);
      expect(vides.peutPublierVideo, isFalse);
      expect(vides.peutPublierDonnees, isFalse);
      expect(vides.invisible, isFalse);
    });

    test('la reception, elle, est ouverte par defaut', () {
      // Le seul defaut permissif, et il est sans risque : ne pas recevoir
      // reviendrait a entrer dans une salle vide. Aucune donnee ne sort.
      final CapacitesSalle vides = CapacitesSalle.depuisJson(
        const <String, dynamic>{},
      );
      expect(vides.peutRecevoir, isTrue);
    });

    test('un eleve sans camera garde la voix', () {
      final AccesSalle acces = AccesSalle.depuisJson(_reponse(video: false));
      expect(acces.capacites.peutPublier, isTrue);
      expect(acces.capacites.peutPublierVideo, isFalse);
    });

    test('seul l enseignant diffuse des donnees', () {
      final AccesSalle eleve = AccesSalle.depuisJson(_reponse());
      final AccesSalle enseignant = AccesSalle.depuisJson(
        _reponse(donnees: true),
      );
      expect(eleve.capacites.peutPublierDonnees, isFalse);
      expect(enseignant.capacites.peutPublierDonnees, isTrue);
    });

    test('le controleur de CTR-02 est invisible et muet', () {
      final AccesSalle controleur = AccesSalle.depuisJson(
        _reponse(publier: false, video: false, invisible: true),
      );
      expect(controleur.capacites.invisible, isTrue);
      expect(controleur.capacites.peutPublier, isFalse);
      expect(controleur.capacites.peutPublierVideo, isFalse);
      expect(controleur.capacites.peutRecevoir, isTrue);
    });
  });

  group('ResultatPreVol', () {
    test('le micro suffit pour entrer : audio avant video', () {
      // ADR-001 et section 17 : pour une academie de Coran, la recitation
      // prime sur l'image. Exiger la camera fermerait la salle a tous les
      // eleves mineurs, dont la politique camera vaut `forbidden` par defaut.
      const ResultatPreVol sansCamera = ResultatPreVol(
        microDisponible: true,
        cameraDisponible: false,
        sortieAudioDisponible: true,
        permissionRefusee: false,
      );
      expect(sansCamera.peutEntrer, isTrue);
    });

    test('sans micro, la seance n a pas de sens', () {
      const ResultatPreVol sansMicro = ResultatPreVol(
        microDisponible: false,
        cameraDisponible: true,
        sortieAudioDisponible: true,
        permissionRefusee: false,
      );
      expect(sansMicro.peutEntrer, isFalse);
    });

    test('une permission refusee bloque, meme micro present', () {
      // Le cas reel : le navigateur a enumere un micro, mais l'usager a refuse
      // l'acces. Entrer quand meme produirait une salle ou l'on est muet sans
      // savoir pourquoi -- exactement ce que le pre-vol doit eviter.
      const ResultatPreVol refus = ResultatPreVol(
        microDisponible: true,
        cameraDisponible: true,
        sortieAudioDisponible: true,
        permissionRefusee: true,
      );
      expect(refus.peutEntrer, isFalse);
    });

    test('une sortie audio absente ne bloque pas', () {
      // Sur le web la liste des sorties est souvent vide alors que le son
      // marche : le navigateur ne l'expose qu'apres accord. En faire un
      // bloquant fermerait la salle a tort.
      const ResultatPreVol sansSortie = ResultatPreVol(
        microDisponible: true,
        cameraDisponible: true,
        sortieAudioDisponible: false,
        permissionRefusee: false,
      );
      expect(sansSortie.peutEntrer, isTrue);
    });
  });

  group('ContenuPresente, un pointeur et rien de plus', () {
    final ContenuPresente ayatAlKursi = ContenuPresente(
      page: 42,
      sourate: 2,
      verset: 255,
      presentePar: 't1',
      emisLe: DateTime.fromMillisecondsSinceEpoch(1758300000000, isUtc: true),
    );

    test('il ne porte AUCUN texte de verset', () {
      // **Le test le plus important du groupe** (invariant J6) : le jour ou
      // quelqu'un ajoutera le texte au paquet pour « eviter un aller-retour »,
      // le Coran deviendra une donnee de transport, et une edition figee
      // voyagera de client en client. Ce que le paquet porte est une ADRESSE.
      final Map<String, dynamic> paquet = ayatAlKursi.versJson();
      expect(paquet.keys.toSet(), <String>{'p', 's', 'v', 'q', 't'});
      // La seule chaine du paquet est l'identite du presentateur. Tout le reste
      // est numerique : une adresse, jamais un contenu.
      expect(paquet['q'], 't1');
      expect(
        paquet.values.whereType<String>().length,
        1,
        reason: 'une seule chaine, et c est l identite',
      );
    });

    test('il survit a l aller-retour JSON sans rien perdre', () {
      final Object? decode = jsonDecode(jsonEncode(ayatAlKursi.versJson()));
      final ContenuPresente relu = ContenuPresente.depuisJson(
        decode! as Map<String, dynamic>,
      );

      expect(relu.page, 42);
      expect(relu.sourate, 2);
      expect(relu.verset, 255);
      expect(relu.presentePar, 't1');
      expect(relu.reference, '2:255');
      // L'horodatage voyage en UTC et revient a l'heure locale : c'est lui qui
      // permet de ne pas reculer d'une page quand deux paquets se croisent.
      expect(
        relu.emisLe.toUtc().millisecondsSinceEpoch,
        ayatAlKursi.emisLe.toUtc().millisecondsSinceEpoch,
      );
    });

    test('le paquet reste court : il part a chaque tour de page', () {
      // Cinq ou six appareils, dont certains en 3G. Les cles d'une lettre ne
      // sont pas une coquetterie, elles sont la moitie du paquet.
      expect(jsonEncode(ayatAlKursi.versJson()).length, lessThan(96));
    });

    test('un paquet tronque ouvre la premiere page, il ne leve pas', () {
      // Il vient du reseau, donc d'une version d'application qu'on ne controle
      // pas. Une exception ici couperait le canal pour toute la seance.
      final ContenuPresente vide = ContenuPresente.depuisJson(
        const <String, dynamic>{},
      );
      expect(vide.page, 1);
      expect(vide.reference, '1:1');
      expect(vide.presentePar, isEmpty);
    });
  });

  test('revue PR 54 : le refus de camera d une seance est oublie a la '
      'sortie, donc avant l entree suivante', () async {
    final LiveKitSessionProvider moteur = LiveKitSessionProvider()
      ..erreurCameraEntreePourTest = 'NotAllowedError: Permission denied';
    expect(moteur.erreurCameraEntree, isNotNull);
    await moteur.quitter();
    expect(moteur.erreurCameraEntree, isNull);
  });

  group('Le moteur refuse de presenter sans jeton qui l autorise', () {
    test('hors salle, presenter ne fait rien et ne leve pas', () async {
      // Le refus est SILENCIEUX : lever obligerait chaque appelant a rattraper
      // une exception qui ne dirait rien de plus que ses capacites.
      final LiveKitSessionProvider moteur = LiveKitSessionProvider();

      final List<ContenuPresente> recus = <ContenuPresente>[];
      final StreamSubscription<ContenuPresente> abonnement = moteur
          .contenusPresentes
          .listen(recus.add);

      await moteur.presenterContenu(
        ContenuPresente(
          page: 1,
          sourate: 1,
          verset: 1,
          presentePar: 'e1',
          emisLe: DateTime.now(),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // Annule DANS le corps, jamais par `addTearDown` : attendre un `cancel`
      // apres la sortie du test bloque sans message des que la zone de temps est
      // simulee (mesure le 20 septembre 2026 sur `salle_test.dart`).
      await abonnement.cancel();
      await moteur.liberer();

      expect(recus, isEmpty);
    });
  });
}
