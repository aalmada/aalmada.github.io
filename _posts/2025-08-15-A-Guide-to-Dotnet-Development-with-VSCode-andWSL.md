---
layout: post
read_time: true
show_date: true
title: "Harnessing WSL for Modern .NET Development with VS Code, Docker, and Aspire"
date: 2025-08-15
img_path: /assets/img/posts/20250815
image: Infinite.jpg
tags:
  [dotnet, aspire, wsl, vscode, docker, cloud-native, development]
category: development
meta_description: "Discover how to harness WSL (Windows Subsystem for Linux) for modern .NET development. This guide walks you through setting up Visual Studio Code, Docker, and Aspire inside WSL, enabling a seamless Linux-powered workflow for building cloud-native .NET applications on Windows."
---

WSL (Windows Subsystem for Linux) lets you run a full Linux environment alongside Windows, improving the development experience and making it easy to use Linux-native tools. With Docker installed in WSL and Aspire orchestrating cloud-native .NET apps, you get an excellent cloud-first development setup, everything runs locally but is ready to deploy to the cloud.

This guide covers setting up Visual Studio Code, .NET, Docker, and Aspire inside WSL for a practical workflow to build and run cloud-native .NET applications. Whether starting fresh or updating your setup, these steps help you get the most out of WSL integration.

---

## What Is WSL?

WSL (Windows Subsystem for Linux) is a compatibility layer that lets you run a full Linux distribution directly on Windows—without the need for a virtual machine. It’s fast, lightweight, and deeply integrated into the Windows ecosystem.

---

## Preparing Your Environment

Before installing WSL and a Linux distribution, make sure your system is ready.

### Step 1: Install Windows Terminal

Windows Terminal provides a modern, tabbed interface for working with PowerShell, Command Prompt, and WSL. It’s the recommended way to interact with your Linux environment.

To install:

1. Open the **Microsoft Store**.
2. Search for **Windows Terminal**.
3. Click **Install** or **Update** to ensure you have the latest version.

Once installed, you can launch it from the Start menu or pin it to your taskbar.

---

### Checking and Updating WSL

Before installing a Linux distribution, it's a good idea to make sure WSL is installed and up to date.

#### Check if WSL Is Installed

Open **PowerShell** or **Windows Terminal** and run:

```powershell
wsl --list --verbose
```

If WSL is installed, this will show a list of distributions and their WSL versions (either 1 or 2). If not, you'll see an error message.

#### Check WSL Platform Version

To check the installed version of the WSL platform itself (available on Windows 11 and newer versions of Windows 10):

```powershell
wsl --version
```

This displays the WSL version and kernel details.

#### Update WSL

To update WSL to the latest version:

```powershell
wsl --update
```

This updates the WSL kernel and related components. You should do this periodically to get the latest updates.

#### Install WSL (if not already installed)

If WSL isn’t installed yet, you can install it with:

```powershell
wsl --install
```

This command installs WSL and sets up a default Linux distribution. You can later install additional distributions from the Microsoft Store.

For more details, visit [Microsoft’s official WSL documentation](https://learn.microsoft.com/en-us/windows/wsl/install).

---

## Installing a Linux Distribution with WSL

Once WSL is installed and updated, you can install a Linux distribution of your choice—such as **Ubuntu**, **Debian**, or **Fedora**—directly from the **Microsoft Store**.

### Steps to Install Linux from the Microsoft Store

1. **Open the Microsoft Store**  
   - Click the **Start** button and search for “Microsoft Store,” then open it.

2. **Search for a Linux Distribution**  
   - In the Store’s search bar, type the name of the distribution you want to install (e.g., “Ubuntu”, “Debian”, “Kali Linux”, “Fedora Remix” or any other available).

> **Note:** This guide focuses on Ubuntu, which is the most widely used and well-supported distribution for WSL. While other distributions like Debian, Fedora, and Kali Linux are available, some steps and commands may differ. For best compatibility and community support, Ubuntu is recommended—especially if you’re new to WSL.

3. **Select and Install**  
   - Click on the distribution you want from the search results.
   - Hit the **Install** button. The download and installation process will begin automatically.

4. **Launch the Distribution**  
   - Once installed, click **Launch** from the Store page, or find it in the Start Menu by searching for its name.
   - The first time you launch it, WSL will initialize the Linux environment and prompt you to create a **username and password** for your Linux user account.

> 🛠️ **Next Steps**: After installation, it's important to update your Linux system to ensure compatibility and prevent issues with outdated packages. This process is explained in the following section.

---

## Launching the Linux Terminal

You can open your Linux terminal in one of the following ways:

- **Start Menu**: Click the Start button, search for your installed distribution (e.g., "Ubuntu"), and select it.
- **Windows Terminal**: Open Windows Terminal and click the dropdown arrow next to the tab bar. Choose your Linux distribution from the list.

This will launch your Linux shell and initialize the environment if it's the first time you're running it.

---

## Updating Your Linux System

Once the terminal is open, run the following command to update your package lists and upgrade installed packages:

```bash
sudo apt update && sudo apt upgrade -y
```

This step is essential to ensure your system is current and ready for additional software installations.

---

## Accessing Files Across Windows and Linux

WSL provides seamless file access between Windows and Linux environments, allowing you to work across systems without manual syncing or duplication.

### Using Windows Explorer

You can browse your Linux file system directly from Windows Explorer:

- Scroll down the sidebar and look for a Linux icon labeled with your distribution’s name (e.g., "Ubuntu").
- Click it to open your Linux home directory and interact with files just like any other folder.

Alternatively, you can use the UNC path:

```bash
\\wsl$\Ubuntu\home\your-username
```

This lets you open Linux files in Windows applications or transfer files between systems.

### Using the Linux Terminal

Windows drives are mounted under the `/mnt` directory in your Linux environment. You can access and manipulate Windows files from the Linux terminal:

```bash
# Navigate to your Windows Documents folder
cd /mnt/c/Users/YourUsername/Documents

# List files
ls

# Copy a file from Windows to Linux
cp /mnt/c/Users/YourUsername/Documents/example.txt ~/example.txt

# Copy a file from Linux to Windows
cp ~/script.sh /mnt/c/Users/YourUsername/Desktop/script.sh
```

This integration makes it easy to move files, edit code, and run scripts across both platforms.

---

## Installing .NET in WSL

To develop .NET applications inside WSL (Windows Subsystem for Linux), you’ll need to install the .NET SDK within your Linux environment. The recommended method is using Microsoft’s official install script.

### Installation Instructions

Installation steps vary depending on your Linux distribution. For the most accurate and up-to-date instructions, refer to the official guide:

[Scripted .NET Installation for Linux](https://learn.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual)

Once the script is downloaded and made executable (as described on that page), you can run it using the following examples:

- To install the latest **LTS** (Long-Term Support) version of .NET:

  ```bash
  ./dotnet-install.sh --channel LTS
  ```

- To install the **latest .NET 9 SDK** (non-LTS):

  ```bash
  ./dotnet-install.sh --channel 9.0
  ```

- To install a **specific patch version**, such as .NET SDK 9.0.100:

  ```bash
  ./dotnet-install.sh --version 9.0.100
  ```

Full documentation for the install script is available at  
[dotnet-install script reference on Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script)

### Making the `dotnet` Command Available

By default, the install script places the .NET SDK in your home directory (`~/.dotnet`). The environment variables it sets are only active for your current terminal session. To make the `dotnet` command available every time you open a terminal, add the appropriate configuration to your shell profile file.

Linux supports several shells, each with its own profile file:

- **Bash**: `~/.bashrc`
- **Zsh**: `~/.zshrc`
- **Fish**: `~/.config/fish/config.fish`

Add the following lines to your profile (adjust for your shell):

```bash
# .NET SDK and global tools setup
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
```

### Example: Using Nano to Update Your Bash Profile

To add the .NET SDK path to your Bash profile using `nano`:

1. Open your Bash profile in nano:

  ```bash
  nano ~/.bashrc
  ```

2. Add the lines at the end of the file:

3. Save and exit nano:
  - Press `Ctrl+O` to write changes.
  - Press `Enter` to confirm.
  - Press `Ctrl+X` to exit.

4. Reload your profile:

  ```bash
  source ~/.bashrc
  ```

After updating your profile, reload your shell configuration or restart your terminal to apply the changes.

### Managing SDK Versions

- You can install multiple SDK versions side by side.
- To list all installed SDKs:

  ```bash
  dotnet --list-sdks
  ```

### Uninstalling SDKs

If you need to remove a previously installed SDK version, refer to the official guidance for Linux environments:

[Removing .NET SDKs and runtimes on Linux – Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/core/install/remove-runtime-sdk-versions?pivots=os-linux#scripted-or-manual)

---

## Opening WSL Projects in VS Code

You can open your WSL-hosted .NET project in Visual Studio Code using either of the following methods.

### Option 1: Using Windows Terminal

1. Launch your Linux distribution from the terminal

1. Navigate to your project folder using the command

   ```bash
   cd ~/projects/my-dotnet-app
   ```

1. Enter the command:

   ```bash
   code .
   ```

4. If the WSL extension is not installed, Visual Studio Code will prompt you to install it

### Option 2: Using Visual Studio Code on Windows

1. Open Visual Studio Code

1. Install the WSL extension if it is not already installed

1. Click the WSL indicator on the left side of the Visual Studio Code footer

1. Select "Connect to WSL"

1. Once connected, go to File > Open Folder and choose your project directory inside WSL

In both cases, Visual Studio Code runs as if it is inside your Linux environment. When you open a new terminal in Visual Studio Code, it will automatically start in your WSL project folder.

> To confirm that Visual Studio Code is connected to WSL, check the left side of the footer. It should display the name of your active Linux distribution.

---

## Installing Docker in WSL (Without Docker Desktop)

Docker is a powerful tool for .NET developers. It streamlines development workflows by:

- Running local databases and service dependencies  
- Packaging and deploying applications consistently across environments  
- Orchestrating multi-container setups with Docker Compose  

Instead of relying on Docker Desktop, you can install Docker directly inside your WSL distribution for a native Linux experience. This setup is lightweight, efficient, and ideal for developers who prefer working entirely within WSL.

---

### Step 1: Install Docker in WSL

To set up Docker within your WSL distribution (such as Ubuntu), refer to the official [installing Docker Engine on Linux](https://docs.docker.com/engine/install/). TThis documentation provides step-by-step instructions for all major distributions and ensures you're installing the most up-to-date and supported components.

- Installing Docker through this method includes:

- Docker Engine

- Docker Command Line Interface (CLI)

- Docker Compose plugin

- Buildx for advanced build capabilities

---

### Step 2: Enable systemd and Configure Docker Autostart

Recent versions of WSL support systemd, which allows services like Docker to run automatically. To enable it:

1. Open your WSL terminal and edit the `/etc/wsl.conf` file:

   ```bash
   sudo nano /etc/wsl.conf
   ```

2. Add the following content:

   ```ini
   [boot]
   systemd=true
   ```

3. Save and exit, then shut down all WSL instances:

   ```bash
   wsl --shutdown
   ```

4. Restart your WSL distribution. Systemd will now be active.

To enable Docker to start automatically with systemd:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

---

### Step 3: Configure Permissions

Add your user to the Docker group to avoid using `sudo`:

```bash
sudo usermod -aG docker $USER
```

Restart your WSL session:

```bash
exit
```

Reopen your terminal and test Docker:

```bash
docker version
docker run hello-world
```

If you see the success message, Docker is running correctly inside WSL.

---

### Managing Containers with Visual Studio Code

To manage Docker containers visually, install the **Container Tools** extension in Visual Studio Code. This extension, published by Microsoft, provides a graphical interface for working with containers directly from the editor.

#### Installation Steps

1. Open Visual Studio Code.
2. Navigate to the Extensions view (`Ctrl+Shift+X`).
3. Search for **Container Tools** and install the extension published by Microsoft.
4. Open the **Containers** panel from the sidebar.

Alternatively, you can install it from the command line:

```bash
code --install-extension ms-azuretools.vscode-containers
```

#### Features

The Container Tools extension enables you to:

- View and manage running containers
- Inspect logs and monitor resource usage
- Start, stop, restart, and remove containers
- Explore container file systems
- Access container-related commands via the Command Palette

It integrates seamlessly with Docker running inside WSL, provided that VS Code is connected to your WSL environment.

---

## Installing the C# Extension for Visual Studio Code

To work with C# projects in VS Code, you need the **C# extension**. There are two main options:

- **C# Extension**:  
  Free and open-source, provides core C# language support, debugging, and basic project features.

- **C# Dev Kit Extension**:  
  Adds advanced features like project management, solution explorer, and richer diagnostics.  
  **Note:** C# Dev Kit is free for individuals, academia, and open-source development, but **not free for organizations**.  
  Be sure to read the [license terms](https://code.visualstudio.com/docs/csharp/cs-dev-kit-faq#_licensing-and-contributing) before installing in a commercial setting.

### How to Install the C# Extension

1. Open Visual Studio Code.
2. Go to the Extensions view (`Ctrl+Shift+X`).
3. Search for **"C#"** or **"C# Dev Kit"** and install your preferred extension.

Alternatively, install from the command line:

```bash
code --install-extension ms-dotnettools.csharp
# or for Dev Kit:
code --install-extension ms-dotnettools.csdevkit
```

Both extensions automatically install the **.NET Install Tool** extension, which helps manage .NET SDKs. However, **the .NET Install Tool does not support WSL**—which is why you needed to install .NET manually in the previous steps.

> **Note:** If you plan to work with other .NET languages, such as F#, you will need different extensions. For example, the [Ionide](https://marketplace.visualstudio.com/items?itemName=Ionide.Ionide-fsharp) extension provides support for F# development in Visual Studio Code. Be sure to install the appropriate extension for your language.

---

## Extending Your Environment with Aspire

Once Docker is up and running inside WSL, you’re well-positioned to take advantage of Aspire—a new .NET stack designed for building cloud-native applications. Aspire simplifies the development of distributed systems by coordinating multiple services, integrating with common infrastructure components, and offering consistent tooling through the .NET CLI.

### Key Capabilities

- **App Host orchestration**: Aspire’s App Host manages service startup, configuration, and discovery.
- **Rich integrations**: Built-in support for Redis, PostgreSQL, MongoDB, and OpenTelemetry.
- **Consistent tooling**: Uses familiar .NET CLI commands and templates for scaffolding and running apps.

This makes Aspire a natural fit for WSL-based development, especially when combined with Docker for containerized services.

---

### Installing Aspire in WSL

You can run the following commands either:

- In a **Linux tab of Windows Terminal** (e.g., Ubuntu running under WSL), or  
- Inside a **terminal panel in Visual Studio Code**, provided it’s connected to your WSL distribution.

#### Step 1: Install the Aspire Workload

```bash
dotnet workload install aspire
```

This installs Aspire’s CLI tools and templates.

#### Step 2: Verify Installation

```bash
dotnet new aspire --list
```

You should see templates like `aspire-apphost`, `aspire-webapi`, and `aspire-worker`.

---

#### Aspire Extension for VS Code

If you're using Visual Studio Code, the Aspire extension adds helpful commands to the Command Palette, making it easier to work with Aspire projects directly from the editor. You can install it from the Extensions Marketplace by searching for `"Aspire"` or via the command line:

```bash
code --install-extension microsoft-aspire.aspire-vscode
```

Once installed, you'll gain access to commands like:

- Creating new Aspire projects  
- Running the App Host  
- Navigating infrastructure components  
- Opening the Aspire dashboard

These commands are available via the Command Palette (`Ctrl+Shift+P`), making it easy to manage Aspire projects without switching to the terminal.

---

#### Step 3: Create and Run an Aspire Project

You can create and run an Aspire project using either:

- The **command line interface (CLI)**:

  ```bash
  dotnet new aspire-starter -n MyAspireApp
  cd MyAspireApp
  aspire run
  ```

- Or the **Command Palette in Visual Studio Code**:
  - Open the palette (`Ctrl+Shift+P`)
  - Search for `Aspire: Create New Project`
  - Follow the prompts to generate and run the project

The `aspire run` command (or its equivalent in the extension) automatically locates the App Host and starts all configured services, including any containers defined in the infrastructure.

---

### Visualizing the Running Infrastructure

Once the project is running, you have two main ways to explore the infrastructure:

- **Container Tools Extension in Visual Studio Code**  
  This extension shows all the containers that were created and started by Aspire. You can inspect their status, logs, and configuration directly from the VS Code interface.

- **Aspire Dashboard in the Browser**  
  A more pleasant and comprehensive experience is to hold **Ctrl** and click the link displayed by the `aspire run` command. This opens the Aspire dashboard in your browser.

  The dashboard provides:
  - A visual overview of all infrastructure components (e.g., services, containers, databases)
  - Direct links to tools and service endpoints
  - Integrated consoles for each component
  - Real-time diagnostics and health checks
  - Environment variables and configuration details
  - Logs and metrics for observability

This dashboard is especially useful for understanding how components interact and for debugging during development.

---

## Why This Setup Rocks

After switching to this workflow, I've found .NET and Aspire development on Windows to be much more enjoyable and productive. WSL gives me the flexibility of Linux tools without leaving the comfort of Windows, and Visual Studio Code bridges the gap beautifully. Aspire rounds out the stack, making it easy to build, test, and run distributed, cloud-native applications locally—no more fighting with mismatched environments or heavyweight virtual machines.

If you're looking to modernize your .NET development setup and leverage Aspire for cloud-native scenarios, give this approach a try. It’s fast, flexible, and surprisingly simple once you get everything in place. If you have questions or tips, feel free to reach out or leave a comment!

Happy coding!
