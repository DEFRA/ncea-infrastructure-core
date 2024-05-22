<#
    .SYNOPSIS
        This Azure Automation runbook automates the scheduled shutdown and startup of an application gatweway in an Azure subscription. 

    .DESCRIPTION
        This is a PowerShell runbook, as opposed to a PowerShell Workflow runbook.
	Note that the Automation Account will need RBAC permission on the application gateway (scoped directly or inherited) in order to
	perform the start/stop operation.
    RBAC:
    'Virtual Machine Contributor' on Application Gateway instance for the system assigned managed identity. 
    'Network Contributor' on Application Gateway instance for the system assigned managed identity. 
    'reader' on Application Gateway instance for the system assigned managed identity. 


    .PARAMETER ResourceGroupName
        The name of the ResourceGroup where the AKS Cluster is located
    
    .PARAMETER AppGatewayName
        The name of the AKS Cluster to stop or start
    
    .PARAMETER Operation
        Currently supported operations are 'start' and 'stop'
    
    .INPUTS
        None.

    .OUTPUTS
        Human-readable informational and error messages produced during the job. Not intended to be consumed by another runbook.
#>

Param(
    	[parameter(Mandatory=$true)]
	[String] $ResourceGroupName,
    	[parameter(Mandatory=$true)]
	[String] $AppGatewayName,
        [parameter(Mandatory=$true)]
	[String] $AppGatewaySubscription,
    	[parameter(Mandatory=$true)]
	[ValidateSet('start','stop')]
    	[String]$Operation
)
	
try
{
	Disable-AzContextAutosave -Scope Process
		
	#System Managed Identity
	Write-Output "Logging into Azure using System Managed Identity"
	$AzureContext = (Connect-AzAccount -Identity -Subscription $AppGatewaySubscription).context
	$AzureContext = Set-AzContext -Subscription $AzureContext.subscription -DefaultProfile $AzureContext   
}
catch {
	Write-Error -Message $_.Exception
	throw $_.Exception
}

Write-Output "Performing $Operation"
switch -CaseSensitive ($Operation)
{
	'start'
	{
	Write-Output "Getting Application Gateway $AppGatewayName in $ResourceGroupName"
    $AppGateway=Get-AzApplicationGateway -Name $AppGatewayName -ResourceGroupName $ResourceGroupName
    #Write-Output $AppGateway
    Write-Output "Starting Application Gateway $AppGatewayName in $ResourceGroupName"
    Start-AzApplicationGateway -ApplicationGateway $AppGateway
	}
	'stop'
	{
        Write-Output "Stopping Application Gateway $AppGatewayName in $ResourceGroupName"
        $AppGateway=Get-AzApplicationGateway -Name $AppGatewayName -ResourceGroupName $ResourceGroupName
        Stop-AzApplicationGateway -ApplicationGateway $AppGateway
	}
}

