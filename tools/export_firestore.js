/**
 * Export the Firestore `recipes` collection to recipes.json.
 *
 *   cd tools
 *   npm install firebase-admin
 *   node export_firestore.js
 *
 * Needs serviceAccountKey.json IN THIS FOLDER:
 *   Firebase console -> Project settings -> Service accounts
 *   -> Generate new private key -> rename to serviceAccountKey.json
 *
 * Uses the modular firebase-admin API (v10+). The older
 * `admin.credential.cert(...)` namespace style no longer works on v13+.
 */
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const KEY_PATH = path.join(__dirname, 'serviceAccountKey.json');
if (!fs.existsSync(KEY_PATH)) {
  console.error('serviceAccountKey.json not found in tools/.');
  console.error('Firebase console -> Project settings -> Service accounts -> Generate new private key');
  process.exit(1);
}

initializeApp({ credential: cert(require(KEY_PATH)) });

const COLLECTION = process.env.COLLECTION || 'recipes';

(async () => {
  try {
    const snap = await getFirestore().collection(COLLECTION).get();
    if (snap.empty) {
      console.error(`Collection "${COLLECTION}" is empty or does not exist.`);
      console.error('Set a different name with:  set COLLECTION=yourName  (PowerShell: $env:COLLECTION="yourName")');
      process.exit(1);
    }
    const rows = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    fs.writeFileSync(path.join(__dirname, 'recipes.json'), JSON.stringify(rows, null, 2));
    console.log(`Exported ${rows.length} documents from "${COLLECTION}" -> tools/recipes.json`);
    console.log('Sample keys:', Object.keys(rows[0]).join(', '));
    process.exit(0);
  } catch (e) {
    console.error('Export failed:', e.message);
    process.exit(1);
  }
})();
