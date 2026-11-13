export const TAILLES_UPLOAD_BIBLIOTHEQUE = {
  image: 10 * 1024 * 1024,
  pdf: 50 * 1024 * 1024,
  audio: 100 * 1024 * 1024,
} as const;

/** La vignette d'un document (BIBLIOTHEQUE-UNE) : une image, 2 Mio au plus. */
export const TAILLE_VIGNETTE_MAX_OCTETS = 2 * 1024 * 1024;

const TYPES_IMAGES = new Set(["image/png", "image/jpeg", "image/webp"]);

/** Vrai pour une vignette annoncee : image png, jpeg ou webp, taille bornee. */
export function mimeVignetteAutorise(mime: string, taille: number): boolean {
  return Number.isSafeInteger(taille) && taille > 0 &&
    taille <= TAILLE_VIGNETTE_MAX_OCTETS && TYPES_IMAGES.has(mime);
}
const TYPES_AUDIO = new Set(["audio/mpeg", "audio/mp4", "audio/ogg"]);

export function mimeAnnonceAutorise(
  mime: string,
  taille: number,
  finalite: string,
): boolean {
  if (!Number.isSafeInteger(taille) || taille <= 0) return false;
  if (TYPES_IMAGES.has(mime)) {
    return taille <= TAILLES_UPLOAD_BIBLIOTHEQUE.image;
  }
  if (mime === "application/pdf") {
    return taille <= TAILLES_UPLOAD_BIBLIOTHEQUE.pdf;
  }
  return finalite === "support" && TYPES_AUDIO.has(mime) &&
    taille <= TAILLES_UPLOAD_BIBLIOTHEQUE.audio;
}

export function detecterMimeReel(octets: Uint8Array): string | null {
  if (
    octets.length >= 8 &&
    octets[0] === 0x89 && octets[1] === 0x50 && octets[2] === 0x4e &&
    octets[3] === 0x47 && octets[4] === 0x0d && octets[5] === 0x0a &&
    octets[6] === 0x1a && octets[7] === 0x0a
  ) return "image/png";
  if (
    octets.length >= 3 && octets[0] === 0xff && octets[1] === 0xd8 &&
    octets[2] === 0xff
  ) {
    return "image/jpeg";
  }
  if (
    octets.length >= 12 &&
    String.fromCharCode(...octets.slice(0, 4)) === "RIFF" &&
    String.fromCharCode(...octets.slice(8, 12)) === "WEBP"
  ) return "image/webp";
  if (
    octets.length >= 5 && String.fromCharCode(...octets.slice(0, 5)) === "%PDF-"
  ) {
    return "application/pdf";
  }
  if (
    octets.length >= 4 && String.fromCharCode(...octets.slice(0, 4)) === "OggS"
  ) {
    return "audio/ogg";
  }
  if (
    octets.length >= 8 && String.fromCharCode(...octets.slice(4, 8)) === "ftyp"
  ) {
    return "audio/mp4";
  }
  if (
    octets.length >= 3 && String.fromCharCode(...octets.slice(0, 3)) === "ID3"
  ) {
    return "audio/mpeg";
  }
  if (octets.length >= 2 && octets[0] === 0xff && (octets[1] & 0xe0) === 0xe0) {
    return "audio/mpeg";
  }
  return null;
}

export async function sha256Hex(octets: Uint8Array): Promise<string> {
  if (
    octets.buffer instanceof ArrayBuffer && octets.byteOffset === 0 &&
    octets.byteLength === octets.buffer.byteLength
  ) {
    const hash = await crypto.subtle.digest("SHA-256", octets.buffer);
    return Array.from(
      new Uint8Array(hash),
      (octet) => octet.toString(16).padStart(2, "0"),
    ).join("");
  }
  const copie = new ArrayBuffer(octets.byteLength);
  new Uint8Array(copie).set(octets);
  const hash = await crypto.subtle.digest("SHA-256", copie);
  return Array.from(
    new Uint8Array(hash),
    (octet) => octet.toString(16).padStart(2, "0"),
  ).join("");
}

// Une Map, pas un objet nu : `nomNeutre("constructor")` ne doit jamais rendre
// une propriete heritee du prototype.
const EXTENSIONS_NEUTRES: ReadonlyMap<string, string> = new Map([
  ["application/pdf", "pdf"],
  ["image/png", "png"],
  ["image/jpeg", "jpg"],
  ["image/webp", "webp"],
  ["audio/mpeg", "mp3"],
  ["audio/mp4", "m4a"],
  ["audio/ogg", "ogg"],
]);

/** Le nom de fichier qui entre dans la cle de stockage : fabrique par le
 * serveur depuis le type annonce, jamais repris du client. Un nom arabe, avec
 * un espace ou un accent ne peut donc plus faire refuser un depot (DEPOT-SIMPLE,
 * 13/11/2026), et aucun nom choisi par une personne ne voyage dans une cle.
 * `null` pour un type que le depot n'accepte pas. */
export function nomNeutre(mime: string): string | null {
  const extension = EXTENSIONS_NEUTRES.get(mime.trim().toLowerCase());
  return extension === undefined ? null : `document.${extension}`;
}

/** Vrai quand le type annonce est de ceux que le depot accepte, quelle que
 * soit la taille : sert a dire « trop lourd » plutot que « type refuse ». */
export function mimeConnu(mime: string, finalite: string): boolean {
  return TYPES_IMAGES.has(mime) || mime === "application/pdf" ||
    (finalite === "support" && TYPES_AUDIO.has(mime));
}

/** Le motif d'un refus de la base, lu dans le nom de l'exception : chaque
 * cause a sa reponse, pour que l'ecran dise la vraie (DEPOT-NOM-LIBRE, I2).
 *   - non_autorise   : le compte n'a pas le droit ;
 *   - non_modifiable : le document n'est plus un brouillon, ou est retire ;
 *   - deja_depose    : cette version a deja son fichier ;
 *   - expire         : la demande de depot a expire ou n'attend plus ;
 *   - invalide       : la base refuse les parametres ;
 *   - autre          : tout le reste (panne de base comprise). */
export type MotifRefus =
  | "non_autorise"
  | "non_modifiable"
  | "deja_depose"
  | "expire"
  | "invalide"
  | "autre";

export function motifRefus(
  erreur: { message?: string; code?: string } | null | undefined,
): MotifRefus {
  const message = erreur?.message ?? "";
  if (message.includes("BibliothequeUploadNonAutorise")) return "non_autorise";
  if (message.includes("BibliothequeBrouillonIntrouvable")) {
    return "non_modifiable";
  }
  if (message.includes("BibliothequeVersionDejaUnFichier")) {
    return "deja_depose";
  }
  if (message.includes("BibliothequeUploadIntentionIndisponible")) {
    return "expire";
  }
  if (
    message.includes("BibliothequeUploadParametresInvalides") ||
    message.includes("BibliothequeUploadTypeOuTailleInvalide") ||
    message.includes("BibliothequeUploadContenuInvalide")
  ) return "invalide";
  if (message.includes("BibliothequeIntrouvable")) return "non_modifiable";
  return "autre";
}

/** Le statut et le message d'un refus, par motif. Un compte sans droit lit
 * toujours un refus (403), jamais un reglage. */
export function reponseRefus(motif: MotifRefus): [string, number] {
  switch (motif) {
    case "non_autorise":
      return ["depot non autorise", 403];
    case "non_modifiable":
      return ["document non modifiable", 409];
    case "deja_depose":
      return ["fichier deja depose", 409];
    case "expire":
      return ["demande expiree", 410];
    case "invalide":
      return ["fichier invalide ou format non autorise", 400];
    case "autre":
      return ["depot impossible", 500];
  }
}
