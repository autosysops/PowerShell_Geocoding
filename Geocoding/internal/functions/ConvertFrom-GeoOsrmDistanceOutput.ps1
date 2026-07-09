function ConvertFrom-GeoOsrmDistanceOutput {
    <#
    .SYNOPSIS
        Convert route output from OSRM to uniform output format.

    .DESCRIPTION
        Convert route output from OSRM (Open Source Routing Machine) to the
        uniform distance output format used by Find-GeoCodeDistance.

    .PARAMETER Resource
        The raw response object returned by Find-GeoCodeDistanceOsrm.

    .EXAMPLE
        Convert the output

        PS> ConvertFrom-GeoOsrmDistanceOutput -Resource $output
    #>

    [CmdLetBinding()]
    [OutputType([Object])]

    Param (
        [Parameter(Mandatory = $true, Position = 1)]
        [Object] $Resource
    )

    Write-Debug "[OSRM] convert distance output"

    $route = $Resource.routes[0]

    return [PSCustomObject]@{
        "Distance"     = [PSCustomObject]@{
            "Meters" = [Math]::Round($route.distance, 0)
        }
        "Duration"     = [TimeSpan]::FromSeconds([Math]::Round($route.duration, 0))
        "TrafficDelay" = $null
    }
}