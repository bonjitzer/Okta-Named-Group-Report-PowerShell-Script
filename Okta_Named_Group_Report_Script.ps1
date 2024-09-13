<#
    Author: john.bitzer@proton.me
    Purpose: To provide a report of specific named Okta groups and the users within them.

    Instructions:
    This script assumes that you have your Okta API key(s) encrypted and stored in a file for retrieval using something like the following PS command:
    "OktaApiKey123" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\Temp\OktaApiKey.txt"

    This script looks for Okta groups that start with a given string. For example, if we give the string "Sales",
    And we have the following groups in Okta:
    "Sales_Oakland", "Sales_Internal", "SalesList" 
    this script will find all the groups that start with "Sales" and then find all the users within them.
        Use line 61 and 62 to see how this can be configured and define your group prefix there.


#>



# Okta API variables. Uncomment the environment you wish to work with, and comment the other environment when not in use.

# API Call Variables - Okta Preview
$oktaTenantUrl = "https://<preview_tenant>.oktapreview.com"
$oktaApiKey = Get-Content "C:\Temp\OktaApiKey.txt" | ConvertTo-SecureString

# API Call Variables - Okta Prod
# $oktaTenantUrl = "https://<prod_tenant>.okta.com"
# $oktaApiKey = Get-Content "C:\Temp\OktaApiKey.txt" | ConvertTo-SecureString

# Global Variables
$groupCsvLocation = "$HOME\Desktop\Okta_Named_Groups.csv"
$groupCsv = {} | Select "Group Name","Okta Group ID" | Export-CSV $groupCsvLocation -NoTypeInformation # creating initial CSV file
$groupCsvFile = Import-Csv $groupCsvLocation

$groupMembershipCsvLocation = "$HOME\Desktop\Okta_Named_Group_Membership.csv"
$groupMembershipCsv = {} | Select "groupName","firstName","lastName","email"| Export-CSV $groupMembershipCsvLocation -NoTypeInformation # creating initial CSV file
$groupMembershipCsvFile = Import-Csv $groupMembershipCsvLocation

$groupCounter = 0



function Write-Group-Csv {
    
    $groupCsvFile | Export-Csv $groupCsvLocation -Append -NoTypeInformation

}

function Write-Group-Memberships-Csv {

    $groupMembershipCsvFile | Export-Csv $groupMembershipCsvLocation -Append -NoTypeInformation

}

function Get-Named-Groups {
    
    # creaing an arrayList to store group UIDs to be used for querying membership
    $global:groupIds = New-Object -TypeName 'System.Collections.ArrayList'
    $global:groupNames = New-Object -TypeName 'System.Collections.ArrayList'

    #$uri = ($oktaTenantUrl+'/api/v1/groups?search=profile.name sw "Sales" ')
    $uri = ($oktaTenantUrl+'/api/v1/groups?search=profile.name sw "Sales" or profile.name sw "Accounting"')
    
    # Using the 'List Groups with Search' call from 'Groups (Okta API)' collection in Postman

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "SSWS " + $OktaApikey)
    
    # issue with TLS, enforcing 1.2 before calling GET method
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #$response = Invoke-RestMethod $uri -Method 'GET' -Headers $headers -UseBasicParsing
    #$response | ConvertTo-Json


    # calling the GET request
    $response = Invoke-WebRequest $uri -Method 'GET' -Headers $headers -UseBasicParsing
    
    ### Only needed when pagination is present
    <#
    # grabbing the next link that is returned in the the Headers to access the next page of results because of Okta's pagination only showing the first 20 results
    $nextPageLink = $response.Headers.Link.Split("<").Split(">")
    # setting uri to the next page link for use with next call
    $uri = $nextPageLink[3] 
    #>
       
        
    $responseContent = ConvertFrom-Json $response.Content

    #Write-Output $responseContent.profile.name
    
    # building groupName and groupId arrayLists
    foreach($group in $responseContent){
        $groupName = $group.profile.name
        $groupId = $group.id
        # using [void] to avoid .Add() function outputting the index each time it adds.
        [void]$groupIds.Add($groupId)
        [void]$groupNames.Add($groupName)

        $groupCsvFile."Group Name" = $groupName
        $groupCsvFile."Okta Group ID" = $groupId

        Write-Group-Csv

        $counter+=1

    }

}

function Get-Group-Memberships {

    
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "SSWS " + $OktaApikey)


    foreach ($group in $global:groupNames) {

        $groupID = $global:groupIds[$groupCounter]
        $response = Invoke-RestMethod ($oktaTenantUrl + '/api/v1/groups/' + $groupId + '/users') -Method 'GET' -Headers $headers
        $response | ConvertTo-Json | Out-Null
        
        $currentGroupName = $global:groupNames[$groupCounter]
        $groupMembershipCsvFile.groupName = $currentGroupName


        foreach ($user in $response) {

            $groupMembershipCsvFile.firstName = $user.profile.firstName
            $groupMembershipCsvFile.lastName = $user.profile.lastName
            $groupMembershipCsvFile.email = $user.profile.email
            
            # calling write function to write group membership information to CSV
            Write-Group-Memberships-Csv

            #Write-Host $responseContent    

        }
        
        $groupCounter += 1

        # pauses script to avoid API rate limit
        If($groupCounter -eq 400){
            Write-Host "Pausing to avoid API rate limit..."
            Start-Sleep 60

        }

    }

    

}

Get-Named-Groups
Get-Group-Memberships
