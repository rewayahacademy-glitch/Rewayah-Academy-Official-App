import {
  assertEquals,
  assertNotEquals,
  assertRejects,
} from "jsr:@std/assert";
import {
  DOMAINE_VIGNETTE,
  signatureConfirmationUpload,
} from "./confirmation_hmac.ts";

Deno.test("confirmation HMAC binds intent, hash and size", async () => {
  const secret = "test-only-confirmation-secret-32-bytes-minimum";
  const signature = await signatureConfirmationUpload(
    secret,
    "aaaaaaaa-0000-0000-0000-000000000001",
    "b".repeat(64),
    1234,
  );

  assertEquals(signature.length, 64);
  assertNotEquals(
    signature,
    await signatureConfirmationUpload(
      secret,
      "aaaaaaaa-0000-0000-0000-000000000002",
      "b".repeat(64),
      1234,
    ),
  );
  assertNotEquals(
    signature,
    await signatureConfirmationUpload(
      secret,
      "aaaaaaaa-0000-0000-0000-000000000001",
      "c".repeat(64),
      1234,
    ),
  );
  assertNotEquals(
    signature,
    await signatureConfirmationUpload(
      secret,
      "aaaaaaaa-0000-0000-0000-000000000001",
      "b".repeat(64),
      1235,
    ),
  );
});

Deno.test("confirmation HMAC rejects short secrets and malformed data", async () => {
  await assertRejects(() =>
    signatureConfirmationUpload(
      "short",
      "aaaaaaaa-0000-0000-0000-000000000001",
      "b".repeat(64),
      1234,
    )
  );
  await assertRejects(() =>
    signatureConfirmationUpload(
      "test-only-confirmation-secret-32-bytes-minimum",
      "not-an-id",
      "b".repeat(64),
      1234,
    )
  );
});

Deno.test("a thumbnail signature never equals a file signature (domain separation)", async () => {
  const secret = "test-only-confirmation-secret-32-bytes-minimum";
  const id = "aaaaaaaa-0000-0000-0000-000000000001";
  const fichier = await signatureConfirmationUpload(secret, id, "b".repeat(64), 1234);
  const vignette = await signatureConfirmationUpload(
    secret,
    id,
    "b".repeat(64),
    1234,
    DOMAINE_VIGNETTE,
  );
  assertEquals(vignette.length, 64);
  assertNotEquals(fichier, vignette);
  // Same domain, same input: stable.
  assertEquals(
    vignette,
    await signatureConfirmationUpload(secret, id, "b".repeat(64), 1234, DOMAINE_VIGNETTE),
  );
});
