Param(
    [Parameter(Mandatory = $true)][string]$pat = $env:pat
)

## CAUTION: This script can be dangerous if not fit purpose on your situation.
## REST-API calls can change and this script is not to be run on production unless
## you feel comfortable and take responsibility for it

$ErrorActionPreference = "Stop"

$account = "<<YOUR VSTS ORGANIZATION>>"
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))

$tfsqueues = @{}
gc .\queues.json | ConvertFrom-Json | % { $tfsqueues[$_.id] = $_.name }

# Get all projects
$projects = (Invoke-RestMethod `
        -Uri "https://$account.visualstudio.com/_apis/projects" `
        -Headers @{Authorization = "Basic $auth" } `
        -Method Get `
        -ContentType "application/json").value.name

$projects | % {
    
    Write-Output "Project: $_" 
    $vstsqueues = @{}

    # Get all queues and based on previous names get the id's
    (Invoke-RestMethod `
            -Uri "https://$account.visualstudio.com/$_/_apis/distributedtask/queues" `
            -Headers @{Authorization = "Basic $auth"; Accept = "application/json; api-version=3.2-preview" } `
            -Method Get `
            -ContentType "application/json" -Verbose).value | % { $vstsqueues[$_.name] = $_.id }

    # get all the builds
    $builds = (Invoke-RestMethod `
            -Uri "https://$account.visualstudio.com/$_/_apis/build/definitions" `
            -Headers @{Authorization = "Basic $auth"; Accept = "application/json; api-version=4.1-preview.6" } `
            -Method Get `
            -ContentType "application/json").value

    # for non XAML builds (should not be returned anyway)
    $builds | Where-Object { $_.type -ne 'xaml' -and $_.queue.id -and $_.queue.name -eq '' } | % {
        Write-Output "  build: $($_.name)"

        # get the full build definition
        $build = Invoke-RestMethod `
            -Uri $_.url `
            -Headers @{Authorization = "Basic $auth"; Accept = "application/json; api-version=4.1-preview.6" } `
            -Method Get `
            -ContentType "application/json" 

        # get queue
        $queuename = $tfsqueues[$_.queue.id]
        Write-Output "    queue name: $queuename"

        # update build
        $build.queue = @{ id = $vstsqueues[$queuename] }

        # post changes
        Invoke-RestMethod `
            -Uri $_.url `
            -Headers @{Authorization = "Basic $auth"; Accept = "application/json; api-version=4.1-preview.6" } `
            -Method Put `
            -ContentType "application/json" `
            -Body ($build | ConvertTo-Json -Depth 100 -Compress) | Out-Null
    }
}