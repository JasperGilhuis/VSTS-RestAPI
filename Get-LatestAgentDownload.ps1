# Setup security and headers
$creds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("user:$(PersonalAccessToken)")))
$encodedAuthValue = "Basic $creds"
$acceptHeaderValue = "application/json;api-version=3.0-preview"
$headers = @{Authorization = $encodedAuthValue;Accept = $acceptHeaderValue }

# win7-x64 or linux-x64 or osx-x64
$vstsUrl = "$(VSTSAccount)/_apis/distributedtask/packages/agent?platform=$(AgentType)&`$top=1"
$response = Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $vstsUrl

# Do Rest-API call
$response = ConvertFrom-Json $response.Content
$url = $response.value[0].downloadUrl

# Update Variable
Write-Host "##vso[task.setvariable variable=AgentDownloadUrl]$url"
