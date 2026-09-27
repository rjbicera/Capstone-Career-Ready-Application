/**
 * Cloud Function: Cleanup old resume analyses
 * Run daily via Cloud Scheduler
 * Keeps latest 50 analyses per user, deletes older than 1 year
 */

const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

const MAX_AGE_DAYS = 365;
const KEEP_LATEST = 50;

async function cleanupOldResumes() {
  const cutoff = new Date(Date.now() - MAX_AGE_DAYS * 24 * 60 * 60 * 1000);
  const usersSnapshot = await db.collection("users").get();

  let totalDeleted = 0;

  for (const userDoc of usersSnapshot.docs) {
    const uid = userDoc.id;
    const resumesRef = userDoc.ref.collection("resumes");

    // Get ALL resumes for this user, ordered newest first
    const allResumes = await resumesRef.orderBy("uploadedAt", "desc").get();

    if (allResumes.size <= KEEP_LATEST) continue; // User has ≤50, nothing to do

    // Identify candidates for deletion:
    // 1. Older than cutoff date
    // 2. Beyond the KEEP_LATEST threshold (i.e., index >= 50)
    const toDelete = [];

    allResumes.docs.forEach((doc, index) => {
      const data = doc.data();
      const uploadedAt = data.uploadedAt?.toDate?.() || new Date(data.uploadedAt);
      const isOld = uploadedAt < cutoff;
      const isBeyondKeepLimit = index >= KEEP_LATEST;

      if (isOld && isBeyondKeepLimit) {
        toDelete.push(doc.ref);
      }
    });

    if (toDelete.length === 0) continue;

    // Batch delete (max 500 per batch)
    for (let i = 0; i < toDelete.length; i += 500) {
      const batch = db.batch();
      const chunk = toDelete.slice(i, i + 500);
      chunk.forEach((ref) => batch.delete(ref));
      await batch.commit();
      totalDeleted += chunk.length;
    }

    console.log(`User ${uid}: deleted ${toDelete.length} old resume analyses`);
  }

  console.log(`Cleanup complete. Total deleted: ${totalDeleted}`);
  return { deleted: totalDeleted };
}

// For direct invocation (testing)
if (require.main === module) {
  cleanupOldResumes()
    .then((result) => {
      console.log("Result:", result);
      process.exit(0);
    })
    .catch((err) => {
      console.error("Cleanup failed:", err);
      process.exit(1);
    });
}

module.exports = { cleanupOldResumes };