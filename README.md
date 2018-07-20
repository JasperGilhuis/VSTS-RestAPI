# VSTS-RestAPI
Several scripts that interact with the VSTS Rest API from PowerShell

## Security JSON
This script uses the Security JSON file for input of several parameters
- VSTS Account: The name of the Visual Studio Account this script runs against
- PAT: A personal access token that has permissions to run against the VSTS account specified

## Make Team Administrator
Script that contains several helper functions that need to be called in order to gather everything to add a team administrator.
This script is using undocumented API-calls and therefor may be subject to changes.

Information needed to create a team administrator are :
- Team Project name
- Team name 
- Email for the user you want to add.

The script first needs to get all the groups through the Graph API. This is needed to get the group ID for the team.
Secondly the user needs to be retrieved through the Graph API, this is in order to get the StorageKey for the user.
Having these values allows us to call a Rest API method to add the Team Administrator

The function lists the administrators available in the team as result

## Get Latest Agent Download Url
Script that helps to get the URL for the account your are targeting

The script requires a few parameters;

PersonalAccesToken - A PAT for the VSTS account you are targeting
VSTSAccount - The https://account.visualstudio.com url
AgentType - The REST API calls for the Agent Type requested, this could be one of three values; "linux-x64", "windows-x64" or "osx-x64"
The script updates a variable, AgentDownloadUrl, that can be used in the pipeline.

I use the script in a Inline PowerShell task
