function Find-GeoCodeLocationNominatim {
    <#
    .SYNOPSIS
        Find a geographical location based on a query or coordinates in Open Street Maps.

    .DESCRIPTION
        Find a geographical location based on a query or coordinates in Open Street Maps.

    .PARAMETER Query
        A textual query for the location, this is what you would normally enter in the search bar for the map service. Can't be used together with Lat/Long.

    .PARAMETER Latitude
        The latitude as a float. Can't be used together with Query.

    .PARAMETER Longitude
        The longitude as a float. Can't be used together with Query.

    .PARAMETER DetailedAddress
        Split the address info into seperate attributes in the output.

    .PARAMETER Limit
        Limits the amount of results being returned.

    .PARAMETER Language
        The language of the returned values can be changed based on the language. Use a country code which is accepted in the header Accept-Language (like "en-US").

    .EXAMPLE
        Find based on query

        PS> Find-GeoCodeLocationNominatim -Query "Microsoft Building 92, NE 36th St, Redmond, WA 98052, United States"
    #>

    [CmdLetBinding()]
    [OutputType([Array])]

    Param (
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Query')]
        [String] $Query,

        [Alias("Lat")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Lon/Lat')]
        [Single] $Latitude,

        [Alias("Lon")]
        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Lon/Lat')]
        [Single] $Longitude,

        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'Lon/Lat')]
        [Switch] $DetailedAddress,

        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'Lon/Lat')]
        [Int32] $Limit,

        [Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $false, Position = 5, ParameterSetName = 'Lon/Lat')]
        [String] $Language = "en-US"
    )

    # Create the headers
    $headers = @{
        "accept-language" = $Language
    }

    switch($PsCmdlet.ParameterSetName) {
        "Query" {
            $uri = "https://nominatim.openstreetmap.org/search?q=$([System.Web.HttpUtility]::UrlEncode($Query))&format=jsonv2"

            if($Limit) {
                $uri += "&limit=$Limit"
            }
        }

        "Lon/Lat" {
            $uri = "https://nominatim.openstreetmap.org/reverse?lat=$Latitude&lon=$Longitude&format=jsonv2"
        }
    }

    if($DetailedAddress) {
        $uri += "&addressdetails=1"
    }

    Write-Debug "[OpenStreetMaps] Call uri: $uri"
    return Invoke-RestMethod -Uri $uri -Method GET -RetryIntervalSec 1 -MaximumRetryCount 5 -Headers $headers
}