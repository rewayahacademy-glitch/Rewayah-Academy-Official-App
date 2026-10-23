// Les libelles des adaptateurs Supabase des Communications (COM-BACK-1),
// lus dans slang au moment de l'appel : la langue courante de l'application
// nomme les donnees rendues par le serveur, en francais comme en arabe.
//
// Aucun libelle nouveau : chaque mot reprend une cle deja traduite.

import '../i18n/strings.g.dart';
import 'communications_supabase.dart';
import 'modeles_communication.dart';

/// Les libelles de communication tires des traductions de l'application.
class LibellesCommunicationSlang implements LibellesCommunication {
  /// Cree les libelles ; ils lisent la langue courante a chaque appel.
  const LibellesCommunicationSlang();

  @override
  String classe(String libelle) =>
      t.admin.groupes.detailTitre(libelle: libelle);

  @override
  String administration() => t.controleur.echanges.auteurAdmin;

  @override
  String famille() => t.com.messages.demo.roles.tuteur;

  @override
  String enseignant({required String prenom, String? nom, String? titre}) =>
      switch (titre) {
        'sayid' || 'sayyid' => '${t.tc.groupe.enseignant.sayyid} $prenom',
        'sayyida' => '${t.tc.groupe.enseignant.sayyida} $prenom',
        _ => prenom,
      };

  @override
  String objet(TypeObjetLie type) => switch (type) {
    TypeObjetLie.classe => t.com.messages.types.classe,
    TypeObjetLie.eleve => t.com.messages.types.eleve,
    TypeObjetLie.dossier => t.com.messages.types.dossier,
    TypeObjetLie.mission => t.com.messages.types.mission,
    TypeObjetLie.remplacement => t.com.messages.types.remplacement,
    TypeObjetLie.profilPaiement => t.com.messages.types.profilPaiement,
    _ => t.com.messages.types.autre,
  };

  @override
  String publicAnnonce(String code) => switch (code) {
    'familles' => t.com.annonces.demoPublication.familles,
    'enseignants' => t.com.annonces.demoPublication.enseignants,
    _ => t.com.annonces.demoPublication.toutes,
  };
}
