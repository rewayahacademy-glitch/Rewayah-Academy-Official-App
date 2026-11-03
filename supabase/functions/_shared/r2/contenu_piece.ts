// Le contenu d'une piece d'identite deposee ressemble-t-il au type signe ?
//
// Decision de la direction (garde-cap, 03/11/2026, option a) : a la
// confirmation d'un depot, le serveur lit AU PLUS les 16 premiers octets de
// l'objet et les compare a la signature du type qui a ete signe au depot. Un
// fichier qui annonce `application/pdf` mais ne commence pas par `%PDF` n'entre
// pas dans la file de validation : la reservation reste non confirmee.
//
// Ce module ne fait aucun appel reseau et ne garde rien : il recoit au plus
// 16 octets et rend un booleen. Les octets ne sont ni conserves, ni journalises,
// ni renvoyes ; aucune fonction ici ne les copie ailleurs que dans sa pile.
//
// Ce que ce controle ne pretend PAS faire : prouver qu'un fichier est un PDF
// valide ou une image lisible. Il ferme le cas grossier (un texte, un
// executable, un fichier vide renomme) que la signature du type ne fermait pas,
// parce que R2 verifie l'en-tete annonce, jamais le contenu.

/// Nombre maximal d'octets lus en tete d'objet. Borne ecrite dans la decision.
export const OCTETS_ENTETE = 16

/// Marques HEIF acceptees a l'offset 8 d'un `ftyp`.
///
/// `heic` et `heix` sont les marques des photos HEIC (iPhone et Android) ;
/// `heif` est demandee par la decision ; `mif1` est la marque generique d'une
/// image HEIF, que certains appareils posent en marque majeure. Les marques
/// compatibles commencent a l'octet 16, hors de la fenetre lue : seule la marque
/// majeure compte.
const MARQUES_HEIF: readonly string[] = ['heic', 'heix', 'heif', 'mif1']

function commencePar(octets: Uint8Array, attendu: readonly number[], decalage = 0): boolean {
  if (octets.length < decalage + attendu.length) {
    return false
  }
  return attendu.every((valeur, i) => octets[decalage + i] === valeur)
}

function ascii(octets: Uint8Array, debut: number, fin: number): string {
  if (octets.length < fin) {
    return ''
  }
  return String.fromCharCode(...octets.subarray(debut, fin))
}

/// Vrai quand les premiers octets correspondent au type de contenu signe.
///
/// `typeSigne` est le `Content-Type` que R2 rend pour l'objet : c'est celui qui
/// a ete signe au depot, puisque R2 refuse un envoi dont l'en-tete differe de
/// la signature. Un type hors de la liste fermee rend faux.
export function contenuConforme(typeSigne: string | null, octets: Uint8Array): boolean {
  const type = (typeSigne ?? '').split(';')[0].trim().toLowerCase()
  switch (type) {
    case 'application/pdf':
      // %PDF
      return commencePar(octets, [0x25, 0x50, 0x44, 0x46])
    case 'image/jpeg':
      return commencePar(octets, [0xff, 0xd8, 0xff])
    case 'image/png':
      // 89 50 4E 47 0D 0A 1A 0A : les huit octets de la signature PNG.
      return commencePar(octets, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    case 'image/heic':
      // Boite `ftyp` a l'offset 4, marque majeure a l'offset 8.
      return ascii(octets, 4, 8) === 'ftyp' && MARQUES_HEIF.includes(ascii(octets, 8, 12))
    default:
      return false
  }
}
