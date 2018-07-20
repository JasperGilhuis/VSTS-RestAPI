# Agent Script
$script = 'curl -s $(AgentDownloadUrl) > /tmp/agent.tar.gz; for i in `seq 1 $(AgentsPerVM)`; do mkdir /agent$i && cd /agent$i && tar zxf /tmp/agent.tar.gz -C . && chmod -R 777 . && sudo -u $(AdminUserName) ./config.sh --unattended --url $(VSTSAccount) --auth pat --token $(PersonalAccessToken) --pool $(AgentPool) --agent $(AgentName)$i --work ./_work --runAsService && ./svc.sh install && ./svc.sh start ; done;'

$Bytes = [System.Text.Encoding]::UTF8.GetBytes($script)
$EncodedText =[Convert]::ToBase64String($Bytes)

# Update Variable
Write-Host "##vso[task.setvariable variable=EncodedScript;issecret=true]$EncodedText"
