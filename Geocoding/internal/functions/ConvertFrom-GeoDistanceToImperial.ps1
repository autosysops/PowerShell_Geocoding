function ConvertFrom-GeoDistanceToImperial {
    <#
    .SYNOPSIS
        Convert a distance in meters to miles.

    .DESCRIPTION
        Converts a numeric distance from meters to miles and rounds the result
        to a configurable number of decimal places.

    .PARAMETER Meters
        The distance value in meters.

    .PARAMETER DecimalPlaces
        Number of decimal places to round the miles value to. Defaults to 2.

    .EXAMPLE
        Convert meters to miles

        PS> ConvertFrom-GeoDistanceToImperial -Meters 1609.344

        1
    #>

    [CmdLetBinding()]
    [OutputType([Double])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Double] $Meters,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateRange(0, 15)]
        [Int32] $DecimalPlaces = 2
    )

    # 1 mile is exactly 1609.344 meters.
    return [Math]::Round(($Meters / 1609.344), $DecimalPlaces)
}
