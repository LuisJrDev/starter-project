# Firebase Firestore Backend
In this folder are all the [Firebase Firestore](https://firebase.google.com/docs/firestore) related files. 
You will use this folder to add the schema of the *Articles* you want to upload for the app and to add the rules that enforce this schema. 

## DB Schema
The full schema (Firestore collection `articles` and Cloud Storage folder `media/articles`) is documented in [docs/DB_SCHEMA.md](./docs/DB_SCHEMA.md).

## Getting Started
Before starting to work on the backend, you must have a Firebase project with the [Firebase Firestore](https://firebase.google.com/docs/firestore), [Firebase Cloud Storage](https://firebase.google.com/docs/storage) and [Firebase Local Emulator Suite](https://firebase.google.com/docs/emulator-suite) technologies enabled.
To do this, create a project but enable only Firebase Cloud Storage, Firebase Firestore, and Firebase Local Emulator Suite technologies.

### Production requirements for Cloud Storage
These two steps are not needed for the emulators, only for a real Firebase project:

1. **Blaze plan.** Default buckets (`{projectId}.firebasestorage.app`) are only accessible on
   the pay-as-you-go Blaze plan. A project on the free Spark plan gets `storage/unauthorized` on
   every upload, even with correct rules. Blaze keeps the same no-cost quotas, so this project
   costs nothing at its scale. Set a budget alert anyway (it notifies, it does not cap spending).
2. **Cross-service rules permission.** `storage.rules` calls `firestore.exists(...)` to protect
   published thumbnails, which requires the Storage service agent
   `service-{projectNumber}@gcp-sa-firebasestorage.iam.gserviceaccount.com` to have the role
   *Firebase Rules Firestore Service Agent*. Accept the prompt shown by the Firebase console
   (Storage → Rules) or by an interactive `firebase deploy`. The CLI skips that prompt when it
   runs non-interactively. The change may take a few minutes to propagate, and until then
   uploads also fail with `storage/unauthorized`.


## Deploying the Project
In order to deploy the Firestore rules from this repository to the [Firebase console](https://firebase.google.com/)  of your project, follow these steps:

### 1. Install firebase CLI
```
npm install -g firebase-tools
```
### 2. Login to your account
```
firebase login
```

### 3. Add your project id to the .firebasesrc file 
This corresponds to the project Id of the firebase project you created in the Firebase web-app.
[Change project id](.firebaserc)

### 4. Initialize the project
```
firebase init
```

You should leave everything as it is, choose:
- emulators
- firestore
- cloud storage

### 5. Deploy to firebase
```
firebase deploy --only firestore:rules,firestore:indexes,storage
```
This will deploy all the rules you write in `firestore.rules` to your Firebase Firestore project.
Be careful becasuse it will overwrite the existing firestore.rules file of your project.

## Running the project in a local emulator
To run the application locally, use the following command:

```firebase emulators:start```

## Seeding sample articles
`scripts/seed.mjs` publishes the sample articles in `scripts/seed-data/` following the
publishing flow described in the [schema](./docs/DB_SCHEMA.md#publishing-flow): it uploads each
thumbnail to `media/articles/{articleId}.{ext}` and then writes `articles/{articleId}`.
It uses the Firebase **client** SDK, so every write is checked by the security rules, just like
the app's writes.

```
npm install
firebase emulators:start --only firestore,storage   # shell 1
npm run seed:emulator                               # shell 2
```

Open the Emulator UI (http://127.0.0.1:4000) to browse the seeded documents and images.

In emulator mode the thumbnail URLs are stored with host `10.0.2.2`, which is how the Android
emulator reaches your machine. For a physical device using `adb reverse`, seed with
`EMULATOR_THUMBNAIL_HOST=127.0.0.1 npm run seed:emulator`.

To seed the real project, deploy the rules first and then run `npm run seed:production`.
It uses the `news-backend-scripts` Web app of the Firebase project.

## Testing the security rules
`test/` contains the unit tests of `firestore.rules` and `storage.rules`
([@firebase/rules-unit-testing](https://firebase.google.com/docs/rules/unit-tests) + the
built-in `node:test` runner). There is one or more tests for every constraint in the
[schema](./docs/DB_SCHEMA.md), including the edge cases (exact limits, emoji lengths, forged
timestamps, foreign thumbnail URLs, overwrites, orphan cleanup).

```
npm install
npm run emulators      # shell 1
npm run test:rules     # shell 2
```
Or in a single command, as the CI does (`.github/workflows/ci.yml`):
```
npx firebase-tools@15 emulators:exec --only firestore,storage "npm run test:rules"
```
(The standalone `firebase` binary cannot run ES module scripts inside `emulators:exec`, while the
npm package can.)
