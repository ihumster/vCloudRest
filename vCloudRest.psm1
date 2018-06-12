function Get-Connection {

    switch ($global:DefaultCIServers.Count) {        
        0 { throw "You are not currently connected to any servers. Please connect first using a Connect-CIServer cmdlet."; $null; break }
        1 { $global:DefaultCIServers[0]; break }
        Default { Menu $global:DefaultCIServers}
    }
}


function Invoke-vCloudRequest {
    #region Params
    [OutputType([xml])]
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Href,
        [parameter(Mandatory = $false)]
        $Body,
        [parameter(Mandatory = $false)]
        [string]$ContentType,
        [parameter(Mandatory = $true)]
        [ValidateSet("Get", "Post", "Put")]
        [string]$Method
    )
    #endregion
    
    $connection = Get-Connection

    if ($connection -ne $null -and $connection.IsConnected) {

        $webclient = New-Object System.Net.WebClient
        $webclient.Headers.Add("x-vcloud-authorization", $connection.SessionSecret)
        $webclient.Headers.Add("Accept", "application/*+xml;version=")
        $webclient.Headers.Add("Accept-Language: en")
        if ($ContentType) {
            $webclient.Headers.Add("Content-Type", $ContentType)
        }
        else {
            $webclient.Headers.Add("Content-Type", 'application/xml')
        }
    
        if ($method -ne "Get") {
            if ($Body -and $Body.gettype() -eq [string]) {
                [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($Body)
            }
            elseif ($Body -and $Body.gettype() -eq [xml]) {
                [byte[]]$byteArray = [System.Text.Encoding]::ASCII.GetBytes($Body.OuterXml)
            }
            else {
                throw "Body parameter has wrong type. Use [string] or [xml] types"
                Break
            }
        }
        switch ($Method) {
            "Get" {
                try {
                    [xml]$xmlResponse = $webclient.DownloadString([uri]::EscapeUriString($Href))
                }
                catch {
                    throw "An error occured attempting to make HTTP GET against $Href"
                }
                return $xmlResponse
            }
        
            "Post" {
                try {
                    $UploadData = $webclient.UploadData($Href, "POST", $bytearray)
                }
                catch {
                    throw "An error occured attempting to make HTTP POST against $Href"
                }
            }
            "Put" {
                try {
                    $UploadData = $webclient.UploadData($Href, "PUT", $bytearray)
                }
                catch {
                    throw "An error occured attempting to make HTTP PUT against $Href"
                }

            }
        }

    }
}
<#
.Synopsis
   Find objects in vCloud Database using Query Service
.DESCRIPTION
   Find objects in vCloud Database using Query Service
.EXAMPLE
   Find-vCloudObject -Format records -QueryType adminOrgVdcStorageProfile -Filter "name==my storage policy name"
.PARAMETER Filter
    Query Filter Expressions:

    ==   |  attribute==value  |  Matches. The example evaluates to true if attribute has a value that matches value in a case-sensitive comparison. Note Asterisk (*) characters that appear anywhere in value are treated as wildcards that match any character string. When value includes wildcards, the comparison with attribute becomes case-insensitive.

    !=   |  attribute!=value  |  Does not match. The example evaluates to true if attribute has a value that does not match value in a case-sensitive comparison. Wildcard characters are not allowed.

    ;    |  attribute1==value1;attribute2!=value2  |  Logical AND. The example evaluates to true only if attribute1 has a value that matches value1 and attribute2 has a value that does not match value2 in a case-sensitive comparison.
    
    ,    |  attribute1==value1,attribute2==value2  |  Logical OR. The example evaluates to true if attribute1 has a value that matches value1 or attribute2 has a value that matches value2 in a case-sensitive comparison.
    
    =gt= |  attribute=gt=value  |  Greater than. The example evaluates to true if attribute has a value that is greater than value. Both attribute and value must be of type int, long, or dateTime.
    
    =lt= |  attribute=lt=value  |  Less than. The example evaluates to true if attribute has a value that is less than value. Both attribute and value must be of type int, long, or dateTime.
    
    =ge= |  attribute=ge=value  |  Greater than or equal to. The example evaluates to true if attribute has a value that is greater than or equal to value. Both attribute and value must be of type int, long, or dateTime.

    =le= |  attribute=le=value  |  Less than or equal to. The example evaluates to true if attribute has a value that is less than or equal to value. Both attribute and value must be of type int, long, or dateTime.

.OUTPUTS
   Cmdlet return XML Object
#>
function Find-vCloudObject {
    #region Params
    [OutputType([xml])]
    [CmdletBinding()]
    Param(
        [ValidateSet("references", "records", "idrecords")]
        [string]$Format = "references",
        [parameter(Mandatory = $true)]
        [ValidateSet("aclRule", "adminAllocatedExternalAddress", "adminApiDefinition", "adminCatalog", "adminCatalogItem", "adminDisk", "adminEvent", "adminFileDescriptor", "adminGroup", "adminMedia", "adminOrgNetwork", "adminOrgVdc", "adminOrgVdcStorageProfile", "adminRole", "adminService", "adminShadowVM", "adminTask", "adminUser", "adminVApp", "adminVAppNetwork", "adminVAppTemplate", "adminVM", "adminVMDiskRelation", "apiDefinition", "apiFilter", "blockingTask", "cell", "condition", "datastore", "datastoreProviderVdcRelation", "dvSwitch", "edgeGateway", "event", "externalLocalization", "externalNetwork", "fileDescriptor", "fromCloudTunnel", "host", "networkPool", "organization", "orgVdcNetwork", "orgVdcResourcePoolRelation", "portgroup", "providerVdc", "providerVdcResourcePoolRelation", "providerVdcStorageProfile", "resourceClass", "resourceClassAction", "resourcePool", "resourcePoolVmList", "right", "role", "service", "serviceLink", "serviceResource", "strandedItem", "strandedUser", "task", "toCloudTunnel", "vAppOrgNetworkRelation", "vAppOrgVdcNetworkRelation", "vchsEdgeGateway", "vchsOrgVdcNetwork", "virtualCenter", "vmGroups", "vmGroupVms")]
        [string]$QueryType,
        [string]$Filter,
        [string]$PageSize = "25"
    )
    #endregion


    $connection = Get-Connection

    if ($connection -eq $null -and $connection.IsConnected) {
        Invoke-vCloudRequest -Href "$($connection.ServiceUri)/query?type=$QueryType&pageSize=$PageSize&format=$Format&filter=$Filter" -Method Get
    }

}

function Remove-vAppNetwork {
    #region Params
    [OutputType([xml])]
    [CmdletBinding()]
    Param(
        [parameter(Mandatory = $true)]
        [string]$OrgVdc,
        [parameter(Mandatory = $true)]
        [string]$vAppName,
        [parameter(Mandatory = $true)]
        [string]$NetworkName

    )
    #endregion

    $OrgVdcLink = Find-vCloudObject -QueryType adminOrgVdc -Filter "name==$OrgVdc"

    switch ($OrgVdcLink.AdminVdcReferences.total) {
        "0" {throw ("`"$OrgVdc`" not exists"); Break}
        "1" {
            $OrgVdcDef = Invoke-vCloudRequest -Method Get -Href $OrgVdcLink.AdminVdcReferences.AdminVdcReference.href

            if (($OrgVdcDef.AdminVdc.ResourceEntities.ResourceEntity | ? {$_.name -eq $vAppName -and $_.type -eq 'application/vnd.vmware.vcloud.vApp+xml'}) -ne $null) {
                    
                $vAppDef = Invoke-vCloudRequest -Href ($OrgVdcDef.AdminVdc.ResourceEntities.ResourceEntity | ? {$_.name -eq $vAppName -and $_.type -eq 'application/vnd.vmware.vcloud.vApp+xml'}).href -Method Get

                $question = "Delete `'$NetworkName`' from `'$vAppName`'?"
                $message = 'Are you sure you want to proceed?'

                $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
                $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList 'Yes'))
                $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

                if (($vAppDef.VApp.NetworkConfigSection.NetworkConfig | ? {$_.networkName -eq $NetworkName}) -ne $null) {
                        
                    $networkConfigSection = Invoke-vCloudRequest -Method Get -Href $vAppDef.vapp.NetworkConfigSection.href
                        
                    $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)

                    if ($decision -eq 0) {
                        if ($networkConfigSection.NetworkConfigSection.NetworkConfig -is [array]) {
                            $i = 0

                            for ($i; $i -le $networkConfigSection.NetworkConfigSection.NetworkConfig.Count - 1; $i++) {
                                if ($networkConfigSection.NetworkConfigSection.NetworkConfig[$i].networkName -eq $NetworkName) {
                                    $networkConfigSection.NetworkConfigSection.RemoveChild($networkConfigSection.NetworkConfigSection.NetworkConfig[$i])
                                }
                            }

                            Invoke-vCloudRequest -Method Put -Href $networkConfigSection.NetworkConfigSection.href -ContentType $networkConfigSection.NetworkConfigSection.type -Body $networkConfigSection

                        }
                        else {
                            if ($networkConfigSection.NetworkConfigSection.NetworkConfig.networkName -eq $NetworkName) {
                                $networkConfigSection.NetworkConfigSection.RemoveChild($networkConfigSection.NetworkConfigSection.NetworkConfig)
                            }

                            Invoke-vCloudRequest -Method Put -Href $networkConfigSection.NetworkConfigSection.href -ContentType $networkConfigSection.NetworkConfigSection.type -Body $networkConfigSection
                        }
                    }

                }
                else {
                    throw "`"$NetworkName`" not found in `"$vAppName`""
                }

            }
            else {

                throw "`"$vAppName`" not found in `"$OrgVdc`""
            }
        }#1

        default { throw "WTF??!" }

    } #switch
}

function Show-DatastoreThreasholds {

    $connection = Get-Connection

    $datastores = Invoke-vCloudRequest -Href "$($connection.ServiceUri)admin/extension/datastores" -Method Get

    $out = @()
    $i = 1
    foreach ($datastore in $datastores.DatastoreReferences.Reference) {
        $percent = [math]::Round($i / [int]$datastores.DatastoreReferences.Reference.Count * 100, 0)
        Write-Progress -Activity "Get info about $($datastore.Name)" -PercentComplete $percent
        $i++
        $ds = Invoke-vCloudRequest -Href $datastore.href -Method Get
        $obj = New-Object PSCustomObject -Property ([ordered]@{
                'Name'              = $datastore.Name;
                'ThresholdYellowGb' = $ds.Datastore.ThresholdYellowGb;
                'ThresholdRedGb'    = $ds.Datastore.ThresholdRedGb;
                'vCenterServer'     = $ds.Datastore.VimObjectRef.VimServerRef.name
            })
        $out += $obj

    }
    return $out
}



Export-ModuleMember -Function "Find-*", "Invoke-*", "Remove-*", "Show-*", "Get-*"