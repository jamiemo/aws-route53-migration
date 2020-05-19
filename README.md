
# aws-route53-migration

Curently only supports public hosted zones, no provision has been made for private hosted zones.

AWS Reference: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-migrating.html

## Export a list of hosted zones
From the AWS CLI list the HostedZone Id and Name for the existing (source) hosted zones:

  `aws route53 list-hosted-zones --output text --query "HostedZones[].[Id,Name]"`

## Export each hosted zone
From the AWS CLI for each hosted zone:

  `aws route53 list-resource-record-sets --hosted-zone-id <hosted-zone-id> > <path-to-output-file>`

## Migrate exported file for import (Route53Migration.ps1)
With all of the output files from above in a folder, run the following from an Administrative PowerShell command prompt:

  `.\Route53Migration.ps1 -InFolder <source folder>  -OutFolder <destination folder>`

## Create hosted zone in new account
From the AWS CLI for each hosted zone:

  `aws route53 create-hosted-zone --name <domain name> --caller-reference "%time%"`

##Export a list of hosted zones
From the AWS CLI list the HostedZone Id and Name of the newly created (destination) hosted zones:

  `aws route53 list-hosted-zones --output text --query "HostedZones[].[Id,Name]"`

## Import converted ResourceRecordSets
Using the converted text files from the destination directory to create the ResourceRecordSets.
From the AWS CLI for each hosted zone:

  `aws route53 change-resource-record-sets --hosted-zone-id <new zone id> --change-batch file://domain.com.txt`
