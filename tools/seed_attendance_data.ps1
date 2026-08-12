# Seeds attendance records for teacher students (fingerprint-ready schema).
$ErrorActionPreference = 'Stop'
$PROJECT = 'fingerprint-app-2026'
$WEB_API_KEY = 'AIzaSyAjdJsDA0NzvLMn3YrlMcoXO0FapZs_G6w'
$BRANCH = 'default_branch'
$ADMIN_EMAIL = 'admin@center.com'
$ADMIN_PASSWORD = 'Admin123!'

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
    elseif ($v -is [double] -or $v -is [decimal]) { $fields[$key] = @{ doubleValue = [double]$v } }
    elseif ($v -is [hashtable] -and $v.ContainsKey('_ts')) {
      $fields[$key] = @{ timestampValue = (Get-Date).ToUniversalTime().ToString('o') }
    }
    elseif ($v -is [hashtable] -and $v.ContainsKey('_iso')) {
      $fields[$key] = @{ timestampValue = [string]$v._iso }
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

Write-Host 'Signing in as admin...'
$admin = Invoke-Json -Method POST -Url "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$WEB_API_KEY" -Body @{
  email = $ADMIN_EMAIL
  password = $ADMIN_PASSWORD
  returnSecureToken = $true
}
$token = $admin.idToken
if (-not $token) { throw 'Admin sign-in failed' }

$today = Get-Date
$todayStr = $today.ToString('yyyy-MM-dd')
$yesterday = $today.AddDays(-1).ToString('yyyy-MM-dd')
$twoDaysAgo = $today.AddDays(-2).ToString('yyyy-MM-dd')

# device-ready placeholder (not used by UI yet) — schema only
Upsert-Doc $token 'devices' 'device_main_gate' @{
  name = 'Main gate ZKTeco'
  branchId = $BRANCH
  serialNumber = 'ZK-READY-001'
  vendor = 'zkteco'
  status = 'inactive'
  location = 'Entrance'
  createdAt = @{ _ts = $true }
  updatedAt = @{ _ts = $true }
}

# Map students to device user ids for future fingerprint sync
$mappings = @(
  @{ id = 'map_ahmed'; studentId = 'stu_ahmed'; deviceUserId = '1001' },
  @{ id = 'map_sara'; studentId = 'stu_sara'; deviceUserId = '1002' },
  @{ id = 'map_omar'; studentId = 'stu_omar'; deviceUserId = '1003' },
  @{ id = 'map_nour'; studentId = 'stu_nour'; deviceUserId = '1004' },
  @{ id = 'map_youssef'; studentId = 'stu_youssef'; deviceUserId = '1005' },
  @{ id = 'map_layan'; studentId = 'stu_layan'; deviceUserId = '1006' },
  @{ id = 'map_karim'; studentId = 'stu_karim'; deviceUserId = '1007' },
  @{ id = 'map_maya'; studentId = 'stu_maya'; deviceUserId = '1008' }
)
foreach ($m in $mappings) {
  Upsert-Doc $token 'biometric_mappings' $m.id @{
    studentId = $m.studentId
    deviceId = 'device_main_gate'
    deviceUserId = $m.deviceUserId
    branchId = $BRANCH
    fingerIndex = 1
    status = 'active'
    createdAt = @{ _ts = $true }
    updatedAt = @{ _ts = $true }
  }
}

Write-Host 'Attendance records...'
$records = @(
  @{ id = 'att_ahmed_today'; studentId = 'stu_ahmed'; groupId = 'group_math_prep1_a'; date = $todayStr; status = 'present'; source = 'fingerprint'; deviceUserId = '1001'; checkInHour = 16; checkInMin = 5 },
  @{ id = 'att_sara_today'; studentId = 'stu_sara'; groupId = 'group_math_prep1_a'; date = $todayStr; status = 'late'; source = 'fingerprint'; deviceUserId = '1002'; checkInHour = 16; checkInMin = 22 },
  @{ id = 'att_youssef_today'; studentId = 'stu_youssef'; groupId = 'group_physics_prep3'; date = $todayStr; status = 'present'; source = 'manual'; deviceUserId = $null; checkInHour = 18; checkInMin = 2 },
  @{ id = 'att_layan_today'; studentId = 'stu_layan'; groupId = 'group_physics_prep3'; date = $todayStr; status = 'absent'; source = 'manual'; deviceUserId = $null; checkInHour = $null; checkInMin = $null },
  @{ id = 'att_omar_yday'; studentId = 'stu_omar'; groupId = 'group_math_prep2_a'; date = $yesterday; status = 'present'; source = 'fingerprint'; deviceUserId = '1003'; checkInHour = 17; checkInMin = 1 },
  @{ id = 'att_nour_yday'; studentId = 'stu_nour'; groupId = 'group_math_prep2_a'; date = $yesterday; status = 'excused'; source = 'manual'; deviceUserId = $null; checkInHour = $null; checkInMin = $null },
  @{ id = 'att_karim_2d'; studentId = 'stu_karim'; groupId = 'group_math_sec1'; date = $twoDaysAgo; status = 'present'; source = 'device'; deviceUserId = '1007'; checkInHour = 10; checkInMin = 4 },
  @{ id = 'att_maya_2d'; studentId = 'stu_maya'; groupId = 'group_math_sec1'; date = $twoDaysAgo; status = 'late'; source = 'fingerprint'; deviceUserId = '1008'; checkInHour = 10; checkInMin = 18 },
  @{ id = 'att_ahmed_yday'; studentId = 'stu_ahmed'; groupId = 'group_math_prep1_a'; date = $yesterday; status = 'present'; source = 'fingerprint'; deviceUserId = '1001'; checkInHour = 16; checkInMin = 3 },
  @{ id = 'att_sara_yday'; studentId = 'stu_sara'; groupId = 'group_math_prep1_a'; date = $yesterday; status = 'present'; source = 'manual'; deviceUserId = $null; checkInHour = 16; checkInMin = 8 }
)

foreach ($r in $records) {
  $data = @{
    studentId = $r.studentId
    branchId = $BRANCH
    date = $r.date
    status = $r.status
    source = $r.source
    groupId = $r.groupId
    note = $null
    recordedBy = 'admin'
    createdAt = @{ _ts = $true }
    updatedAt = @{ _ts = $true }
  }
  if ($null -ne $r.deviceUserId) {
    $data.deviceId = 'device_main_gate'
    $data.deviceUserId = $r.deviceUserId
  }
  if ($null -ne $r.checkInHour) {
    $checkIn = Get-Date -Year $today.Year -Month $today.Month -Day ([int]$r.date.Substring(8,2)) -Hour $r.checkInHour -Minute $r.checkInMin -Second 0
    # Fix day from date string properly
    $parts = $r.date.Split('-')
    $checkIn = Get-Date -Year ([int]$parts[0]) -Month ([int]$parts[1]) -Day ([int]$parts[2]) -Hour $r.checkInHour -Minute $r.checkInMin -Second 0
    $data.checkInAt = @{ _iso = $checkIn.ToUniversalTime().ToString('o') }
  }
  Upsert-Doc $token 'attendances' $r.id $data
}

Write-Host ''
Write-Host 'DONE - attendance seeded'
Write-Host ("Records: " + $records.Count)
Write-Host 'Schema ready for future fingerprint device (devices + biometric_mappings)'
