# Remove
# Imports the last captured WIM to deployment share
# Updates the task sequence to point to the new OS

#Script variables
$root_dir = 'M:'
$os = 'Windows 10 x64'
$deploy_ts_name = 'deploy'

Add-PSSnapIn Microsoft.BDD.PSSnapIn
New-PSDrive -Name 'MDTShare' -PSProvider MDTProvider -Root "$root_dir\MDTFogDeploy" | Out-Null

#find last captured WIM
$latest_wim = (Get-ChildItem -Path "$root_dir\MDTBuildLab\Captures" | sort CreationTime | Select-Object -Last 1)

#generate name from wim name
$latest_wim_name = $latest_wim.Name.Replace('.wim','')

#TODO check it is recent & handle error

#import last captured WIM
#Import-MDTOperatingSystem -Path "MDTShare:\Operating Systems\$($os)" -SourceFile $latest_wim.FullName -DestinationFolder $latest_wim_name -Verbose

#get the guid of the new OS
$new_os_guid = (Get-ChildItem "MDTShare:\Operating Systems\$($os)" | ? { $_.Name -match $latest_wim_name }).guid

#open the task sequence XML file for editing
$ts_xml_path = "M:\MDTFogDeploy\Control\$deploy_ts_name\ts.xml"
$ts_xml = [xml]$(Get-Content $ts_xml_path)

#get the node containing OSGUID in the global vars section
$global_var_os_guid_node = ($ts_xml | Select-Xml -XPath "//sequence/globalVarList/variable[@name='OSGUID']").Node

#update the OSGUID properties
$global_var_os_guid_node | % {
    Write-Host "Updating global variables: $($_.'#text') to $new_os_guid"
    $_.'#text' = $new_os_guid
}

#get the node containing OSGUID in the OS install section
$install_os_guid_node = ($ts_xml | Select-Xml -XPath "//sequence/group[@name='Install']/step[@type='BDD_InstallOS']/defaultVarList/variable[@name='OSGUID']").Node

#update the OSGUID property
Write-Host "Updating install step variable: $($install_os_guid_node.'#text') to $new_os_guid"
$install_os_guid_node.'#text' = $new_os_guid

#save the XML
$ts_xml.Save($ts_xml_path)

#update the deployment share
Update-MDTDeploymentShare -path 'MDTShare:'

Remove-PSDrive -Name 'MDTShare'