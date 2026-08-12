/**
 * Seeds real teacher data into fingerprint-app-2026 for the teacher mobile app.
 * Uses admin client auth (no Firebase CLI token required).
 *
 * Run: node tools/seed_teacher_data.js
 */
const https = require('https');

const PROJECT = 'fingerprint-app-2026';
const WEB_API_KEY = 'AIzaSyAjdJsDA0NzvLMn3YrlMcoXO0FapZs_G6w';
const BRANCH = 'default_branch';

const ADMIN = { email: 'admin@center.com', password: 'Admin123!' };
const TEACHER = {
  email: 'teacher@center.com',
  password: 'Teacher123!',
  displayName: 'أ. محمود حسن',
  phone: '01012345678',
};

function requestJson(method, url, bodyObj, bearerToken) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const data = bodyObj ? JSON.stringify(bodyObj) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (bearerToken) headers.Authorization = 'Bearer ' + bearerToken;
    if (data) headers['Content-Length'] = Buffer.byteLength(data);
    const req = https.request(
      {
        hostname: u.hostname,
        path: u.pathname + u.search,
        method,
        headers,
      },
      (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          let parsed = raw;
          try {
            parsed = raw ? JSON.parse(raw) : {};
          } catch (_) {}
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
          values: v.map((item) =>
            typeof item === 'number'
              ? Number.isInteger(item)
                ? { integerValue: String(item) }
                : { doubleValue: item }
              : { stringValue: String(item) },
          ),
        },
      };
    } else if (v && v._ts) {
      fields[k] = { timestampValue: new Date().toISOString() };
    }
  }
  return fields;
}

async function signIn(email, password) {
  const res = await requestJson(
    'POST',
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${WEB_API_KEY}`,
    { email, password, returnSecureToken: true },
  );
  if (!res.body.idToken) {
    throw new Error(
      `Sign-in failed for ${email}: ${JSON.stringify(res.body).slice(0, 300)}`,
    );
  }
  return { uid: res.body.localId, idToken: res.body.idToken };
}

async function ensureAuthUser(email, password, displayName) {
  const signup = await requestJson(
    'POST',
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${WEB_API_KEY}`,
    { email, password, returnSecureToken: true, displayName },
  );
  if (signup.body.localId) {
    console.log('✓ Auth created', email, signup.body.localId);
    return { uid: signup.body.localId, idToken: signup.body.idToken };
  }
  const msg = signup.body.error?.message || '';
  if (String(msg).includes('EMAIL_EXISTS')) {
    const signed = await signIn(email, password);
    console.log('✓ Auth exists', email, signed.uid);
    return signed;
  }
  throw new Error(`Signup failed: ${JSON.stringify(signup.body).slice(0, 300)}`);
}

async function upsertDoc(token, collection, id, data) {
  const name = `projects/${PROJECT}/databases/(default)/documents/${collection}/${id}`;
  const res = await requestJson(
    'PATCH',
    `https://firestore.googleapis.com/v1/${name}`,
    { fields: toFields(data) },
    token,
  );
  if (res.status >= 200 && res.status < 300) {
    console.log('✓', `${collection}/${id}`);
    return id;
  }
  console.error(
    '✗',
    `${collection}/${id}`,
    res.status,
    JSON.stringify(res.body).slice(0, 280),
  );
  return null;
}

async function createDoc(token, collection, data) {
  const parent = `projects/${PROJECT}/databases/(default)/documents`;
  const res = await requestJson(
    'POST',
    `https://firestore.googleapis.com/v1/${parent}/${collection}`,
    { fields: toFields(data) },
    token,
  );
  if (res.status >= 200 && res.status < 300) {
    const id = res.body.name.split('/').pop();
    console.log('✓', `${collection}/${id}`);
    return id;
  }
  console.error(
    '✗',
    collection,
    res.status,
    JSON.stringify(res.body).slice(0, 280),
  );
  return null;
}

async function listCollection(token, collection) {
  const parent = `projects/${PROJECT}/databases/(default)/documents/${collection}`;
  const res = await requestJson(
    'GET',
    `https://firestore.googleapis.com/v1/${parent}?pageSize=100`,
    null,
    token,
  );
  if (res.status >= 200 && res.status < 300) {
    return res.body.documents || [];
  }
  return [];
}

function fieldStr(doc, key) {
  return doc.fields?.[key]?.stringValue ?? '';
}

function fieldBool(doc, key) {
  return doc.fields?.[key]?.booleanValue === true;
}

function isActive(doc) {
  return !doc.fields?.deletedAt && !fieldBool(doc, 'placeholder');
}

function docId(doc) {
  return doc.name.split('/').pop();
}

function findByName(docs, name) {
  return docs.find((d) => isActive(d) && fieldStr(d, 'name') === name);
}

(async () => {
  console.log('Signing in as admin…');
  const admin = await signIn(ADMIN.email, ADMIN.password);
  const token = admin.idToken;
  const stamp = { createdAt: { _ts: true }, updatedAt: { _ts: true } };

  console.log('\nEnsuring teacher auth…');
  const teacherAuth = await ensureAuthUser(
    TEACHER.email,
    TEACHER.password,
    TEACHER.displayName,
  );

  await upsertDoc(token, 'users', teacherAuth.uid, {
    email: TEACHER.email,
    displayName: TEACHER.displayName,
    role: 'teacher',
    phone: TEACHER.phone,
    branchId: BRANCH,
    linkedStudentIds: [],
    parentIds: [],
    ...stamp,
  });

  // Stable academic structure (upsert by fixed ids)
  console.log('\nAcademic structure…');
  await upsertDoc(token, 'centers', 'default_center', {
    name: 'سنتر مكة التعليمي',
    phone: '01123456789',
    address: 'القاهرة — مدينة نصر',
    ...stamp,
  });
  await upsertDoc(token, 'branches', BRANCH, {
    centerId: 'default_center',
    name: 'الفرع الرئيسي',
    timezone: 'Africa/Cairo',
    currency: 'EGP',
    locale: 'ar',
    ...stamp,
  });

  await upsertDoc(token, 'stages', 'stage_prep', {
    name: 'إعدادي',
    order: 3,
    branchId: BRANCH,
    ...stamp,
  });
  await upsertDoc(token, 'stages', 'stage_sec', {
    name: 'ثانوي',
    order: 4,
    branchId: BRANCH,
    ...stamp,
  });

  const grades = {
    g1: { id: 'grade_prep_1', name: 'الأول الإعدادي', stageId: 'stage_prep', order: 1 },
    g2: { id: 'grade_prep_2', name: 'الثاني الإعدادي', stageId: 'stage_prep', order: 2 },
    g3: { id: 'grade_prep_3', name: 'الثالث الإعدادي', stageId: 'stage_prep', order: 3 },
    g4: { id: 'grade_sec_1', name: 'الأول الثانوي', stageId: 'stage_sec', order: 1 },
  };
  for (const g of Object.values(grades)) {
    await upsertDoc(token, 'grades', g.id, {
      stageId: g.stageId,
      name: g.name,
      order: g.order,
      branchId: BRANCH,
      ...stamp,
    });
  }

  const subjects = {
    math: { id: 'subj_math', name: 'رياضيات' },
    physics: { id: 'subj_physics', name: 'فيزياء' },
    arabic: { id: 'subj_arabic', name: 'عربي' },
    english: { id: 'subj_english', name: 'English' },
  };
  for (const s of Object.values(subjects)) {
    await upsertDoc(token, 'subjects', s.id, {
      name: s.name,
      branchId: BRANCH,
      stageId: 'stage_prep',
      ...stamp,
    });
  }

  const rooms = {
    r1: { id: 'room_a1', name: 'قاعة أ1', capacity: 28, building: 'أ', floor: '1' },
    r2: { id: 'room_a2', name: 'قاعة أ2', capacity: 32, building: 'أ', floor: '1' },
    r3: { id: 'room_b1', name: 'قاعة ب1', capacity: 24, building: 'ب', floor: '2' },
  };
  for (const r of Object.values(rooms)) {
    await upsertDoc(token, 'classrooms', r.id, {
      name: r.name,
      capacity: r.capacity,
      building: r.building,
      floor: r.floor,
      status: 'active',
      branchId: BRANCH,
      ...stamp,
    });
  }

  console.log('\nTeacher profile…');
  const teacherId = 'teacher_mahmoud';
  await upsertDoc(token, 'teachers', teacherId, {
    name: TEACHER.displayName,
    phone: TEACHER.phone,
    userId: teacherAuth.uid,
    branchId: BRANCH,
    salaryMethod: 'perSession',
    subjectIds: [subjects.math.id, subjects.physics.id],
    status: 'active',
    ...stamp,
  });

  console.log('\nGroups…');
  const groups = [
    {
      id: 'group_math_prep1_a',
      name: 'رياضيات — أول إعدادي (أ)',
      gradeId: grades.g1.id,
      subjectId: subjects.math.id,
      classroomId: rooms.r1.id,
      capacity: 25,
    },
    {
      id: 'group_math_prep2_a',
      name: 'رياضيات — ثاني إعدادي (أ)',
      gradeId: grades.g2.id,
      subjectId: subjects.math.id,
      classroomId: rooms.r2.id,
      capacity: 28,
    },
    {
      id: 'group_physics_prep3',
      name: 'فيزياء — ثالث إعدادي',
      gradeId: grades.g3.id,
      subjectId: subjects.physics.id,
      classroomId: rooms.r3.id,
      capacity: 22,
    },
    {
      id: 'group_math_sec1',
      name: 'رياضيات — أول ثانوي',
      gradeId: grades.g4.id,
      subjectId: subjects.math.id,
      classroomId: rooms.r1.id,
      capacity: 30,
    },
  ];

  for (const g of groups) {
    await upsertDoc(token, 'groups', g.id, {
      name: g.name,
      branchId: BRANCH,
      gradeId: g.gradeId,
      subjectId: g.subjectId,
      teacherId,
      classroomId: g.classroomId,
      capacity: g.capacity,
      ...stamp,
    });
  }

  console.log('\nWeekly schedule…');
  // weekday: 1=Mon … 7=Sun  (matches app)
  const today = new Date();
  // JS: 0=Sun..6=Sat → convert to 1=Mon..7=Sun
  const jsDay = today.getDay();
  const todayWeekday = jsDay === 0 ? 7 : jsDay;

  const schedules = [
    // Ensure some sessions for "today" so dashboard is populated
    {
      id: 'sch_math_prep1_today',
      groupId: 'group_math_prep1_a',
      weekday: todayWeekday,
      startTime: '16:00',
      endTime: '17:30',
    },
    {
      id: 'sch_physics_today',
      groupId: 'group_physics_prep3',
      weekday: todayWeekday,
      startTime: '18:00',
      endTime: '19:30',
    },
    {
      id: 'sch_math_prep1_mon',
      groupId: 'group_math_prep1_a',
      weekday: 1,
      startTime: '16:00',
      endTime: '17:30',
    },
    {
      id: 'sch_math_prep1_wed',
      groupId: 'group_math_prep1_a',
      weekday: 3,
      startTime: '16:00',
      endTime: '17:30',
    },
    {
      id: 'sch_math_prep2_tue',
      groupId: 'group_math_prep2_a',
      weekday: 2,
      startTime: '17:00',
      endTime: '18:30',
    },
    {
      id: 'sch_math_prep2_thu',
      groupId: 'group_math_prep2_a',
      weekday: 4,
      startTime: '17:00',
      endTime: '18:30',
    },
    {
      id: 'sch_physics_sun',
      groupId: 'group_physics_prep3',
      weekday: 7,
      startTime: '15:00',
      endTime: '16:30',
    },
    {
      id: 'sch_math_sec_sat',
      groupId: 'group_math_sec1',
      weekday: 6,
      startTime: '10:00',
      endTime: '12:00',
    },
    {
      id: 'sch_math_sec_wed',
      groupId: 'group_math_sec1',
      weekday: 3,
      startTime: '18:00',
      endTime: '20:00',
    },
  ];

  // Deduplicate if today already matches mon/wed etc. — still fine to upsert fixed ids
  for (const s of schedules) {
    await upsertDoc(token, 'schedules', s.id, {
      groupId: s.groupId,
      weekday: s.weekday,
      startTime: s.startTime,
      endTime: s.endTime,
      branchId: BRANCH,
      ...stamp,
    });
  }

  console.log('\nStudents linked to teacher groups…');
  const students = [
    { id: 'stu_ahmed', name: 'أحمد علي', gradeId: grades.g1.id, phone: '01011112222' },
    { id: 'stu_sara', name: 'سارة محمد', gradeId: grades.g1.id, phone: '01022223333' },
    { id: 'stu_omar', name: 'عمر خالد', gradeId: grades.g2.id, phone: '01033334444' },
    { id: 'stu_nour', name: 'نور حسن', gradeId: grades.g2.id, phone: '01044445555' },
    { id: 'stu_youssef', name: 'يوسف إبراهيم', gradeId: grades.g3.id, phone: '01055556666' },
    { id: 'stu_layan', name: 'ليان سمير', gradeId: grades.g3.id, phone: '01066667777' },
    { id: 'stu_karim', name: 'كريم فادي', gradeId: grades.g4.id, phone: '01077778888' },
    { id: 'stu_maya', name: 'مايا طارق', gradeId: grades.g4.id, phone: '01088889999' },
  ];

  for (const s of students) {
    await upsertDoc(token, 'students', s.id, {
      name: s.name,
      phone: s.phone,
      gradeId: s.gradeId,
      branchId: BRANCH,
      parentIds: [],
      status: 'active',
      ...stamp,
    });
  }

  const enrollments = [
    { id: 'enr_ahmed_g1', studentId: 'stu_ahmed', gradeId: grades.g1.id, fee: 1200 },
    { id: 'enr_sara_g1', studentId: 'stu_sara', gradeId: grades.g1.id, fee: 1200 },
    { id: 'enr_omar_g2', studentId: 'stu_omar', gradeId: grades.g2.id, fee: 1300 },
    { id: 'enr_nour_g2', studentId: 'stu_nour', gradeId: grades.g2.id, fee: 1300 },
    { id: 'enr_youssef_g3', studentId: 'stu_youssef', gradeId: grades.g3.id, fee: 1400 },
    { id: 'enr_layan_g3', studentId: 'stu_layan', gradeId: grades.g3.id, fee: 1400 },
    { id: 'enr_karim_g4', studentId: 'stu_karim', gradeId: grades.g4.id, fee: 1600 },
    { id: 'enr_maya_g4', studentId: 'stu_maya', gradeId: grades.g4.id, fee: 1600 },
  ];

  for (const e of enrollments) {
    await upsertDoc(token, 'enrollments', e.id, {
      studentId: e.studentId,
      gradeId: e.gradeId,
      type: 'full',
      fee: e.fee,
      note: 'اشتراك كامل',
      status: 'active',
      branchId: BRANCH,
      ...stamp,
    });
  }

  console.log('\nDONE — teacher data seeded in Firestore');
  console.log('Teacher login:', TEACHER.email);
  console.log('Password:', TEACHER.password);
  console.log('Teacher doc id:', teacherId);
  console.log('Groups:', groups.length, '| Schedules:', schedules.length, '| Students:', students.length);
  console.log(
    'Console:',
    `https://console.firebase.google.com/project/${PROJECT}/firestore/databases/-default-/data`,
  );
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
