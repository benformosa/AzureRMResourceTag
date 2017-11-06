<#
.SYNOPSIS
Report on tags applied to Azure Resources.

.DESCRIPTION
Returns an array of Azure Resources and their tags. Tags are listed as top-level properties.

.PARAMETER TagPrefix
Prefix the name of each tag with this string. Setting this to the empty string might cause problems if you have a tag name which is the same as a resource property name.

.PARAMETER VirtualMachines
Only report on Virtual Machines.

.PARAMETER Properties
Array of properties to include in the output. You probably want at least "ResourceID" in this array.

.OUTPUTS
pscustomobject[]

.LINK
Related command: Get-AzureRMResourceTag.ps1

See https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-using-tags for documentation on using tags.
#>

[CmdletBinding()]
param(
    [Switch]
    $VirtualMachines,
    
    [Parameter(HelpMessage="String to prefix tag name with.")]
    [string]
    $TagPrefix = "TAG_",
    
    [Parameter(HelpMessage="List of tag names which will not be returned.")]
    [string[]]
    $IgnoreTags = @(),
    
    [Parameter(HelpMessage="List of properties to return for each resource.")]
    [string[]]
    $Properties = @(
        "ResourceName"
        "ResourceGroupName"
        "ResourceID"
    )
)

begin {
    # Get a list of all Tag Names (Keys)
    $TagNames = (Get-AzureRmTag).Name | Where-Object {!$IgnoreTags.Contains($_)}

    # Array of custom objects to return
    $Resources = @()

    $VirtualMachinesFilter = {$_.ResourceType -eq "Microsoft.Compute/virtualMachines"}
    $AllFilter = {$_}
    $Filter = $AllFilter

    if ($VirtualMachines) {
        $Filter = $VirtualMachinesFilter
    }
}

process {
    # Get all Virtual Machine Resources
    foreach ($Resource in $(Get-AzureRMResource | Where-Object $Filter)) {

        # Create a custom object
        $Object = New-Object PSObject

        # Add a member for each Property
        foreach ($Property in $Properties) {
            $Object | Add-Member Noteproperty $Property $Resource.$Property
        }

        # Add a member for each TagName
        foreach ($TagName in $TagNames) {
            $Object | Add-Member Noteproperty "$TagPrefix$TagName" $Resource.Tags.$TagName
        }

        $Resources += $Object
    }
}

end {
    $Resources
}
