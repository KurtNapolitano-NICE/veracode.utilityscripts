
param(
    $vid, 
    $vkey)

$newTag = 'pairing'
$addPrefix = 'mattersight.pairing.'

function Get-AppId($applistxml, $appName) {
    foreach($app in $applistxml.applist.app) {
        if($app.app_name -eq $appName) {
            return $app.app_id
        }
    }

    return "<not_found>"
}

# download tool

if(!(Test-Path 'veracode.zip')) {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile("https://tools.veracode.com/integrations/API-Wrappers/C%23/bin/VeracodeC%23API.zip", "veracode.zip")

    if(Test-Path 'veracode') {
        Remove-Item veracode
    }
}

if(!(Test-Path 'veracode')) {
    Expand-Archive veracode.zip
}

$veracodeexe = '.\veracode\VeracodeC#API.exe'

$appNames = Get-Content app_names.txt

[xml]$applistxml = & $veracodeexe -vid $vid -vkey $vkey -action getapplist

foreach($appName in $appNames) {
    write-host Working on app: $appName 

    $appId = Get-AppId $applistxml $appName
    if($appId -eq '<not_found>') {
        Write-Host "Could not find app with name $appName" -ForegroundColor Yellow
        continue
    }

    [xml]$appinfoxml = & $veracodeexe -vid $vid -vkey $vkey -action getappinfo -appid $appId

    $tags = $appinfoxml.appinfo.application.tags
    if(!$tags.Contains($newTag))
    {
        $tags += ",$newTag"
    }

    $newName = $addPrefix + $appName
    
    & $veracodeexe -vid $vid -vkey $vkey -action updateapp -appid $appId  -criticality "High" -tags $tags
}