// FN-101 (parcours 1, piege 1.12, 31/10/2026) : un fichier de 53 octets de
// texte, nomme `.pdf`, passait pour une piece d'identite et entrait dans la
// file de validation.
//
// Le meme controle que le serveur (`supabase/functions/_shared/r2/
// contenu_piece.ts`, decision de la direction du 03/11/2026, option a) : les
// premiers octets du fichier sont compares a la signature de son type, deduit
// de l'extension. Ici, avant l'envoi : la personne apprend tout de suite que
// le fichier ne convient pas, au lieu d'attendre une validation qui ne
// viendra pas.
//
// Ce controle n'est pas une barriere : un client se contourne. La barriere est
// cote serveur (la liste fermee du seau `kyc`, migration 20261108400000, et la
// lecture des 16 premiers octets de `piece-identite-confirme`). Il ne pretend
// pas prouver qu'une image est lisible ; il ferme le cas grossier (un texte,
// un fichier vide ou d'un autre type renomme).

import 'dart:typed_data';

/// Marques HEIF acceptees a l'offset 8 d'une boite `ftyp`, comme le serveur.
const Set<String> _marquesHeif = <String>{'heic', 'heix', 'heif', 'mif1'};

bool _commencePar(Uint8List octets, List<int> attendu, [int decalage = 0]) {
  if (octets.length < decalage + attendu.length) {
    return false;
  }
  for (int i = 0; i < attendu.length; i++) {
    if (octets[decalage + i] != attendu[i]) {
      return false;
    }
  }
  return true;
}

String _ascii(Uint8List octets, int debut, int fin) =>
    octets.length < fin ? '' : String.fromCharCodes(octets.sublist(debut, fin));

/// Vrai quand les premiers octets de [octets] correspondent au type annonce
/// par [extension] (minuscules, sans point). Une extension hors de la liste
/// de `SelecteurFichierNatif.extensionsAcceptees` rend faux. Fonction pure.
bool contenuPieceConforme(String extension, Uint8List octets) {
  switch (extension.toLowerCase()) {
    case 'pdf':
      // %PDF
      return _commencePar(octets, const <int>[0x25, 0x50, 0x44, 0x46]);
    case 'jpg':
    case 'jpeg':
      return _commencePar(octets, const <int>[0xff, 0xd8, 0xff]);
    case 'png':
      return _commencePar(octets, const <int>[
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
      ]);
    case 'heic':
      return _ascii(octets, 4, 8) == 'ftyp' &&
          _marquesHeif.contains(_ascii(octets, 8, 12));
    case 'webp':
      // RIFF, quatre octets de taille, puis WEBP. Le seau `kyc` accepte le
      // WebP (20261108400000) ; le controle serveur ne le connait pas encore
      // (ecart note par le garde-cap le 03/11, a trancher par N4).
      return _ascii(octets, 0, 4) == 'RIFF' && _ascii(octets, 8, 12) == 'WEBP';
    default:
      return false;
  }
}
