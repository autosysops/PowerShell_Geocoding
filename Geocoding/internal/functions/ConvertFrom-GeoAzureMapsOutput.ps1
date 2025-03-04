function ConvertFrom-GeoAzureMapsOutput {
    <#
    .SYNOPSIS
        Convert output from Azure Maps to uniform output format.

    .DESCRIPTION
        Convert output from Azure Maps to uniform output format.

    .PARAMETER Resource
        The output from Azure Maps

    .EXAMPLE
        Convert the output

        PS> ConvertFrom-GeoAzureMapsOutput -Resource $output
    #>

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Object] $Resource
    )

    Write-Debug "[AzureMaps] convert output"

    return [PSCustomObject]@{
        "Coordinates" = [PSCustomObject]@{
            "Latitude"  = $Resource.geometry.coordinates[1]
            "Longitude" = $Resource.geometry.coordinates[0]
        }
        "Address"     = [PSCustomObject]@{
            "Street Address" = if($Resource.properties.address.addressLine){$Resource.properties.address.addressLine}else{$null}
            "Locality"       = if($Resource.properties.address.locality){$Resource.properties.address.locality}else{$null}
            "Region"         = if($Resource.properties.address.adminDistricts[0].shortName){$Resource.properties.address.adminDistricts[0].shortName}else{$null}
            "Postal Code"    = if($Resource.properties.address.postalCode){$Resource.properties.address.postalCode}else{$null}
            "Country"        = if($Resource.properties.address.countryRegion.name){$Resource.properties.address.countryRegion.name}else{$null}
        }
        "Boundingbox" = [PSCustomObject]@{
            "South Latitude" = $Resource.bbox[1]
            "West Longitude" = $Resource.bbox[0]
            "North Latitude" = $Resource.bbox[3]
            "East Longitude" = $Resource.bbox[2]
        }
    }
}
