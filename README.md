# Okta-Named-Group-Report-Script
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
