// MINEUR-FANTOME (06/11/2026) : la meme comparaison que creer_profil_enfant
// (20261110340000), et les deux refus nouveaux reconnus par le client.

import 'package:flutter_test/flutter_test.dart';
import 'package:rewayah_academy/core/foyer/port_creation_profil_eleve.dart';
import 'package:rewayah_academy/core/foyer/profil_eleve_brouillon.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FunctionException;

void main() {
  test('nomCompare : casse, accents latins et espaces doubles ignores', () {
    expect(nomCompare('  AMÎNA ', 'diallo'), nomCompare('Amina', 'Diallo'));
    expect(nomCompare('Zoé', 'Le  Gall'), 'zoe le gall');
    expect(nomCompare('Yanis', 'Diallo'), isNot(nomCompare('Amina', 'Diallo')));
    // L'arabe reste tel quel, seuls les espaces se resserrent.
    expect(nomCompare('أمينة', 'ديالو'), 'أمينة ديالو');
  });

  test('borne haute 17 ans : un profil cree ici est un mineur', () {
    expect(BornesAge.clientActuelle.contient(17), isTrue);
    expect(BornesAge.clientActuelle.contient(18), isFalse);
    expect(BornesAge.clientActuelle.contient(6), isTrue);
  });

  ResultatCreationProfil refus(String message) => resultatDepuisRefus(
    FunctionException(status: 403, details: <String, String>{'error': message}),
  );

  test('refus du serveur reconnus', () {
    expect(
      (refus(
        'profil du titulaire : ce prenom et ce nom sont ceux du titulaire',
      ) as CreationRefusee).motif,
      MotifRefusCreation.titulaire,
    );
    expect(
      (refus(
        'age adulte : un profil eleve de 18 ans ou plus ne se cree pas ici',
      ) as CreationRefusee).motif,
      MotifRefusCreation.adulte,
    );
    expect(
      (refus('age hors bornes') as CreationRefusee).motif,
      MotifRefusCreation.ageHorsBornes,
    );
  });
}
