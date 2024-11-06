# VS Template Creator

PowerShell script to automate Visual Studio solution and project creation using DTE automation.

## Overview

This tool provides a simple way to create Visual Studio solutions and projects using PowerShell and Visual Studio DTE (Development Tools Environment) automation. Instead of manually creating projects through the Visual Studio GUI or using `dotnet new`, this script automates the process using Visual Studio's COM-based automation model.

## Features

- Create complete Visual Studio solutions from JSON configuration
- Support for multiple project types:
  - Console Applications
  - Windows Forms Applications
  - WPF Applications
  - Class Libraries
  - Unit Test Projects
- Automatic framework version configuration
- Git repository initialization (optional)
- Headless operation (no GUI required)

## Requirements

- Windows 10 or later
- PowerShell 5.1 or later
- Visual Studio 2019 Professional installed
- Administrator privileges (for COM automation)

## Installation

1. Clone this repository:

```powershell
git clone https://github.com/Foadsf/vstemplate-creator
```

2. Navigate to the directory:

```powershell
cd vstemplate-creator
```

## Usage

1. Create a configuration file (e.g., `config.json`):

```json
{
  "SolutionName": "MyEnterpriseSolution",
  "VersionControl": "git",
  "Projects": [
    {
      "Name": "MyEnterprise.UI",
      "Type": "wpf",
      "Framework": "net472"
    },
    {
      "Name": "MyEnterprise.Console",
      "Type": "console",
      "Framework": "net472"
    }
  ]
}
```

2. Run the script:

```powershell
.\CreateSolution.ps1 -ConfigPath ".\config.json" -Verbose
```

### Supported Project Types

- `console`: Console Application
- `wpf`: WPF Application
- `winforms`: Windows Forms Application
- `classlib`: Class Library
- `mstest`: MSTest Unit Test Project

### Supported Framework Versions

- `net48`: .NET Framework 4.8
- `net472`: .NET Framework 4.7.2
- `net471`: .NET Framework 4.7.1
- `net47`: .NET Framework 4.7
- `net462`: .NET Framework 4.6.2
- `net461`: .NET Framework 4.6.1
- `net46`: .NET Framework 4.6

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Copyright (C) 2024

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
