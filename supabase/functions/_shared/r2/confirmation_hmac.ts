const encoder = new TextEncoder();

/** Domain prefix of a thumbnail confirmation (BIBLIOTHEQUE-UNE, review I7).
 * The signed message of a document file has no prefix; a thumbnail's carries
 * this one, written identically in `confirmer_vignette_bibliotheque`. A
 * signature made for one therefore cannot confirm the other. */
export const DOMAINE_VIGNETTE = "bibliotheque-vignette-v1";

/** HMAC bound to the server-created intent, verified again by the database.
 * `domaine`, when given, is the first line of the signed message. */
export async function signatureConfirmationUpload(
  secret: string,
  intentionId: string,
  sha256: string,
  size: number,
  domaine?: string,
): Promise<string> {
  if (
    encoder.encode(secret).byteLength < 32 || secret.trim() !== secret ||
    !/^[0-9a-f-]{36}$/i.test(intentionId) ||
    !/^[0-9a-f]{64}$/i.test(sha256) ||
    !Number.isSafeInteger(size) || size <= 0
  ) {
    throw new Error("confirmation signing input invalid");
  }

  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const corps = `${intentionId.toLowerCase()}\n${sha256.toLowerCase()}\n${size}`;
  const canonical = domaine === undefined ? corps : `${domaine}\n${corps}`;
  const mac = await crypto.subtle.sign("HMAC", key, encoder.encode(canonical));
  return Array.from(new Uint8Array(mac), (byte) =>
    byte.toString(16).padStart(2, "0")
  ).join("");
}
