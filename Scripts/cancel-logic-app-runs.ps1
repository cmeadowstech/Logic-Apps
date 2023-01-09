
$runs = Get-AzLogicAppRunHistory -ResourceGroupName testWorkflow -Name testWorkflow -FollowNextPageLink |
        where Status -eq "Running"
$runs | Select WaitEndTime, StartTime, EndTime, Status, Name, Id |
        Export-Csv stalledRuns.csv -NoTypeInformation

Write-Host "There are $($runs.count) runs. A full report has been exported to the current directory."
$Confirmation = Read-Host -Prompt "Is this correct (y/n)? Confirm to proceed with cancellation."

$runs | 
    ForEach-Object -Parallel {
        Stop-AzLogicAppRun -ResourceGroupName testWorkflow -Name testWorkflow -RunName $_.Name -Force
    } -ThrottleLimit 100

