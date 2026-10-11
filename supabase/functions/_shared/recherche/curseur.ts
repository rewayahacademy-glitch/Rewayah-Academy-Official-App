export interface CurseurRecherche {
  readonly version: 1;
  readonly domaine: "classes";
  readonly sujet: string;
  readonly espace: string;
  readonly requeteTag: string;
  readonly apres: string;
  readonly expireLe: number;
}

export interface ChargeCurseurRecherche {
  readonly version: 1;
  readonly domaine: "classes";
  readonly sujet: string;
  readonly espace: string;
  readonly requete: string;
  readonly apres: string;
  readonly expireLe: number;
}

export interface ContexteCurseurRecherche {
  readonly version: 1;
  readonly domaine: "classes";
  readonly sujet: string;
  readonly espace: string;
  readonly requete: string;
}

const encodeur = new TextEncoder();
const UUID =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function base64url(bytes: Uint8Array): string {
  let binaire = "";
  for (const octet of bytes) binaire += String.fromCharCode(octet);
  return btoa(binaire).replaceAll("+", "-").replaceAll("/", "_").replace(
    /=+$/,
    "",
  );
}

function debase64url(valeur: string): Uint8Array {
  if (!/^[A-Za-z0-9_-]+$/.test(valeur)) throw new Error("base64url invalide");
  const base64 = valeur.replaceAll("-", "+").replaceAll("_", "/");
  const binaire = atob(base64 + "=".repeat((4 - base64.length % 4) % 4));
  return Uint8Array.from(binaire, (caractere) => caractere.charCodeAt(0));
}

async function cleHmac(secret: string): Promise<CryptoKey> {
  if (new TextEncoder().encode(secret).length < 32) {
    throw new Error("RECHERCHE_CURSOR_SECRET doit contenir au moins 32 octets");
  }
  return await crypto.subtle.importKey(
    "raw",
    encodeur.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

function chargeValide(charge: CurseurRecherche): boolean {
  return charge.version === 1 && charge.domaine === "classes" &&
    UUID.test(charge.sujet) && UUID.test(charge.apres) &&
    charge.espace.length > 0 && /^[A-Za-z0-9_-]{43}$/.test(charge.requeteTag) &&
    Number.isSafeInteger(charge.expireLe);
}

function requeteHmacInput(requete: string): Uint8Array {
  return encodeur.encode(`rewayah-search-cursor-v1\0${requete}`);
}

async function tagRequete(cle: CryptoKey, requete: string): Promise<string> {
  const entree = requeteHmacInput(requete);
  return base64url(
    new Uint8Array(
      await crypto.subtle.sign("HMAC", cle, entree.buffer as ArrayBuffer),
    ),
  );
}

export async function signerCurseur(
  charge: ChargeCurseurRecherche,
  secret: string,
): Promise<string> {
  if (
    charge.version !== 1 || charge.domaine !== "classes" ||
    !UUID.test(charge.sujet) || !UUID.test(charge.apres) ||
    charge.espace.length === 0 || charge.requete.length === 0 ||
    !Number.isSafeInteger(charge.expireLe)
  ) {
    throw new Error("charge de curseur invalide");
  }
  const cle = await cleHmac(secret);
  const chargeSignee: CurseurRecherche = {
    version: charge.version,
    domaine: charge.domaine,
    sujet: charge.sujet,
    espace: charge.espace,
    requeteTag: await tagRequete(cle, charge.requete),
    apres: charge.apres,
    expireLe: charge.expireLe,
  };
  const contenu = base64url(encodeur.encode(JSON.stringify(chargeSignee)));
  const signature = new Uint8Array(
    await crypto.subtle.sign("HMAC", cle, encodeur.encode(contenu)),
  );
  return `${contenu}.${base64url(signature)}`;
}

export async function lireCurseur(
  token: string,
  secret: string,
  contexte: ContexteCurseurRecherche,
  maintenantSecondes = Math.floor(Date.now() / 1000),
): Promise<CurseurRecherche | null> {
  try {
    if (token.length > 2048) return null;
    const parties = token.split(".");
    if (parties.length !== 2) return null;
    const [contenu, signature] = parties;
    const cle = await cleHmac(secret);
    if (
      !await crypto.subtle.verify(
        "HMAC",
        cle,
        debase64url(signature).buffer as ArrayBuffer,
        encodeur.encode(contenu),
      )
    ) return null;

    const brut: unknown = JSON.parse(
      new TextDecoder().decode(debase64url(contenu)),
    );
    if (typeof brut !== "object" || brut === null) return null;
    const charge = brut as CurseurRecherche;
    if (!chargeValide(charge) || charge.expireLe <= maintenantSecondes) {
      return null;
    }
    if (
      charge.version !== contexte.version ||
      charge.domaine !== contexte.domaine ||
      charge.sujet !== contexte.sujet || charge.espace !== contexte.espace
    ) return null;
    const entreeRequete = requeteHmacInput(contexte.requete);
    if (
      !await crypto.subtle.verify(
        "HMAC",
        cle,
        debase64url(charge.requeteTag).buffer as ArrayBuffer,
        entreeRequete.buffer as ArrayBuffer,
      )
    ) return null;
    return charge;
  } catch {
    return null;
  }
}
