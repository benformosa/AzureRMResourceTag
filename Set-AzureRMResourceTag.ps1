<#
.SYNOPSIS
Set tags on Azure Resources from array input.

.DESCRIPTION
Takes input in the format outputted by Get-AzureRMResourceTag.ps1, i.e. table-like objects with a ResourceID property, and any number of tag properties. Each tag property should have a name like <TagPrefix><TagName>, where TagPrefix is the value of the parameter TagPrefix, and TagName is the name (or key) of the tag to set.

.PARAMETER TagPrefix
Prefix the name of each tag with this string. Setting this to the empty string might cause problems if you have a tag name which is the same as another property name.

.INPUTS
object[]
An array of objects, e.g. the output from Get-AzureRMResourceTag.ps1, Import-CSV, Hashtables or PSCustomObjects, which have a ResourceID Property.

.EXAMPLE
Get-AzureRMResourceTag.ps1 | Export-CSV tags.csv
Import-CSV tags.csv | Set-AzureRMResourceTag.ps1

Export tag data to CSV, then set tags from CSV.

.EXAMPLE
@{
    ResourceId = "/subscriptions/subscription ID/providers/Microsoft.Sql/servers/ContosoServer/databases/ContosoDatabase"
    T-Dept = "Finance"
    T-Environment = "Test"
} | Set-AzureRMResourceTag.ps1 -TagPrefix "T-"

Set tags on a resource using a HashTable.

.LINK
Related command: Get-AzureRMResourceTag.ps1

See https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags for documentation on using tags.
#>

[CmdletBinding(SupportsShouldProcess=$True, ConfirmImpact='High')]
param(
    [Parameter(
        HelpMessage="Azure Resources to apply tags to",
        Position=0, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ]
    [object]
    $Resources,
    
    [Parameter(HelpMessage="String which tag names are prefixed with.")]
    [string]
    $TagPrefix = "TAG_"
)

process {
    foreach ($Resource in $Resources) {
        # Validate that the input has a ResourceID
        if ($Resource.ResourceID) {
            # Get the Azure-RMResource
            $AzureResource = Get-AzureRMResource -ResourceId $Resource.ResourceID
            # Don't continue if Get-AzureRMResource failed
            if ($AzureResource) {
                Write-Verbose "Starting $($AzureResource.ResourceName)"
                
                # Convert the input into a Hash
                $ResourceHash = @{}
                $Resource.psobject.properties | ForEach-Object {
                    $ResourceHash."$($_.Name)" = $_.Value
                }
                
                # Remove any keys that aren't tags
                $NotTags = $ResourceHash.Keys | Where-Object {! $_.StartsWith($TagPrefix)}
                $NotTags | ForEach-Object {
                    $ResourceHash.Remove($_)
                }
                
                # Remove "TAG_" from the Hash keys
                $Tags = @{}
                $ResourceHash.GetEnumerator() | ForEach-Object {
                    # Only set tags with values
                    if($_.Value) {
                        $Tags."$($_.Name.replace($TagPrefix,''))" = $_.Value
                    }
                }
                Write-Verbose "    Found $($Tags.count) tags"
                
                # Update the Azure Resource
                if ($PSCmdlet.ShouldProcess($AzureResource.ResourceID, "Apply tags")) {
                    Set-AzureRmResource -ResourceId $AzureResource.ResourceID -Tag $Tags -Force -Confirm:$False
                }
            } else {
                Write-Warning "Could not Get-AzureRMResource $($Resource.ResourceID)"
            }
        } else {
            Write-Warning "No ResourceID found"
        }
    }
}
