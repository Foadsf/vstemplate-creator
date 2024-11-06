# Example Configurations

This directory contains example JSON configuration files demonstrating different solution structures and use cases.

## Examples

1. **01-basic-console.json**

   - Simple console application
   - Basic configuration example
   - Single project solution

2. **02-wpf-with-library.json**

   - WPF application with supporting class library
   - Unit test project included
   - Common UI application structure

3. **03-enterprise-solution.json**

   - Complex enterprise solution structure
   - Multiple UI projects (WPF and WinForms)
   - Multiple class libraries
   - Separate test projects for unit and integration tests

4. **04-mixed-frameworks.json**

   - Solution with different framework versions
   - Demonstrates framework version flexibility
   - Mixed UI technologies

5. **05-testing-focused.json**
   - Testing-centric project structure
   - Multiple test projects for different testing levels
   - Demonstrates test project organization

## Usage

To use any of these examples:

1. Copy the desired JSON file to your working directory
2. Run the script:

```powershell
.\CreateSolution.ps1 -ConfigPath "example-file.json" -Verbose
```

## Note

These examples can be used as templates for your own configurations. Feel free to mix and match different aspects to create the solution structure that best fits your needs.
