const fs = require('fs');
const path = require('path');
const https = require('https');

const PROJECT = 'fingerprint-app-2026';
const conf = JSON.parse(
  fs.readFileSync(
    path.join(process.env.USERPROFILE, '.config', 'configstore', 'firebase-tools.json'),
    'utf8',
  ),
);
const tokens = conf.tokens || {};
const accessToken = tokens.access_token;
if (!accessToken) {
  console.error('No access_token in firebase-tools.json. Run: firebase login');
  process.exit(1);
}
if (tokens.expires_at && Date.now() > tokens.expires_at) {
  console.error('Firebase CLI access token expired. Run: firebase login --reauth');
  process.exit(1);
}

function requestJson(method, url, bodyObj, bearer = true) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const data = bodyObj ? JSON.stringify(bodyObj) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (bearer) headers.Authorization = 'Bearer ' + accessToken;
    if (data) headers['Content-Length'] = Buffer.byteLength(data);
    const req = https.request(
      { hostname: u.hostname, path: u.pathname + u.search, method, headers },
      (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          let parsed = raw;
          try {
            parsed = raw ? JSON.parse(raw) : {};
          } catch {}
          resolve({ status: res.statusCode, body: parsed });
        });
      },
    );
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

function toFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v === null || v === undefined) continue;
    if (typeof v === 'string') fields[k] = { stringValue: v };
    else if (typeof v === 'number') {
      fields[k] = Number.isInteger(v)
        ? { integerValue: String(v) }
        : { doubleValue: v };
    } else if (typeof v === 'boolean') fields[k] = { booleanValue: v };
    else if (Array.isArray(v)) {
      fields[k] = {
        arrayValue: {
          values: v.map((item) => ({ stringValue: String(item) })),
        },
      };
    } else if (v && v._ts) {
      fields[k] = { timestampValue: new Date().toISOString() };
    }
  }
  return fields;
}

async function upsertDoc(collection, id, data) {
  const name = `projects/${PROJECT}/databases/(default)/documents/${collection}/${id}`;
  const res = await requestJson('PATCH', `https://firestore.googleapis.com/v1/${name}`, {
    fields: toFields(data),
  });
  if (res.status >= 200 && res.status < 300) {
    console.log('✓', `${collection}/${id}`);
    return true;
  }
  console.error('✗', `${collection}/${id}`, res.status, JSON.stringify(res.body).slice(0, 250));
  return false;
}

async function createDoc(collection, data) {
  const parent = `projects/${PROJECT}/databases/(default)/documents`;
  const res = await requestJson(
    'POST',
    `https://firestore.googleapis.com/v1/${parent}/${collection}`,
    { fields: toFields(data) },
  );
  if (res.status >= 200 && res.status < 300) {
    const id = res.body.name.split('/').pop();
    console.log('✓', `${collection}/${id}`);
    return id;
  }
  console.error('✗', collection, res.status, JSON.stringify(res.body).slice(0, 250));
  return null;
}

(async () => {
  console.log('Enabling Email/Password…');
  const cfgRes = await requestJson(
    'PATCH',
    `https://identitytoolkit.googleapis.com/admin/v2/projects/${PROJECT}/config?updateMask=signIn.email`,
    { signIn: { email: { enabled: true, passwordRequired: true } } },
  );
  console.log('Auth config:', cfgRes.status);

  const email = 'admin@center.com';
  const password = 'Admin123!';

  // Client signup after enabling email
  const signup = await requestJson(
    'POST',
    'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyAjdJsDA0NzvLMn3YrlMcoXO0FapZs_G6w',
    { email, password, returnSecureToken: true, displayName: 'المدير العام' },
    false,
  );
  let uid = signup.body.localId;
  if (!uid && signup.body.error) {
    const msg = signup.body.error.message || '';
    console.log('Signup:', msg);
    if (String(msg).includes('EMAIL_EXISTS')) {
      const signin = await requestJson(
        'POST',
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyAjdJsDA0NzvLMn3YrlMcoXO0FapZs_G6w',
        { email, password, returnSecureToken: true },
        false,
      );
      uid = signin.body.localId;
      if (!uid) console.log('Signin failed:', JSON.stringify(signin.body).slice(0, 300));
    }
  } else {
    console.log('Created auth user', uid);
  }

  const stamp = { createdAt: { _ts: true }, updatedAt: { _ts: true } };

  if (uid) {
    await upsertDoc('users', uid, {
      email,
      displayName: 'المدير العام',
      role: 'admin',
      branchId: 'default_branch',
      linkedStudentIds: [],
      parentIds: [],
      ...stamp,
    });
  }

  await upsertDoc('centers', 'default_center', {
    name: 'السنتر التعليمي',
    phone: '',
    address: '',
    ...stamp,
  });
  await upsertDoc('branches', 'default_branch', {
    centerId: 'default_center',
    name: 'الفرع الرئيسي',
    timezone: 'Africa/Cairo',
    currency: 'EGP',
    locale: 'ar',
    ...stamp,
  });

  const stageIds = {};
  for (const s of [
    { name: 'تمهيدي', order: 1 },
    { name: 'ابتدائي', order: 2 },
    { name: 'إعدادي', order: 3 },
  ]) {
    const id = await createDoc('stages', {
      name: s.name,
      order: s.order,
      branchId: 'default_branch',
      ...stamp,
    });
    if (id) stageIds[s.name] = id;
  }

  for (const g of [
    { stage: 'تمهيدي', name: 'KG1', order: 1 },
    { stage: 'تمهيدي', name: 'KG2', order: 2 },
    { stage: 'ابتدائي', name: 'الصف الأول', order: 1 },
    { stage: 'ابتدائي', name: 'الصف الثاني', order: 2 },
    { stage: 'ابتدائي', name: 'الصف الثالث', order: 3 },
    { stage: 'إعدادي', name: 'الأول الإعدادي', order: 1 },
    { stage: 'إعدادي', name: 'الثاني الإعدادي', order: 2 },
    { stage: 'إعدادي', name: 'الثالث الإعدادي', order: 3 },
  ]) {
    await createDoc('grades', {
      stageId: stageIds[g.stage] || '',
      name: g.name,
      order: g.order,
      branchId: 'default_branch',
      ...stamp,
    });
  }

  for (const name of ['عربي', 'رياضيات', 'English', 'علوم', 'دراسات']) {
    await createDoc('subjects', {
      name,
      branchId: 'default_branch',
      stageId: stageIds['ابتدائي'] || '',
      ...stamp,
    });
  }

  for (const r of [
    { name: 'قاعة 1', capacity: 25, building: 'A', floor: '1' },
    { name: 'قاعة 2', capacity: 30, building: 'A', floor: '1' },
    { name: 'قاعة 3', capacity: 20, building: 'B', floor: '2' },
  ]) {
    await createDoc('classrooms', {
      ...r,
      status: 'active',
      branchId: 'default_branch',
      ...stamp,
    });
  }

  for (const name of [
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
  ]) {
    await upsertDoc(name, '_placeholder', {
      branchId: 'default_branch',
      placeholder: true,
      note: 'حذف بعد إضافة بيانات حقيقية',
      ...stamp,
    });
  }

  console.log('\nDONE');
  console.log('Login email:', email);
  console.log('Login password:', password);
  console.log(
    'Firestore:',
    `https://console.firebase.google.com/project/${PROJECT}/firestore/databases/-default-/data`,
  );
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
