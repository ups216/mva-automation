Import-Module C:\IntelliTraceCollector\Microsoft.VisualStudio.IntelliTrace.PowerShell.dll
Start-IntelliTraceCollection `
    -ApplicationPool "DefaultAppPool" `
    -CollectionPlan "C:\IntelliTraceCollector\collection_plan.ASP.NET.default.xml" `
    -OutputPath "C:\IntelliTraceLogFiles" -Confirm:$false