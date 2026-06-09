# Test script for Update Profile API (PATCH /api/customers/me)
# Run: npm run dev (in one terminal), then powershell ./test-update-profile.ps1 (in another)

$base = "http://localhost:3000/api"
$results = @()

# First, register a test customer account
function Test-Api($name, $method, $path, $body, $headers, $expectStatus) {
    try {
        $params = @{
            Uri = "$base$path"
            Method = $method
            TimeoutSec = 15
            ErrorAction = "Stop"
        }
        if ($body) { $params.Body = ($body | ConvertTo-Json -Depth 10); $params.ContentType = "application/json" }
        if ($headers) { $params.Headers = $headers }
        $r = Invoke-WebRequest @params
        $status = $r.StatusCode
        $json = $r.Content | ConvertFrom-Json
        $ok = if ($expectStatus) { $status -eq $expectStatus } else { $status -ge 200 -and $status -lt 300 }
        $message = if ($json.success) { "success=true" } else { $json.message }
        $results += [pscustomobject]@{ Test = $name; Status = $status; OK = $ok; Message = $message }
        return $json
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $errBody = $reader.ReadToEnd()
        $reader.Close()
        try { $json = $errBody | ConvertFrom-Json; $msg = $json.message } catch { $msg = $errBody.Substring(0, [Math]::Min(80, $errBody.Length)) }
        $ok = if ($expectStatus) { $status -eq $expectStatus } else { $false }
        $results += [pscustomobject]@{ Test = $name; Status = $status; OK = $ok; Message = $msg }
        return $null
    }
}

Write-Host "=== Test Update Profile API ===" -ForegroundColor Cyan

# 1. Register test customer
Write-Host "`n[1] Registering test customer..." -ForegroundColor Yellow
$email = "testupdate_$(Get-Random)@test.com"
$registerResp = Test-Api "Register Customer" POST "/auth/register" @{
    email = $email
    password = "Password123456"
    full_name = "Test User"
    phone = "0901234567"
    role = "customer"
} $null 200

$accessToken = $registerResp.data.accessToken
$userId = $registerResp.data.user.id
Write-Host "User ID: $userId" -ForegroundColor Green
Write-Host "Access Token: $($accessToken.Substring(0, 20))..." -ForegroundColor Green

$headers = @{ Authorization = "Bearer $accessToken" }

# 2. Test: Get current profile
Write-Host "`n[2] Getting current profile..." -ForegroundColor Yellow
Test-Api "Get Profile" GET "/customers/me" $null $headers 200 | Out-Null

# 3. Test: Update full_name successfully
Write-Host "`n[3] Updating full_name..." -ForegroundColor Yellow
Test-Api "Update full_name" PATCH "/customers/me" @{
    full_name = "Updated Name"
} $headers 200 | Out-Null

# 4. Test: Update phone successfully
Write-Host "`n[4] Updating phone..." -ForegroundColor Yellow
Test-Api "Update phone" PATCH "/customers/me" @{
    phone = "0909876543"
} $headers 200 | Out-Null

# 5. Test: Update gender successfully
Write-Host "`n[5] Updating gender..." -ForegroundColor Yellow
Test-Api "Update gender" PATCH "/customers/me" @{
    gender = "male"
} $headers 200 | Out-Null

# 6. Test: Update date_of_birth successfully
Write-Host "`n[6] Updating date_of_birth..." -ForegroundColor Yellow
Test-Api "Update date_of_birth" PATCH "/customers/me" @{
    date_of_birth = "1990-01-15"
} $headers 200 | Out-Null

# 7. Test: Update avatar_url with valid URL
Write-Host "`n[7] Updating avatar_url..." -ForegroundColor Yellow
Test-Api "Update avatar_url" PATCH "/customers/me" @{
    avatar_url = "https://example.com/avatar.jpg"
} $headers 200 | Out-Null

# 8. Test: Update address (customer_profiles field)
Write-Host "`n[8] Updating address..." -ForegroundColor Yellow
Test-Api "Update address" PATCH "/customers/me" @{
    address = "123 Main St, City, District"
} $headers 200 | Out-Null

# 9. Test: Partial update (multiple fields)
Write-Host "`n[9] Partial update (multiple fields)..." -ForegroundColor Yellow
Test-Api "Partial update multiple" PATCH "/customers/me" @{
    full_name = "Final Name"
    phone = "0919999999"
    gender = "female"
} $headers 200 | Out-Null

# 10. Test: Empty body should fail
Write-Host "`n[10] Empty body (should fail 400)..." -ForegroundColor Yellow
Test-Api "Empty body" PATCH "/customers/me" @{} $headers 400 | Out-Null

# 11. Test: full_name empty string should fail
Write-Host "`n[11] Empty full_name (should fail 400)..." -ForegroundColor Yellow
Test-Api "Empty full_name" PATCH "/customers/me" @{
    full_name = "   "
} $headers 400 | Out-Null

# 12. Test: Invalid phone should fail
Write-Host "`n[12] Invalid phone (should fail 400)..." -ForegroundColor Yellow
Test-Api "Invalid phone" PATCH "/customers/me" @{
    phone = "invalid"
} $headers 400 | Out-Null

# 13. Test: Invalid gender should fail
Write-Host "`n[13] Invalid gender (should fail 400)..." -ForegroundColor Yellow
Test-Api "Invalid gender" PATCH "/customers/me" @{
    gender = "other"
} $headers 400 | Out-Null

# 14. Test: Invalid date_of_birth format should fail
Write-Host "`n[14] Invalid date format (should fail 400)..." -ForegroundColor Yellow
Test-Api "Invalid date_of_birth format" PATCH "/customers/me" @{
    date_of_birth = "01/15/1990"
} $headers 400 | Out-Null

# 15. Test: date_of_birth in future should fail
Write-Host "`n[15] Future date_of_birth (should fail 400)..." -ForegroundColor Yellow
$futureDate = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
Test-Api "Future date_of_birth" PATCH "/customers/me" @{
    date_of_birth = $futureDate
} $headers 400 | Out-Null

# 16. Test: Invalid avatar URL should fail
Write-Host "`n[16] Invalid avatar URL (should fail 400)..." -ForegroundColor Yellow
Test-Api "Invalid avatar_url" PATCH "/customers/me" @{
    avatar_url = "not a valid url"
} $headers 400 | Out-Null

# 17. Test: Cannot update email
Write-Host "`n[17] Try to update email (should fail 400)..." -ForegroundColor Yellow
Test-Api "Update email forbidden" PATCH "/customers/me" @{
    email = "newemail@test.com"
} $headers 400 | Out-Null

# 18. Test: Cannot update role
Write-Host "`n[18] Try to update role (should fail 400)..." -ForegroundColor Yellow
Test-Api "Update role forbidden" PATCH "/customers/me" @{
    role = "admin"
} $headers 400 | Out-Null

# 19. Test: Cannot update status
Write-Host "`n[19] Try to update status (should fail 400)..." -ForegroundColor Yellow
Test-Api "Update status forbidden" PATCH "/customers/me" @{
    status = "suspended"
} $headers 400 | Out-Null

# 20. Test: Cannot update password
Write-Host "`n[20] Try to update password (should fail 400)..." -ForegroundColor Yellow
Test-Api "Update password forbidden" PATCH "/customers/me" @{
    password = "NewPassword123"
} $headers 400 | Out-Null

# 21. Test: Cannot update id
Write-Host "`n[21] Try to update id (should fail 400)..." -ForegroundColor Yellow
Test-Api "Update id forbidden" PATCH "/customers/me" @{
    id = "fake-id-123"
} $headers 400 | Out-Null

# 22. Test: Unauthenticated request should fail
Write-Host "`n[22] Unauthenticated request (should fail 401)..." -ForegroundColor Yellow
Test-Api "Update without auth" PATCH "/customers/me" @{
    full_name = "Hacker"
} $null 401 | Out-Null

# 23. Test: Invalid token should fail
Write-Host "`n[23] Invalid token (should fail 401)..." -ForegroundColor Yellow
$badHeaders = @{ Authorization = "Bearer invalid.token.here" }
Test-Api "Update with invalid token" PATCH "/customers/me" @{
    full_name = "Hacker"
} $badHeaders 401 | Out-Null

# 24. Test: Address too long should fail
Write-Host "`n[24] Address too long (should fail 400)..." -ForegroundColor Yellow
$longAddress = "a" * 300
Test-Api "Address too long" PATCH "/customers/me" @{
    address = $longAddress
} $headers 400 | Out-Null

# 25. Test: full_name too long should fail
Write-Host "`n[25] full_name too long (should fail 400)..." -ForegroundColor Yellow
$longName = "a" * 300
Test-Api "full_name too long" PATCH "/customers/me" @{
    full_name = $longName
} $headers 400 | Out-Null

# 26. Test: Age validation (too young)
Write-Host "`n[26] Date of birth - too young (should fail 400)..." -ForegroundColor Yellow
$youngDate = (Get-Date).AddYears(-10).ToString("yyyy-MM-dd")
Test-Api "Date too young" PATCH "/customers/me" @{
    date_of_birth = $youngDate
} $headers 400 | Out-Null

Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
$pass = ($results | Where-Object { $_.OK -eq $true }).Count
$fail = ($results | Where-Object { $_.OK -eq $false }).Count
Write-Host "Passed: $pass, Failed: $fail" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
