function Find-GeoCodeDistanceStraightLine {
    <#
    .SYNOPSIS
        Calculate straight-line distance between two coordinates.

    .DESCRIPTION
        Calculates the great-circle distance between an origin and destination
        coordinate using the Haversine formula.

    .PARAMETER OriginLatitude
        The latitude of the origin point.

    .PARAMETER OriginLongitude
        The longitude of the origin point.

    .PARAMETER DestinationLatitude
        The latitude of the destination point.

    .PARAMETER DestinationLongitude
        The longitude of the destination point.

    .EXAMPLE
        Calculate straight-line distance

        PS> Find-GeoCodeDistanceStraightLine -OriginLatitude 52.30 -OriginLongitude 4.75 -DestinationLatitude 53.56 -DestinationLongitude 9.92
    #>

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Double] $OriginLatitude,

        [Parameter(Mandatory = $true, Position = 2)]
        [Double] $OriginLongitude,

        [Parameter(Mandatory = $true, Position = 3)]
        [Double] $DestinationLatitude,

        [Parameter(Mandatory = $true, Position = 4)]
        [Double] $DestinationLongitude
    )

    # The trigonometric functions in .NET use radians, while geographic
    # coordinates are provided in degrees. A full circle is 360 degrees but
    # 2 * PI radians, so multiplying by PI and dividing by 180 converts a
    # degree value to the equivalent angle in radians.
    $earthRadiusMeters = 6371000

    $lat1 = $OriginLatitude * [Math]::PI / 180
    $lat2 = $DestinationLatitude * [Math]::PI / 180

    $dLat = ($DestinationLatitude - $OriginLatitude) * [Math]::PI / 180
    $dLon = ($DestinationLongitude - $OriginLongitude) * [Math]::PI / 180

    # Haversine uses half-angle terms (dLat/2 and dLon/2). This improves
    # numerical stability for short distances and is part of the standard
    # great-circle distance formula.
        $haversineComponent = [Math]::Sin($dLat / 2) * [Math]::Sin($dLat / 2) +
                         [Math]::Cos($lat1) * [Math]::Cos($lat2) *
                         [Math]::Sin($dLon / 2) * [Math]::Sin($dLon / 2)

        $centralAngleRadians = 2 * [Math]::Atan2([Math]::Sqrt($haversineComponent), [Math]::Sqrt(1 - $haversineComponent))
        $distanceMeters = [Math]::Round($earthRadiusMeters * $centralAngleRadians, 0)

    # No ConvertFrom-Geo* helper is needed because this function already
    # produces the module's normalized distance object directly.
    return [PSCustomObject]@{
        "Distance"     = [PSCustomObject]@{
            "Meters" = $distanceMeters
        }
        "Duration"     = $null
        "TrafficDelay" = $null
    }
}

