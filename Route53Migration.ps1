
<#

.SYNOPSIS
Updates an exported Route 53 resourcce record set file to be reimported to another Route 53 hosted zone.

.DESCRIPTION
Creates a new file of resource record sets ready to import from the file exported by the AWS CLI:

    aws route53 list-resource-record-sets --hosted-zone-id hosted-zone-id > path-to-output-file

Sets the Changes to be applied, and the ResoureRecordSets to be created, while excluding the NS for the root of the zone 
and the SOA resource records that are created when the new hosted zone is created. 

Private hosted zones are not currently supported.

The full procedure is detailed at: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-migrating.html

.PARAMETER InFolder 
The folder of hosted zone resource record sets previously exported via the AWS CLI

.PARAMETER OutFolder
The destination folder to create the resource record set converted files to be imported into the new hosted zones in the destination account

.EXAMPLE
Migrate all exported resource record sets exported previously to the .\source folder to new files in the .\destintion folder:

    Route53Migration.ps1 -InFolder .\source -OutFolder .\destination

.OUTPUTS
Each resource record included in the -OutFolder file is displayed, and the output file ready to create ResourceRecordSets.

.NOTES
Hosted zones in the destination account need to be created in advance.

#>

Param ([Parameter(Mandatory=$true)][string]$InFolder, 
    [Parameter(Mandatory=$true)][string]$OutFolder
)

Function MigrateResorceRecordSets{
([Parameter(Mandatory=$true)][string]$InFile, 
    [Parameter(Mandatory=$true)][string]$OutFile
)
    # Import JSON as PSObject
    $inputZoneZone = Get-Content $InFile | ConvertFrom-Json

    # Create an empty PSObject
    $outputZone = New-Object PSObject 
    $outputZone | Add-Member -type NoteProperty -name Changes -Value @()

    $domain = ""

    # Loop through ResourceRecordSets to fine SOA
    $inputZoneZone.ResourceRecordSets | ForEach-Object {
        # If  SOA record get the domain
        if ($_.Type -eq "SOA") {
            $domain = $_.Name
        }
    }

    if ($domain -ne "") {
        # Loop through ResourceRecordSets
        $inputZoneZone.ResourceRecordSets | ForEach-Object {
            # If not a NS of the root zone or the SOA record add it to the new object
            if ((($_.Type -eq "NS") -and ($_.Name -ne $domain)) -or (($_.Type -ne "SOA") -and ($_.Type -ne "NS"))) {
                Write-Host "Creating:" $domain $_.Name"($($_.Type))"
                # Create new PSObject
                $resourceRecord = New-Object PSObject 
                # Set the Action to CREATE
                $resourceRecord | Add-Member -type NoteProperty -name Action -Value "CREATE"
                # Set the ResourceRecordSet to the imported 
                $resourceRecord | Add-Member -type NoteProperty -name ResourceRecordSet -Value $_ 
                $outputZone.Changes += $resourceRecord
            } else {
                Write-Host "Excluding:" $domain $_.Name "($($_.Type))"
            }
        }
    }

    $outputZone | ConvertTo-Json -depth 10 | Set-Content -Path $OutFile
}

Get-ChildItem $InFolder | Foreach-Object {
    $inFile = $_.FullName
    $outFile = $OutFolder + "\" + $_.Name

    $result = MigrateResorceRecordSets -Infile $inFile -OutFile $outFile
}