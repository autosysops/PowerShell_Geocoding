function ConvertFrom-GeoBingMapsOutput {
    <#
    .SYNOPSIS
        Convert output from Bing Maps to uniform output format.

    .DESCRIPTION
        Convert output from Bing Maps to uniform output format.

    .PARAMETER Resource
        The output from Bing Maps

    .EXAMPLE
        Convert the output

        PS> ConvertFrom-GeoBingMapsOutput -Resource $output
    #>

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Object] $Resource
    )

    Write-Debug "[BingMaps] convert output"

    return [PSCustomObject]@{
        "Coordinates" = [PSCustomObject]@{
            "Latitude"  = $Resource.point.coordinates[0]
            "Longitude" = $Resource.point.coordinates[1]
        }
        "Address"     = [PSCustomObject]@{
            "Street Address" = $Resource.address.addressLine
            "Locality"       = $Resource.address.locality
            "Region"         = $Resource.address.adminDistrict
            "Postal Code"    = $Resource.address.postalCode
            "Country"        = $Resource.address.countryRegion
        }
        "Boundingbox" = [PSCustomObject]@{
            "South Latitude" = $Resource.bbox[0]
            "West Longitude" = $Resource.bbox[1]
            "North Latitude" = $Resource.bbox[2]
            "East Longitude" = $Resource.bbox[3]
        }
    }
}
