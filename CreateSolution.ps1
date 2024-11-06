[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConfigPath
)

# Function to get project template path
function Get-ProjectTemplate {
    param (
        [string]$ProjectType,
        [string]$Framework,
        [string]$UIFramework = ""
    )
    
    $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional"
    $baseTemplatePath = Join-Path $vsPath "Common7\IDE\ProjectTemplates\CSharp"
    
    Write-Verbose "Searching for $ProjectType template..."
    
    # Define template paths based on project type
    $templatePaths = switch ($ProjectType) {
        "console" {
            @(
                "Windows\1033\ConsoleApplication\csConsoleApplication.vstemplate"
            )
        }
        "classlib" {
            @(
                "Windows\1033\ClassLibrary\csClassLibrary.vstemplate"
            )
        }
        "wpf" {
            @(
                "Windows\1033\WPFApplication\csWPFApplication.vstemplate"
            )
        }
        "winforms" {
            @(
                "Windows\1033\WindowsApplication\csWindowsApplication.vstemplate"
            )
        }
        "mstest" {
            @(
                "Test\1033\UnitTestProject\UnitTestProject.vstemplate"
            )
        }
        default {
            throw "Unsupported project type: $ProjectType"
        }
    }
    
    # Try to find template
    $template = $null
    foreach ($templatePath in $templatePaths) {
        $fullPath = Join-Path $baseTemplatePath $templatePath
        Write-Verbose "Checking template path: $fullPath"
        
        if (Test-Path $fullPath) {
            $template = $fullPath
            Write-Verbose "Found template: $template"
            break
        }
    }
    
    if (-not $template) {
        throw "Could not find template for project type: $ProjectType"
    }
    
    return $template
}

# Function to initialize version control
function Initialize-VersionControl {
    param (
        [string]$SolutionPath,
        [string]$VCSystem
    )
    
    switch ($VCSystem.ToLower()) {
        "git" {
            if (Get-Command git -ErrorAction SilentlyContinue) {
                Push-Location $solutionPath
                git init
                @"
.vs/
bin/
obj/
*.user
*.suo
packages/
*.dll
*.pdb
"@ | Out-File -FilePath .gitignore -Encoding utf8
                git add .
                git commit -m "Initial commit"
                Pop-Location
                Write-Verbose "Git repository initialized"
            }
            else {
                Write-Warning "Git is not installed. Skipping version control initialization."
            }
        }
        "svn" {
            Write-Warning "SVN initialization not implemented"
        }
        default {
            Write-Warning "No version control system specified or unsupported type: $VCSystem"
        }
    }
}

# Main function to create Visual Studio solution and projects
function New-VSTemplate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    $dte = $null
    
    try {
        # Read and validate configuration
        if (-not (Test-Path $ConfigPath)) {
            throw "Configuration file not found: $ConfigPath"
        }
        
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        
        if (-not $config.SolutionName) {
            throw "Solution name is required in configuration"
        }
        
        # Get or start Visual Studio DTE
        $dte = New-Object -ComObject VisualStudio.DTE.16.0
        $dte.SuppressUI = $true
        $dte.MainWindow.Visible = $false
        Start-Sleep -Seconds 5  # Give VS more time to initialize
        
        # Create solution
        $solutionPath = Join-Path $PWD $config.SolutionName
        New-Item -ItemType Directory -Path $solutionPath -Force | Out-Null
        
        Write-Verbose "Creating solution at: $solutionPath"
        $solution = $dte.Solution
        $solution.Create($solutionPath, $config.SolutionName)
        
        # Process each project
        foreach ($project in $config.Projects) {
            Write-Verbose "Creating project: $($project.Name)"
            try {
                $templatePath = Get-ProjectTemplate -ProjectType $project.Type -Framework $project.Framework
                Write-Verbose "Using template: $templatePath"
                
                $projectName = $project.Name
                $projectPath = Join-Path $solutionPath $projectName
                Write-Verbose "Project path: $projectPath"
                
                # Create project directory if it doesn't exist
                if (-not (Test-Path $projectPath)) {
                    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
                }

                # Get template folder path
                $templateFolder = Split-Path $templatePath -Parent
                
                # Add project to solution
                Write-Verbose "Adding project from template folder: $templateFolder"
                $proj = $solution.AddFromTemplate(
                    $templatePath,
                    $projectPath,
                    $projectName,
                    $false
                )
                
                # Check if project files were created, regardless of return value
                $projFile = Get-ChildItem -Path $projectPath -Filter "*.csproj" -Recurse | Select-Object -First 1
                if ($projFile) {
                    Write-Verbose "Project $projectName created successfully"
                    
                    # Update project framework
                    $projFile = Get-ChildItem -Path $projectPath -Filter "*.csproj" -Recurse | Select-Object -First 1
                    if ($projFile) {
                        try {
                            Write-Verbose "Updating framework in: $($projFile.FullName)"
                            [xml]$projXml = Get-Content $projFile.FullName
                            
                            # Find or create first PropertyGroup
                            $propertyGroup = $projXml.Project.PropertyGroup
                            if (-not $propertyGroup) {
                                $propertyGroup = $projXml.CreateElement("PropertyGroup")
                                [void]$projXml.Project.AppendChild($propertyGroup)
                            }
                            elseif ($propertyGroup -is [array]) {
                                $propertyGroup = $propertyGroup[0]
                            }
                            
                            # Map framework identifier to version
                            $frameworkVersion = switch -Regex ($project.Framework) {
                                'net48' { 'v4.8' }
                                'net472' { 'v4.7.2' }
                                'net471' { 'v4.7.1' }
                                'net47' { 'v4.7' }
                                'net462' { 'v4.6.2' }
                                'net461' { 'v4.6.1' }
                                'net46' { 'v4.6' }
                                default { 'v4.7.2' }  # Default to 4.7.2 if not specified
                            }
                            
                            # Update or create TargetFrameworkVersion element
                            $targetFrameworkVersion = $propertyGroup.SelectSingleNode("TargetFrameworkVersion")
                            if (-not $targetFrameworkVersion) {
                                $targetFrameworkVersion = $projXml.CreateElement("TargetFrameworkVersion")
                                [void]$propertyGroup.AppendChild($targetFrameworkVersion)
                            }
                            $targetFrameworkVersion.InnerText = $frameworkVersion
                            
                            # Save the changes
                            $projXml.Save($projFile.FullName)
                            Write-Verbose "Successfully updated framework version to $frameworkVersion"
                        }
                        catch {
                            Write-Verbose "Framework update warning (non-critical): $_"
                        }
                        Write-Verbose "Updated framework version to $frameworkVersion"
                    }
                }
                else {
                    Write-Warning "Could not find project file for $projectName"
                }
            }
            catch {
                Write-Warning "Failed to create project $($project.Name): $_"
                continue
            }
        }
        
        # Save solution
        $solutionFile = Join-Path $solutionPath "$($config.SolutionName).sln"
        Write-Verbose "Saving solution to: $solutionFile"
        $solution.SaveAs($solutionFile)
        
        # Initialize version control if specified
        if ($config.VersionControl) {
            Initialize-VersionControl -SolutionPath $solutionPath -VCSystem $config.VersionControl
        }
        
        Write-Host "Solution created successfully at: $solutionPath"
    }
    catch {
        Write-Error "Error creating template: $_"
        throw
    }
    finally {
        if ($dte) {
            Write-Verbose "Cleaning up Visual Studio instance..."
            try {
                $dte.Quit()
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($dte) | Out-Null
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
            }
            catch {
                Write-Warning "Error during cleanup: $_"
            }
        }
    }
}

# Main script execution
if ($MyInvocation.InvocationName -eq "&") {
    # Script is being dot-sourced
    Export-ModuleMember -Function New-VSTemplate
}
else {
    # Script is being run directly
    New-VSTemplate -ConfigPath $ConfigPath
}