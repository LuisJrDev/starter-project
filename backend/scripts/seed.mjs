// Seeds the `articles` collection and `media/articles` folder with sample data.
//
// It uses the Firebase *client* SDK on purpose: every write goes through the
// same security rules as the mobile app, so a successful seed is also a smoke
// test of `firestore.rules` and `storage.rules`.
//
// Usage: npm run seed:emulator   (requires `npm run emulators` in another shell)
//
// Schema: see ../docs/DB_SCHEMA.md

import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp } from 'firebase/app';
import {
  collection,
  connectFirestoreEmulator,
  doc,
  getFirestore,
  serverTimestamp,
  setDoc,
  terminate,
} from 'firebase/firestore';
import {
  connectStorageEmulator,
  deleteObject,
  getDownloadURL,
  getStorage,
  ref,
  uploadBytes,
} from 'firebase/storage';

const PROJECT_ID = 'backend-news-symmetry';
const SEED_DATA_DIR = path.join(path.dirname(fileURLToPath(import.meta.url)), 'seed-data');
const DESCRIPTION_MAX_LENGTH = 300;
const CONTENT_TYPE_BY_EXTENSION = {
  '.jpg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

const TARGETS = {
  emulator: {
    firebaseConfig: {
      apiKey: 'emulator-fake-api-key',
      projectId: PROJECT_ID,
      storageBucket: `${PROJECT_ID}.firebasestorage.app`,
    },
    connectToEmulators(firestore, storage) {
      connectFirestoreEmulator(firestore, '127.0.0.1', 8080);
      connectStorageEmulator(storage, '127.0.0.1', 9199);
    },
  },
};

function readTargetName() {
  const argument = process.argv.find((arg) => arg.startsWith('--target='));
  const targetName = argument?.split('=')[1] ?? 'emulator';
  if (!TARGETS[targetName]) {
    throw new Error(`Unknown target "${targetName}". Available: ${Object.keys(TARGETS).join(', ')}`);
  }
  return targetName;
}

function connectToTarget(target) {
  const app = initializeApp(target.firebaseConfig);
  const firestore = getFirestore(app);
  const storage = getStorage(app);
  target.connectToEmulators?.(firestore, storage);
  return { firestore, storage };
}

async function readSeedArticles() {
  const json = await readFile(path.join(SEED_DATA_DIR, 'articles.json'), 'utf8');
  return JSON.parse(json);
}

// Mirrors the derivation rule of the domain entity in the Flutter app:
// strip Markdown syntax, collapse whitespace, keep the first 300 characters.
function deriveDescription(markdown) {
  const plainText = markdown
    .replace(/^\s{0,3}(#{1,6}|>|[-*+]|\d+\.)\s+/gm, '')
    .replace(/(\*\*|__|\*|_|~~|`)/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  return plainText.slice(0, DESCRIPTION_MAX_LENGTH);
}

async function uploadThumbnail(storage, articleId, imageFileName) {
  const extension = path.extname(imageFileName).toLowerCase();
  const thumbnailRef = ref(storage, `media/articles/${articleId}${extension}`);
  const bytes = await readFile(path.join(SEED_DATA_DIR, 'images', imageFileName));
  await uploadBytes(thumbnailRef, bytes, { contentType: CONTENT_TYPE_BY_EXTENSION[extension] });
  return thumbnailRef;
}

function buildArticleDocument(seedArticle, thumbnailURL) {
  return {
    title: seedArticle.title,
    content: seedArticle.content,
    description: deriveDescription(seedArticle.content),
    author: seedArticle.author,
    thumbnailURL,
    publishedAt: serverTimestamp(),
  };
}

async function writeArticleOrRemoveThumbnail(articleRef, articleDocument, thumbnailRef) {
  try {
    await setDoc(articleRef, articleDocument);
  } catch (error) {
    await deleteObject(thumbnailRef);
    throw error;
  }
}

async function publishSeedArticle({ firestore, storage }, seedArticle) {
  const articleRef = doc(collection(firestore, 'articles'));
  const thumbnailRef = await uploadThumbnail(storage, articleRef.id, seedArticle.image);
  const thumbnailURL = await getDownloadURL(thumbnailRef);
  await writeArticleOrRemoveThumbnail(articleRef, buildArticleDocument(seedArticle, thumbnailURL), thumbnailRef);
  console.log(`✔ articles/${articleRef.id}  "${seedArticle.title}"`);
}

async function main() {
  const targetName = readTargetName();
  const connection = connectToTarget(TARGETS[targetName]);
  console.log(`Seeding ${targetName} (${PROJECT_ID})...`);
  for (const seedArticle of await readSeedArticles()) {
    await publishSeedArticle(connection, seedArticle);
  }
  await terminate(connection.firestore);
}

main().catch((error) => {
  console.error(`✘ Seed failed: ${error.code ?? ''} ${error.message}`);
  process.exit(1);
});
