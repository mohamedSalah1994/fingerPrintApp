/**
 * One-time seed for fingerprint-app-2026
 * Creates Auth admin + Firestore collections/documents.
 *
 * Usage (from project root):
 *   node tools/seed_firestore.js
 */
const { initializeApp } = require('firebase/app');
const {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
} = require('firebase/auth');
const {
  getFirestore,
  doc,
  setDoc,
  serverTimestamp,
  collection,
  addDoc,
} = require('firebase/firestore');

const firebaseConfig = {
  apiKey: 'AIzaSyAjdJsDA0NzvLMn3YrlMcoXO0FapZs_G6w',
  authDomain: 'fingerprint-app-2026.firebaseapp.com',
  projectId: 'fingerprint-app-2026',
  storageBucket: 'fingerprint-app-2026.firebasestorage.app',
  messagingSenderId: '241296984676',
  appId: '1:241296984676:web:79bbdd73466210e1f8ed71',
};

const EMAIL = process.env.SEED_EMAIL || 'admin@center.com';
const PASSWORD = process.env.SEED_PASSWORD || 'Admin123!';
const DISPLAY_NAME = process.env.SEED_NAME || 'المدير العام';
const BRANCH_ID = 'default_branch';
const CENTER_ID = 'default_center';

async function main() {
  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
  const db = getFirestore(app);

  let cred;
  try {
    cred = await createUserWithEmailAndPassword(auth, EMAIL, PASSWORD);
    console.log('Created auth user:', EMAIL);
  } catch (e) {
    if (e.code === 'auth/email-already-in-use') {
      cred = await signInWithEmailAndPassword(auth, EMAIL, PASSWORD);
      console.log('Signed in existing user:', EMAIL);
    } else if (e.code === 'auth/operation-not-allowed') {
      console.error(
        'ERROR: Enable Email/Password in Firebase Console → Authentication → Sign-in method',
      );
      process.exit(1);
    } else {
      throw e;
    }
  }

  const uid = cred.user.uid;
  const stamp = {
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };

  await setDoc(
    doc(db, 'centers', CENTER_ID),
    {
      name: 'السنتر التعليمي',
      phone: '',
      address: '',
      ...stamp,
    },
    { merge: true },
  );
  console.log('✓ centers/' + CENTER_ID);

  await setDoc(
    doc(db, 'branches', BRANCH_ID),
    {
      centerId: CENTER_ID,
      name: 'الفرع الرئيسي',
      timezone: 'Africa/Cairo',
      currency: 'EGP',
      locale: 'ar',
      ...stamp,
    },
    { merge: true },
  );
  console.log('✓ branches/' + BRANCH_ID);

  await setDoc(
    doc(db, 'users', uid),
    {
      email: EMAIL,
      displayName: DISPLAY_NAME,
      role: 'admin',
      branchId: BRANCH_ID,
      linkedStudentIds: [],
      parentIds: [],
      ...stamp,
    },
    { merge: true },
  );
  console.log('✓ users/' + uid + ' (admin)');

  const stages = [
    { name: 'تمهيدي', order: 1 },
    { name: 'ابتدائي', order: 2 },
    { name: 'إعدادي', order: 3 },
  ];
  const stageIds = {};
  for (const s of stages) {
    const ref = await addDoc(collection(db, 'stages'), {
      ...s,
      branchId: BRANCH_ID,
      ...stamp,
    });
    stageIds[s.name] = ref.id;
    console.log('✓ stages/' + ref.id + ' ' + s.name);
  }

  const gradeDefs = [
    { stage: 'تمهيدي', name: 'KG1', order: 1 },
    { stage: 'تمهيدي', name: 'KG2', order: 2 },
    { stage: 'ابتدائي', name: 'الصف الأول', order: 1 },
    { stage: 'ابتدائي', name: 'الصف الثاني', order: 2 },
    { stage: 'ابتدائي', name: 'الصف الثالث', order: 3 },
    { stage: 'إعدادي', name: 'الأول الإعدادي', order: 1 },
    { stage: 'إعدادي', name: 'الثاني الإعدادي', order: 2 },
    { stage: 'إعدادي', name: 'الثالث الإعدادي', order: 3 },
  ];
  const gradeIds = {};
  for (const g of gradeDefs) {
    const ref = await addDoc(collection(db, 'grades'), {
      stageId: stageIds[g.stage],
      name: g.name,
      order: g.order,
      branchId: BRANCH_ID,
      ...stamp,
    });
    gradeIds[g.name] = ref.id;
    console.log('✓ grades/' + ref.id + ' ' + g.name);
  }

  const subjects = ['عربي', 'رياضيات', 'English', 'علوم', 'دراسات'];
  for (const name of subjects) {
    const ref = await addDoc(collection(db, 'subjects'), {
      name,
      branchId: BRANCH_ID,
      stageId: stageIds['ابتدائي'],
      ...stamp,
    });
    console.log('✓ subjects/' + ref.id + ' ' + name);
  }

  const rooms = [
    { name: 'قاعة 1', capacity: 25, building: 'A', floor: '1' },
    { name: 'قاعة 2', capacity: 30, building: 'A', floor: '1' },
    { name: 'قاعة 3', capacity: 20, building: 'B', floor: '2' },
  ];
  for (const r of rooms) {
    const ref = await addDoc(collection(db, 'classrooms'), {
      ...r,
      status: 'active',
      branchId: BRANCH_ID,
      ...stamp,
    });
    console.log('✓ classrooms/' + ref.id + ' ' + r.name);
  }

  // Empty placeholder docs so collections appear in console for remaining tables
  const emptyCollections = [
    'teachers',
    'students',
    'parents',
    'groups',
    'schedules',
    'enrollments',
    'enrollment_subjects',
    'attendances',
    'devices',
    'biometric_mappings',
    'notifications',
  ];
  for (const name of emptyCollections) {
    await setDoc(doc(db, name, '_placeholder'), {
      branchId: BRANCH_ID,
      placeholder: true,
      note: 'حذف هذا المستند بعد إضافة بيانات حقيقية',
      ...stamp,
    });
    console.log('✓ ' + name + '/_placeholder');
  }

  console.log('\nDone.');
  console.log('Login with:', EMAIL, '/', PASSWORD);
  console.log(
    'Console:',
    'https://console.firebase.google.com/project/fingerprint-app-2026/firestore/databases/-default-/data',
  );
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed failed:', err.code || '', err.message || err);
  process.exit(1);
});
