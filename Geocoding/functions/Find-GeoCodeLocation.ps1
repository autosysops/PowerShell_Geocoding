function Find-GeoCodeLocation {
    <#
    .SYNOPSIS
        Find a geographical location based on a query or coordinates.

    .DESCRIPTION
        Find a geographical location based on a query or coordinates. It supports multiple providers being: Open Street Maps, Bing Maps and Google Maps.

    .PARAMETER Query
        A textual query for the location, this is what you would normally enter in the search bar for the map service. Can't be used together with Lat/Long.

    .PARAMETER Latitude
        The latitude as a float. Can't be used together with Query.

    .PARAMETER Longitude
        The longitude as a float. Can't be used together with Query.

    .PARAMETER Provider
        The service to use to find the location. It supports Open Street Maps (OSM), Bing Maps (Bing), Azure Maps (Azure) and Google Maps (Google).
        To use Azure, Bing and Google an API key is required which needs to be requested via their service. Open Street Maps can be used without an API key.
        Default it will use Open Street Maps

    .PARAMETER Apikey
        Required when using Azure, Google or Bing. Needs to be entered as a string.

    .PARAMETER Limit
        Limits the amount of results being returned.

    .PARAMETER Language
        For Open Street Maps and Google the language of the returned values can be changed based on the language. Use a country code which is accepted in the header Accept-Language (like "en-US").

    .EXAMPLE
        Use OpenStreetMaps to query and return a single result

        PS> Find-GeoCodeLocation -Query "Microsoft Building 92, NE 36th St, Redmond, WA 98052, United States" -Provider OSM -Limit 1 | fl *

        Coordinates : @{Latitude=47.64249155; Longitude=-122.13692695171639}
        Address     : @{Street Address=Northeast 36th Street 15010; Locality=; Region=Washington; Postal Code=98052; Country=United States}
        Boundingbox : @{South Latitude=47.6413399; West Longitude=-122.1378316; North Latitude=47.6433901; East Longitude=-122.1365074}

    .EXAMPLE
        Use Bing Maps to query and return a single result

        PS> Find-GeoCodeLocation -Query "Microsoft Building 92, NE 36th St, Redmond, WA 98052, United States" -Provider Bing -Apikey <YOUR API KEY> -Limit 1 | fl *

        Coordinates : @{Latitude=47,642428; Longitude=-122,05937604}
        Address     : @{Street Address=NE 36th St; Locality=Redmond; Region=WA; Postal Code=98074; Country=United States}
        Boundingbox : @{South Latitude=47,6385652824306; West Longitude=-122,06701963172; North Latitude=47,646290717572; East Longitude=-122,051732453158}

    .EXAMPLE
        Use Google Maps to query and return a single result

        PS> Find-GeoCodeLocation -Query "Microsoft Building 92, NE 36th St, Redmond, WA 98052, United States" -Provider Google -Apikey <YOUR API KEY> -Limit 1 | fl *

        Coordinates : @{Latitude=47,6423109; Longitude=-122,1368406}
        Address     : @{Street Address=Northeast 36th Street 15010; Locality=Redmond; Region=Washington; Postal Code=System.Object[]; Country=United States}
        Boundingbox : @{South Latitude=47,6410083697085; West Longitude=-122,138480530292; North Latitude=47,6437063302915; East Longitude=-122,135782569708}

    .EXAMPLE
        Use Azure Maps to query and return a single result

        PS> Find-GeoCodeLocation -Query "Microsoft Building 92, NE 36th St, Redmond, WA 98052, United States" -Provider Azure -Apikey <YOUR API KEY> -Limit 1 | fl *

        Coordinates : @{Latitude=47,6423109; Longitude=-122,1368406}
        Address     : @{Street Address=Northeast 36th Street 15010; Locality=Redmond; Region=Washington; Postal Code=System.Object[]; Country=United States}
        Boundingbox : @{South Latitude=47,6410083697085; West Longitude=-122,138480530292; North Latitude=47,6437063302915; East Longitude=-122,135782569708}


    .EXAMPLE
        Use OpenStreetMaps to lookup coordinates and return a single result

        PS> Find-GeoCodeLocation -Latitude 38.75408328 -Longitude -78.13476563 -Provider OSM -Limit 1 | fl *

        Coordinates : @{Latitude=38.75186724786314; Longitude=-78.13181680294852}
        Address     : @{Street Address=Fodderstack Road ; Locality=; Region=Virginia; Postal Code=22747; Country=United States}
        Boundingbox : @{South Latitude=38.7196074; West Longitude=-78.1576132; North Latitude=38.7593864; East Longitude=-78.1236110}

    .EXAMPLE
        Use Bing Maps to lookup coordinates and return a single result

        PS> Find-GeoCodeLocation -Latitude 38.75408328 -Longitude -78.13476563 -Provider Bing -Apikey <YOUR API KEY> -Limit 1 | fl *

        Coordinates : @{Latitude=38,75408173; Longitude=-78,13477325}
        Address     : @{Street Address=; Locality=Hampton; Region=VA; Postal Code=22747; Country=United States}
        Boundingbox : @{South Latitude=38,7502190085035; West Longitude=-78,1413771887125; North Latitude=38,7579444436449; East Longitude=-78,1281693200765 }

    .EXAMPLE
        Use Google Maps to lookup coordinates and return a single result

        PS> Find-GeoCodeLocation -Latitude 38.75408328 -Longitude -78.13476563 -Provider Google -Apikey <YOUR API KEY> -Limit 1 | fl *

        Coordinates : @{Latitude=38,75408; Longitude=-78,13477}
        Address     : @{Street Address= ; Locality=Flint Hill; Region=Virginia; Postal Code=; Country=United States}
        Boundingbox : @{South Latitude=38,7527135197085; West Longitude=-78,1361614802915; North Latitude=38,7554114802915; East Longitude=-78,1334635197085 }

    .EXAMPLE
        Use Azure Maps to lookup coordinates and return a single result

        PS> Find-GeoCodeLocation -Latitude 38.75408328 -Longitude -78.13476563 -Provider Azure -Apikey <YOUR API KEY> -Limit 1 | fl *

        Coordinates : @{Latitude=38,75408; Longitude=-78,13477}
        Address     : @{Street Address= ; Locality=Flint Hill; Region=Virginia; Postal Code=; Country=United States}
        Boundingbox : @{South Latitude=38,7527135197085; West Longitude=-78,1361614802915; North Latitude=38,7554114802915; East Longitude=-78,1334635197085 }


    .NOTES
        Open Street Maps: https://nominatim.org/release-docs/latest/api/Overview/
        Bing Maps: https://learn.microsoft.com/en-us/bingmaps/rest-services/locations/
        Google Maps: https://developers.google.com/maps/documentation/geocoding
        Azure Maps: https://learn.microsoft.com/en-us/azure/azure-maps/about-azure-maps
    #>

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

        [ValidateSet('OpenStreetMaps', 'OSM', 'BingMaps', 'Bing', 'GoogleMaps', 'Google', "Azure", "AzureMaps")]
        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'Lon/Lat')]
        [String] $Provider = "OpenStreetMaps",

        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'Lon/Lat')]
        [Int32] $Limit,

        [Parameter(Mandatory = $false, Position = 4, ParameterSetName = 'Query')]
        [Parameter(Mandatory = $false, Position = 5, ParameterSetName = 'Lon/Lat')]
        [String] $Language = "en-US"
    )

    DynamicParam {
        if($Provider -in 'BingMaps', 'Bing', 'GoogleMaps', 'Google', "Azure", "AzureMaps") {
            $attribute = New-Object System.Management.Automation.ParameterAttribute
            $attribute.Mandatory = $true

            $collection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $collection.Add($attribute)

            $param = New-Object System.Management.Automation.RuntimeDefinedParameter('Apikey', [string], $collection)
            $dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $dictionary.Add('Apikey', $param)

            return $dictionary
        }
    }

    Process {
        # do actions for the right provider
        switch ($Provider) {
            { $_ -in "OpenStreetMaps", "OSM" } {
                Write-Debug "[OpenStreetMaps] start processing"
                Send-THEvent -ModuleName "Geocoding" -EventName "Find-GeoCodeLocation" -PropertiesHash @{Provider = "OSM" }

                # Create the parameters
                $splat = $PSBoundParameters
                $null = $splat.Remove("Provider")
                $splat.add("DetailedAddress",$true)

                # Query the provider for the results
                $res = Find-GeoCodeLocationNominatim @splat

                # Format the results in a uniform format
                $res = @($res | ForEach-Object {ConvertFrom-GeoNominatimOutput -Resource $_})

                # Return result
                return $res
            }

            { $_ -in "AzureMaps", "Azure" } {
                Write-Debug "[AzureMaps] start processing"
                Send-THEvent -ModuleName "Geocoding" -EventName "Find-GeoCodeLocation" -PropertiesHash @{Provider = "Azure" }

                # Create the parameters
                $splat = $PSBoundParameters
                $null = $splat.Remove("Provider")
                $null = $splat.Remove("Language")

                # Query the provider for the results
                $res = (Find-GeoCodeLocationAzureMaps @splat).features

                # Format the results in a uniform format
                $res = @($res | ForEach-Object {ConvertFrom-GeoAzureMapsOutput -Resource $_})

                # Return result
                return $res
            }

            { $_ -in "BingMaps", "Bing" } {
                Write-Debug "[BingMaps] start processing"
                Send-THEvent -ModuleName "Geocoding" -EventName "Find-GeoCodeLocation" -PropertiesHash @{Provider = "Bing" }

                # Create the parameters
                $splat = $PSBoundParameters
                $null = $splat.Remove("Provider")
                $null = $splat.Remove("Language")

                # Query the provider for the results
                $res = (Find-GeoCodeLocationBingMaps @splat).resourceSets.resources

                # Format the results in a uniform format
                $res = @($res | ForEach-Object {ConvertFrom-GeoBingMapsOutput -Resource $_})

                # Return result
                return $res
            }

            { $_ -in "GoogleMaps", "Google" } {
                Write-Debug "[GoogleMaps] start processing"
                Send-THEvent -ModuleName "Geocoding" -EventName "Find-GeoCodeLocation" -PropertiesHash @{Provider = "Google" }

                # Create the parameters
                $splat = $PSBoundParameters
                $null = $splat.Remove("Provider")
                $null = $splat.Remove("Limit")

                # Query the provider for the results
                $res = (Find-GeoCodeLocationGoogleMaps @splat).results

                if($Limit) {
                    $res = $res | Select-Object -First $Limit
                }

                # Format the results in a uniform format
                $res = @($res | ForEach-Object {ConvertFrom-GeoGoogleMapsOutput -Resource $_})

                # Return result
                return $res
            }
        }
    }
}