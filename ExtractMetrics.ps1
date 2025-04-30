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
    [string]$QueryType
    [string]$entity
    [string]$attribute
}
 
$queryArray = @()
 
foreach ($section in $jsonReport.sections) {
    #Write-Host $section.displayName
    foreach ($visualContainer in $section.visualContainers){
        #Write-Host $visualContainer.y
        $jsonVisual = ConvertFrom-Json -InputObject $visualContainer.config
        foreach($query in $jsonVisual.singleVisual.prototypeQuery.Select){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.Name
            $row.QueryType = ($query.Column) ? "Column" : (($query.Measure) ? "Measure" : "")
            $queryArray += $row
        }
        foreach($query in $jsonVisual.singleVisual.projections.Y){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.Name
            $row.QueryType =  ($query.Column) ? "Column" : (($query.Measure) ? "Measure" : "")
            $queryArray += $row
        }
        foreach($query in $jsonVisual.singleVisual.projections.X){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.Name
            $row.QueryType =  ($query.Column) ? "Column" : (($query.Measure) ? "Measure" : "")
            $queryArray += $row
        }
        foreach($query in $jsonVisual.singleVisual.projections.Category){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.Name
            $row.QueryType =  ($query.Column) ? "Column" : (($query.Measure) ? "Measure" : "")
            $queryArray += $row
        }    
        foreach($query in $jsonVisual.singleVisual.projections.Series){
            $row = [QueryDetail]::new()
            $row.Section = $section.displayName
            $row.Visual = $jsonVisual.singleVisual.visualType
            $row.Query = $query.Name
            $row.QueryType =  ($query.Column) ? "Column" : (($query.Measure) ? "Measure" : "")
            $queryArray += $row
        }      
    }
}

#Output unprocessed data
$queryArray | Export-Csv -Path "Output.csv"


#Declare variable to capture output
$yamlOutput = @()

#Loop through items and build out test yaml
foreach ($q in $queryArray) {
    if ($q.Query -match "\.") 
    {
        $parts = $q.Query.Split('.')
        $q.entity = $parts[0]
        $q.attribute = $parts[1]
    }
        $daxMeasure = @"
EVALUATE ROW ("Output",'$($q.entity)'[$($q.attribute)])
"@

        $daxColumn = @"
EVALUATE ROW ("Output",FIRSTNONBLANKVALUE('$($q.entity)'[$($q.attribute)],1))
"@

        # Generate the DAX query
        $daxQuery = ($q.QueryType -eq "Measure") ? $daxMeasure : ($q.QueryType -eq "Column") ? $daxColumn : "" 

        # Build the YAML block
        $yamlBlock = @"
- Name: Check metric $($q.attribute) exists
  Description: > 
    Check metric exists and is available for visualisation.
  Data Source: SemanticModel
  Query: |
    $daxQuery
  Expectation: set is not empty
"@

    if ($q.attribute.length -gt 0) 
    {
        $yamlOutput += $yamlBlock
    }
}


# Combine under the root key 'Tests:'
$finalYaml = "Tests:`n" + ($yamlOutput -join "`n")

# Output to file
$finalYaml | Out-File -FilePath "MetricTests.yaml" -Encoding UTF8


