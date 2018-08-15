Param(
    [string]$pat = $env:pat
)
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))

## CAUTION: This script can be dangerous if not fit purpose on your situation.
## REST-API calls can change and this script is not to be run on production unless
## you feel comfortable and take responsibility for it

# get all projects
$projects = (Invoke-RestMethod `
        -Uri "http://localhost:8080/tfs/Microsoft1/_apis/projects?api-version=2" `
        -Headers @{Authorization = "Basic $vstsauth"} `
        -Method Get `
        -ContentType "application/json").value.name

# for all projects get the queues save to queues.json
($projects | % { 
        Invoke-RestMethod `
            -Uri "http://localhost:8080/tfs/Microsoft1/$_/_apis/distributedtask/queues?api-version=3.2-preview" `
            -Headers @{Authorization = "Basic $auth"} `
            -Method Get `
            -ContentType "application/json" 
    }).value | ConvertTo-Json | sc queues.json