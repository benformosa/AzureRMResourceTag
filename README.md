# AzureRMResourceTag

A tool to easily manage resource tags in Azure.

## Workflow

Tagging Azure resources is a good way to understand how they are used, and who is responsible for them. My Azure environment didn't use tags, so I developed this script to assign them.

The workflow I use with this script allows anyone to have input into the process without needing access to Azure, or even PowerShell.

1. Login to Azure PowerShell. I use [LoginAzure.ps1](https://github.com/benformosa/Toolbox/blob/master/Windows/LoginAzure.ps1) to make this easier.
2. Get a CSV of all resources and their tags:

    ```powershell
    Get-AzureRMResourceTag | Export-CSV -NoTypeInformation tags.csv
    ```

3. Share the CSV with your team using Office 365, network share or whatever.
4. Open the CSV with Excel and fill in the tags you want to set.
    * You can add extra tags by adding a column. Make sure you prepend the tag prefix (`TAG_` by default) to the tag name in the column heading.
5. Import the CSV and set tags on resources:

    ```powershell
    Import-CSV tags.csv | Set-AzureRMResourceTag
    ```
