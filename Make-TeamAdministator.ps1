function GetVSTSCredential () {
    Param(
        $UserEmail,
        $Token
    )

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $UserEmail, $Token)))
    return @{Authorization = ("Basic {0}" -f $base64AuthInfo)}
}
function Get-AllGroupsGraph() {
    Param(
        [Parameter(Mandatory = $true)] $userParams
    )
    
    try {
        
        # Base64-encodes the Personal Access Token (PAT) appropriately
        $authorization = GetVSTSCredential -Token $userParams.PAT -userEmail $userParams.userEmail

        # https://xpirit-jasper.vssps.visualstudio.com/_apis/graph/groups?api-version=5.0-preview
        # find all groups from Graph API
        $projectUri = "https://" + $userParams.VSTSAccount + ".vssps.visualstudio.com/_apis/graph/groups?api-version=5.0-preview"
        $response = Invoke-RestMethod -Uri $projectUri -Method Get -Headers $authorization 
        return $response
        
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error : " + $ErrorMessage  
    }
}
function Get-AllUsersGraph() {
    Param(
        [Parameter(Mandatory = $true)] $userParams
    )
    
    try {
        
        # Base64-encodes the Personal Access Token (PAT) appropriately
        $authorization = GetVSTSCredential -Token $userParams.PAT -userEmail $userParams.userEmail

        # https://xpirit-jasper.vssps.visualstudio.com/_apis/graph/users?api-version=5.0-preview
        # find all users from Graph API
        $projectUri = "https://" + $userParams.VSTSAccount + ".vssps.visualstudio.com/_apis/graph/users?api-version=5.0-preview"
        $response = Invoke-RestMethod -Uri $projectUri -Method Get -Headers $authorization 
        return $response
        
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error : " + $ErrorMessage  
    }
}
function Get-UsersStorageKey() {
    Param(
        [Parameter(Mandatory = $true)] $userParams,
        [Parameter(Mandatory = $true)] $User

    )
    
    try {
        
        # Base64-encodes the Personal Access Token (PAT) appropriately
        $authorization = GetVSTSCredential -Token $userParams.PAT -userEmail $userParams.userEmail

        $Uri = $user._Links.StorageKey.href

        # https://xpirit-jasper.vssps.visualstudio.com/_apis/graph/users?api-version=5.0-preview
        # find all users from Graph API
        $response = Invoke-RestMethod -Uri $Uri -Method Get -Headers $authorization 
        return $response.value
        
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error : " + $ErrorMessage  
    }
}
function Add-TeamAdministrator() {

    Param(
        [Parameter(Mandatory = $true)] $UserParams,
        [Parameter(Mandatory = $true)] $TeamId,
        [Parameter(Mandatory = $true)] $UserStorageKey
    )

    try {
        
        # Base64-encodes the Personal Access Token (PAT) appropriately
        $authorization = GetVSTSCredential -Token $UserParams.PAT -userEmail $UserParams.userEmail
          
        # add user to group
        $userData = @{
            teamId = $TeamId;
            newUsersJson = "[]";
            existingUsersJson = "[""$UserStorageKey""]" }

        $json = ConvertTo-Json -InputObject $userData

        # .visualstudio.com/TeamPermissions/_api/_identity/AddTeamAdmins?__v=5
        $Uri = "https://" + $userParams.VSTSAccount + ".visualstudio.com/TeamPermissions/_api/_identity/AddTeamAdmins?__v=5"
        $result = Invoke-RestMethod -Uri $Uri -Method Post -Headers $authorization -ContentType "application/json" -Body $json
        return $result
    }
    catch {
        Write-Host "Error : " + $_.ErrorDetails.Message
    }
}
function CreateTeamAdministrator() {

    Param(
        [Parameter(Mandatory = $true)] $TeamProjectName,
        [Parameter(Mandatory = $true)] $TeamName,
        [Parameter(Mandatory = $true)] $UserEmail
    )

    try {
        
        # Get the Origin for the Team 
        $groups = Get-AllGroupsGraph -UserParams $userParameters
        $group = $groups.value | Where-Object { $_.principalName -eq ("[{0}]\{1}" -f $TeamProjectName, $TeamName) } 

        # Get the users
        $users = Get-AllUsersGraph -UserParams $userParameters
        $user = $users.value | Where-Object { $_.mailAddress -eq $UserEmail } 

        # Get users Storage Key
        $userStorageKey = Get-UsersStorageKey -UserParams $userParameters -User $user

        # Add the Team Administrator
        $administors = Add-TeamAdministrator -UserParams $userParameters -TeamId $group.originid  -UserStorageKey $userStorageKey

        # List Team Admins
        $administors.admins | ForEach-Object {
            Write-Host ("Team Admin: {0} [{1}]" -f $_.FriendlyDisplayName, $_.MailAddress) -ForeGroundColor Yellow  
        }

    }
    catch {
        Write-Host "Error : " + $_.ErrorDetails.Message
    }
}

# #################################################################################################################################
# #################################################################################################################################
# #################################################################################################################################

# Load Security Settings JSON
$userDataFile = $PSScriptRoot + "\Security.json"
$userParameters = Get-Content -Path $userDataFile | ConvertFrom-Json

$TranscriptFile = (".\Logs\{0}-{1}-{2}.log" -f $MyInvocation.MyCommand.Name, $userParameters.VSTSAccount, (Get-Date -format  FileDateTimeUniversal) )
if (Test-Path -Path $TranscriptFile) {
    Remove-item $TranscriptFile -Force
}
Start-Transcript -Path $TranscriptFile

## Main Logic, define inputs
$TeamProjectName = "TeamPermissions"
$TeamName = "Team One"
$UserEmail = "emailaccount@host.com"

CreateTeamAdministrator -TeamProjectName $TeamProjectName -TeamName $TeamName -UserEmail $UserEmail

Stop-Transcript