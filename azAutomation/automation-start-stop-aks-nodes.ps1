<#
    .SYNOPSIS
        This Azure Automation runbook automates the scheduled shutdown and startup of the VM scale set for an AKS Cluster in an Azure subscription. 

    .DESCRIPTION
        This is a PowerShell runbook, as opposed to a PowerShell Workflow runbook.
	Note that the Automation Account will need RBAC permission on the Cluster (scoped directly or inherited) in order to
	perform the start/stop operation.
    RBAC:
    Assign 'reader' permissions on the AKS instance for the automation account system managed identity.
    Assign 'Virtual Machine Contributor' on the AKS VM scale set for the automation account system managed identity.

    .PARAMETER ResourceGroupName
        The name of the ResourceGroup where the AKS Cluster is located
    
    .PARAMETER AksClusterName
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
	[String] $AksClusterName,
    	[parameter(Mandatory=$true)]
	[ValidateSet('start','stop')]
    	[String]$Operation
)
	
try
{
	Disable-AzContextAutosave -Scope Process
		
	#System Managed Identity
	Write-Output "Logging into Azure using System Managed Identity"
	$AzureContext = (Connect-AzAccount -Identity).context
	$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
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
	Write-Output "Starting VM Scale Set $AksClusterName in $ResourceGroupName"
    $AzCluster=Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $AksClusterName
    $AzVmss=Get-AzVmss -ResourceGroupName $AzCluster.NodeResourceGroup
    Start-AzVmss -ResourceGroupName $AzVmss.ResourceGroupName -VMScaleSetName $AzVmss.Name
	}
	'stop'
	{
	Write-Output "Stopping VM Scale Set $AksClusterName in $ResourceGroupName"
    $AzCluster=Get-AzAksCluster -ResourceGroupName $ResourceGroupName -Name $AksClusterName
    $AzVmss=Get-AzVmss -ResourceGroupName $AzCluster.NodeResourceGroup
    Stop-AzVmss -ResourceGroupName $AzVmss.ResourceGroupName -VMScaleSetName $AzVmss.Name -Force
	}
}
