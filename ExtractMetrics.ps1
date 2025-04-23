##This code is for illustration purposes only and is NOT production ready code

# Save your pbix file as a pbip
# Specify the path to the JSON file
$jsonFilePath = ".\pbip\Sample Report - Taxi.Report\report.json"

# Read the JSON file and convert it to a PowerShell object
$jsonReport = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json
 
#Define an object that lets me capture the Section, Visual and queryRef values
class QueryDetail {
    [string]$Section
    [string]$Visual
    [string]$Query
}
 
$queryArray = @()
 
foreach ($section in $jsonReport.sections) {
    #Write-Host $section.displayName
    foreach ($visualContainer in $section.visualContainers){
        #Write-Host $visualContainer.y
        $jsonVisual = ConvertFrom-Json -InputObject $visualContainer.config
        foreach($query in $jsonVisual.singleVisual.projections.Values){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.queryRef
            $queryArray += $row
        }
        foreach($query in $jsonVisual.singleVisual.projections.Y){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.queryRef
            $queryArray += $row
        }
        foreach($query in $jsonVisual.singleVisual.projections.X){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.queryRef
            $queryArray += $row
        }
        foreach($query in $jsonVisual.singleVisual.projections.Category){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.queryRef
            $queryArray += $row
        }    
        foreach($query in $jsonVisual.singleVisual.projections.Series){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.queryRef
            $queryArray += $row
        }      
    }
}

#Transform the Query string to dax format
foreach ($q in $queryArray) {
    if ($q.Query -match "\.") {
        $parts = $q.Query.Split('.')
        $entity = $parts[0]
        $attribute = $parts[1]
        $q.Query = "'$entity'[$attribute]"
    }
}

#Output as a list 
#$queryArray | Export-Csv -Path ".\Ouput.csv" -NoTypeInformation

# Create a string builder to hold the full YAML content
$yamlOutput = @()

foreach ($q in $queryArray) {
    $yamlBlock = @"
- Name: Check metric exists
  Description: > 
    Check metric exists and is available for visualisation.
  Data Source: SemanticModel
  Query: |
    EVALUATE ROW("Output", $($q.Query) )
  Expectation: set is not empty
"@

    $yamlOutput += $yamlBlock
}

# Combine under the root key 'Tests:'
$finalYaml = "Tests:`n" + ($yamlOutput -join "`n")

# Output to file
$finalYaml | Out-File -FilePath "MetricTests.yaml" -Encoding UTF8


