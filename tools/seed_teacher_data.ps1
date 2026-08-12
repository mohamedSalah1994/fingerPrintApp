# Seeds real teacher Firestore data. All Arabic text lives in seed_teacher_payload.json (UTF-8).
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$PROJECT = 'fingerprint-app-2026'
$WEB_API_KEY = 'AIzaSyAjdJsDA0NzvLMn3YrlMcoXO0FapZs_G6w'
$BRANCH = 'default_branch'
$ADMIN_EMAIL = 'admin@center.com'
$ADMIN_PASSWORD = 'Admin123!'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsonPath = Join-Path $root 'seed_teacher_payload.json'
$payload = Get-Content -LiteralPath $jsonPath -Encoding UTF8 -Raw | ConvertFrom-Json

function Invoke-Json {
  param([string]$Method, [string]$Url, $Body = $null, [string]$Token = $null)
  $headers = @{ 'Content-Type' = 'application/json; charset=utf-8' }
  if ($Token) { $headers['Authorization'] = "Bearer $Token" }
  $params = @{ Method = $Method; Uri = $Url; Headers = $headers }
  if ($null -ne $Body) {
    $json = $Body | ConvertTo-Json -Depth 30 -Compress
    $params.Body = [System.Text.Encoding]::UTF8.GetBytes($json)
    $params.ContentType = 'application/json; charset=utf-8'
  }
  return Invoke-RestMethod @params
}

function ConvertTo-FirestoreFields([hashtable]$obj) {
  $fields = @{}
  foreach ($key in $obj.Keys) {
    $v = $obj[$key]
    if ($null -eq $v) { continue }
    if ($v -is [string]) { $fields[$key] = @{ stringValue = $v } }
    elseif ($v -is [bool]) { $fields[$key] = @{ booleanValue = [bool]$v } }
    elseif ($v -is [int] -or $v -is [long] -or $v -is [Int64]) { $fields[$key] = @{ integerValue = "$v" } }
    elseif ($v -is [double] -or $v -is [decimal] -or $v -is [float]) { $fields[$key] = @{ doubleValue = [double]$v } }
    elseif ($v -is [System.Collections.IList]) {
      $values = @()
      foreach ($item in $v) {
        if ($item -is [int] -or $item -is [long]) { $values += @{ integerValue = "$item" } }
        else { $values += @{ stringValue = "$item" } }
      }
      $fields[$key] = @{ arrayValue = @{ values = $values } }
    }
    elseif ($v -is [hashtable] -and $v.ContainsKey('_ts')) {
      $fields[$key] = @{ timestampValue = (Get-Date).ToUniversalTime().ToString('o') }
    }
  }
  return $fields
}

function Upsert-Doc([string]$Token, [string]$Collection, [string]$Id, [hashtable]$Data) {
  $url = "https://firestore.googleapis.com/v1/projects/$PROJECT/databases/(default)/documents/${Collection}/${Id}"
  $body = @{ fields = (ConvertTo-FirestoreFields $Data) }
  Invoke-Json -Method PATCH -Url $url -Body $body -Token $Token | Out-Null
  Write-Host "OK $Collection/$Id"
}

function New-StampData([hashtable]$extra) {
  $map = @{
    createdAt = @{ _ts = $true }
    updatedAt = @{ _ts = $true }
  }
  foreach ($k in $extra.Keys) { $map[$k] = $extra[$k] }
  return $map
}

Write-Host 'Signing in as admin...'
$admin = Invoke-Json -Method POST -Url "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$WEB_API_KEY" -Body @{
  email = $ADMIN_EMAIL
  password = $ADMIN_PASSWORD
  returnSecureToken = $true
}
$token = $admin.idToken
if (-not $token) { throw 'Admin sign-in failed' }

$t = $payload.teacher
Write-Host ("Ensuring teacher auth " + $t.email + "...")
$teacherUid = $null
try {
  $signup = Invoke-Json -Method POST -Url "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$WEB_API_KEY" -Body @{
    email = $t.email
    password = $t.password
    returnSecureToken = $true
    displayName = $t.displayName
  }
  $teacherUid = $signup.localId
  Write-Host "Auth created $teacherUid"
} catch {
  $signin = Invoke-Json -Method POST -Url "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$WEB_API_KEY" -Body @{
    email = $t.email
    password = $t.password
    returnSecureToken = $true
  }
  $teacherUid = $signin.localId
  Write-Host "Auth exists $teacherUid"
}
if (-not $teacherUid) { throw 'Teacher uid missing' }

Upsert-Doc $token 'users' $teacherUid (New-StampData @{
  email = [string]$t.email
  displayName = [string]$t.displayName
  role = 'teacher'
  phone = [string]$t.phone
  branchId = $BRANCH
  linkedStudentIds = @()
  parentIds = @()
})

Write-Host 'Center / branch...'
Upsert-Doc $token 'centers' 'default_center' (New-StampData @{
  name = [string]$payload.center.name
  phone = [string]$payload.center.phone
  address = [string]$payload.center.address
})
Upsert-Doc $token 'branches' $BRANCH (New-StampData @{
  centerId = 'default_center'
  name = [string]$payload.branch.name
  timezone = 'Africa/Cairo'
  currency = 'EGP'
  locale = 'ar'
})

Write-Host 'Stages / grades / subjects / classrooms...'
foreach ($s in $payload.stages) {
  Upsert-Doc $token 'stages' $s.id (New-StampData @{
    name = [string]$s.name
    order = [int]$s.order
    branchId = $BRANCH
  })
}
foreach ($g in $payload.grades) {
  Upsert-Doc $token 'grades' $g.id (New-StampData @{
    stageId = [string]$g.stageId
    name = [string]$g.name
    order = [int]$g.order
    branchId = $BRANCH
  })
}
foreach ($s in $payload.subjects) {
  Upsert-Doc $token 'subjects' $s.id (New-StampData @{
    name = [string]$s.name
    branchId = $BRANCH
    stageId = 'stage_prep'
  })
}
foreach ($r in $payload.classrooms) {
  Upsert-Doc $token 'classrooms' $r.id (New-StampData @{
    name = [string]$r.name
    capacity = [int]$r.capacity
    building = [string]$r.building
    floor = [string]$r.floor
    status = 'active'
    branchId = $BRANCH
  })
}

Write-Host 'Teacher profile...'
Upsert-Doc $token 'teachers' $t.docId (New-StampData @{
  name = [string]$t.displayName
  phone = [string]$t.phone
  userId = $teacherUid
  branchId = $BRANCH
  salaryMethod = 'perSession'
  subjectIds = @('subj_math', 'subj_physics')
  status = 'active'
})

Write-Host 'Groups...'
foreach ($g in $payload.groups) {
  Upsert-Doc $token 'groups' $g.id (New-StampData @{
    name = [string]$g.name
    branchId = $BRANCH
    gradeId = [string]$g.gradeId
    subjectId = [string]$g.subjectId
    teacherId = [string]$t.docId
    classroomId = [string]$g.classroomId
    capacity = [int]$g.capacity
  })
}

Write-Host 'Schedules...'
$jsDay = [int](Get-Date).DayOfWeek
$todayWeekday = if ($jsDay -eq 0) { 7 } else { $jsDay }

Upsert-Doc $token 'schedules' 'sch_today_math' (New-StampData @{
  groupId = 'group_math_prep1_a'
  weekday = [int]$todayWeekday
  startTime = '16:00'
  endTime = '17:30'
  branchId = $BRANCH
})
Upsert-Doc $token 'schedules' 'sch_today_physics' (New-StampData @{
  groupId = 'group_physics_prep3'
  weekday = [int]$todayWeekday
  startTime = '18:00'
  endTime = '19:30'
  branchId = $BRANCH
})

foreach ($s in $payload.schedules) {
  Upsert-Doc $token 'schedules' $s.id (New-StampData @{
    groupId = [string]$s.groupId
    weekday = [int]$s.weekday
    startTime = [string]$s.startTime
    endTime = [string]$s.endTime
    branchId = $BRANCH
  })
}

Write-Host 'Students + enrollments...'
foreach ($s in $payload.students) {
  Upsert-Doc $token 'students' $s.id (New-StampData @{
    name = [string]$s.name
    phone = [string]$s.phone
    gradeId = [string]$s.gradeId
    branchId = $BRANCH
    parentIds = @()
    status = 'active'
  })
  Upsert-Doc $token 'enrollments' ("enr_$($s.id)") (New-StampData @{
    studentId = [string]$s.id
    gradeId = [string]$s.gradeId
    type = 'full'
    fee = [double]$s.fee
    note = [string]$payload.enrollmentNote
    status = 'active'
    branchId = $BRANCH
  })
}

Write-Host ''
Write-Host 'DONE - real teacher data written to Firestore'
Write-Host ("Login: " + $t.email)
Write-Host ("Password: " + $t.password)
Write-Host ("Teacher doc: " + $t.docId)
Write-Host ("Groups: " + $payload.groups.Count + " | Weekly slots: " + ($payload.schedules.Count + 2) + " | Students: " + $payload.students.Count)
