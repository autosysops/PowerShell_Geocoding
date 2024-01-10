function ConvertFrom-GeoNominatimOutput {
    <#
    .SYNOPSIS
        Convert output from Open Street Maps to uniform output format.

    .DESCRIPTION
        Convert output from Open Street Maps to uniform output format.

    .PARAMETER Resource
        The output from Open Street Maps

    .EXAMPLE
        Convert the output

        PS> ConvertFrom-GeoNominatimOutput -Resource $output
    #>

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Object] $Resource
    )

    Write-Debug "[OpenStreetMaps] convert output"

    return [PSCustomObject]@{
        "Coordinates" = [PSCustomObject]@{
            "Latitude"  = $Resource.lat
            "Longitude" = $Resource.lon
        }
        "Address"     = [PSCustomObject]@{
            "Street Address" = $Resource.address.road + " " + $Resource.address.house_number
            "Locality"       = $Resource.address.city
            "Region"         = $Resource.address.state
            "Postal Code"    = $Resource.address.postcode
            "Country"        = $Resource.address.country
        }
        "Boundingbox" = [PSCustomObject]@{
            "South Latitude" = $Resource.boundingbox[0]
            "West Longitude" = $Resource.boundingbox[2]
            "North Latitude" = $Resource.boundingbox[1]
            "East Longitude" = $Resource.boundingbox[3]
        }
    }
}
