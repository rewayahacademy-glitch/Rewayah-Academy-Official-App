import 'package:flutter_test/flutter_test.dart';
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
      expect(FournisseurVideo.depuis('quelque_chose_de_neuf'), FournisseurVideo.cloud);
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
}
