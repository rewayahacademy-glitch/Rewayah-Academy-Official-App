export const TAILLES_UPLOAD_BIBLIOTHEQUE = {
  image: 10 * 1024 * 1024,
  pdf: 50 * 1024 * 1024,
  audio: 100 * 1024 * 1024,
} as const;

const TYPES_IMAGES = new Set(["image/png", "image/jpeg", "image/webp"]);
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
