function ConvertFrom-GeoGoogleMapsOutput {
    <#
    .SYNOPSIS
        Convert output from Google Maps to uniform output format.

    .DESCRIPTION
        Convert output from Google Maps to uniform output format.

    .PARAMETER Resource
        The output from Google Maps

    .EXAMPLE
        Convert the output

        PS> ConvertFrom-GeoGoogleMapsOutput -Resource $output
    #>

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Object] $Resource
    )

    Write-Debug "[GoogleMaps] convert output"

    return [PSCustomObject]@{
        "Coordinates" = [PSCustomObject]@{
            "Latitude"  = $Resource.geometry.location.lat
            "Longitude" = $Resource.geometry.location.lng
        }
        "Address"     = [PSCustomObject]@{
            "Street Address" = ($Resource.address_components | Where-Object {$_.types -like "*route*"}).long_name + " " + ($Resource.address_components | Where-Object {$_.types -like "*street_number*"}).long_name
            "Locality"       = ($Resource.address_components | Where-Object {$_.types -like "*locality*"}).long_name
            "Region"         = ($Resource.address_components | Where-Object {$_.types -like "*administrative_area_level_1*"}).long_name
            "Postal Code"    = ($Resource.address_components | Where-Object {$_.types -like "*postal_code*"}).long_name
            "Country"        = ($Resource.address_components | Where-Object {$_.types -like "*country*"}).long_name
        }
        "Boundingbox" = [PSCustomObject]@{
            "South Latitude" = $Resource.geometry.viewport.southwest.lat
            "West Longitude" = $Resource.geometry.viewport.southwest.lng
            "North Latitude" = $Resource.geometry.viewport.northeast.lat
            "East Longitude" = $Resource.geometry.viewport.northeast.lng
        }
    }
}
