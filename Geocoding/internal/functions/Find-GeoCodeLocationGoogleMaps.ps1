function Find-GeoCodeLocationGoogleMaps {
    <#
    .SYNOPSIS
        Find a geographical location based on a query or coordinates in Google Maps.

    .DESCRIPTION
        Find a geographical location based on a query or coordinates in Google Maps.

    .PARAMETER Query
        A textual query for the location, this is what you would normally enter in the search bar for the map service. Can't be used together with Lat/Long.

    .PARAMETER Latitude
        The latitude as a float. Can't be used together with Query.

    .PARAMETER Longitude
        The longitude as a float. Can't be used together with Query.

    .PARAMETER Apikey
        Apikey from Google

    .PARAMETER Language
        The language of the returned values can be changed based on the language. Use a country code which is accepted in the header Accept-Language (like "en-US").

    .EXAMPLE
        Find based on query

        PS> Find-GeoCodeLocationGooleMaps -Query "Microsoft Building 92, NE 36th St, Redmond, WA 98052, United States" -Apikey <YOUR API KEY>
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification='The product is called like this.')]

    [CmdLetBinding()]
    [OutputType([System.Object[]])]

    Param (
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Query')]
        [String] $Query,

        [Alias("Lat")]
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Lon/Lat')]
        [Single] $Latitude,

        [Alias("Lon")]
        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Lon/Lat')]
        [Single] $Longitude,

        [Parameter(Mandatory = $true, Position = 2, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $true, Position = 3, ParameterSetName = 'Lon/Lat')]
        [String] $ApiKey,

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
            $uri = "https://maps.googleapis.com/maps/api/geocode/json?address=$([System.Web.HttpUtility]::UrlEncode($Query))&key=$ApiKey"
        }

        "Lon/Lat" {
            $uri = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$($Latitude),$($Longitude)&key=$ApiKey"
        }
    }

    Write-Debug "[GoogleMaps] Call uri: $uri"
    return Invoke-RestMethod -Uri $uri -Method GET -RetryIntervalSec 1 -MaximumRetryCount 5 -Headers $headers
}