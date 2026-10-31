// Journal d'audit : chaque action sensible, avec qui, quand, quoi, avant et après.
// Écrit uniquement par les Cloud Functions ; jamais modifiable ni supprimable
// (règles Firestore : aucune écriture côté client).

import { FieldValue, Transaction, getFirestore } from "firebase-admin/firestore";

export function ecrireAudit(
  tx: Transaction,
  acteurUid: string,
  action: string,
  cible: string,
  avant: string | null = null,
  apres: string | null = null,
): void {
  const ref = getFirestore().collection("audit").doc();
  tx.create(ref, { acteurUid, action, cible, avant, apres, date: FieldValue.serverTimestamp() });
}
