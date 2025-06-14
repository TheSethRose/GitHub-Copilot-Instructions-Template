#!/bin/bash

# GitHub Copilot Instructions Template Installer
# Version: 1.0.0
# Author: Seth Rose
# Description: Installs GitHub Copilot instruction templates and prompts

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/TheSethRose/GitHub-Copilot-Instructions-Template.git"
TEMP_DIR="github-copilot-instructions-tmp"
USER_PROMPTS_DIR="$HOME/Library/Application Support/Code - Insiders/User/prompts"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print header
print_header() {
    echo
    print_color $BLUE "=================================================="
    print_color $BLUE "  GitHub Copilot Instructions Template Installer"
    print_color $BLUE "=================================================="
    echo
}

# Function to print step
print_step() {
    local step=$1
    local description=$2
    echo
    print_color $YELLOW "Step ${step}: ${description}"
    echo "----------------------------------------"
}

# Function to ask yes/no question
ask_yes_no() {
    local question=$1
    local default=$2
    local response
    
    # Fallback check - if we can't access /dev/tty, show error
    if [ ! -c /dev/tty ]; then
        print_color $RED "Error: Cannot access terminal for interactive input"
        print_color $RED "Please download and run this script directly instead of piping"
        print_color $BLUE "Run: curl -O https://raw.githubusercontent.com/TheSethRose/GitHub-Copilot-Instructions-Template/main/install.sh && bash install.sh"
        exit 1
    fi
    
    while true; do
        if [ "$default" = "y" ]; then
            printf "%s [Y/n]: " "$question" >&2
            read response </dev/tty
            response=${response:-y}
        else
            printf "%s [y/N]: " "$question" >&2
            read response </dev/tty
            response=${response:-n}
        fi
        
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) print_color $RED "Please answer yes (y) or no (n)." >&2;;
        esac
    done
}

# Function to ask multiple choice question
ask_choice() {
    local question=$1
    local option1=$2
    local option2=$3
    local default=$4
    local response
    
    # Fallback check - if we can't access /dev/tty, show error
    if [ ! -c /dev/tty ]; then
        print_color $RED "Error: Cannot access terminal for interactive input"
        print_color $RED "Please download and run this script directly instead of piping"
        print_color $BLUE "Run: curl -O https://raw.githubusercontent.com/TheSethRose/GitHub-Copilot-Instructions-Template/main/install.sh && bash install.sh"
        exit 1
    fi
    
    while true; do
        echo "$question" >&2
        echo "1) $option1" >&2
        echo "2) $option2" >&2
        printf "Choose [1/2] (default: %s): " "$default" >&2
        read response </dev/tty
        response=${response:-$default}
        
        case $response in
            1 ) return 0;;  # Return 0 for option 1 (success in bash)
            2 ) return 1;;  # Return 1 for option 2
            * ) print_color $RED "Please choose 1 or 2." >&2;;
        esac
    done
}

# Function to check if directory exists and is not empty
check_github_folder() {
    if [ -d ".github" ] && [ "$(ls -A .github 2>/dev/null)" ]; then
        return 0  # Exists and not empty
    else
        return 1  # Doesn't exist or is empty
    fi
}

# Function to backup existing .github folder
backup_github_folder() {
    if [ -d ".github" ]; then
        local backup_name=".github.backup.$(date +%Y%m%d_%H%M%S)"
        print_color $YELLOW "Creating backup: $backup_name"
        mv .github "$backup_name"
        print_color $GREEN "✓ Backup created successfully"
    fi
}

# Function to clone repository
clone_repository() {
    print_color $YELLOW "Cloning repository..."
    
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    
    git clone "$REPO_URL" "$TEMP_DIR" --quiet
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✓ Repository cloned successfully"
    else
        print_color $RED "✗ Failed to clone repository"
        exit 1
    fi
}

# Function to copy .github folder
copy_github_folder() {
    local delete_existing=$1
    
    if [ "$delete_existing" = true ] && [ -d ".github" ]; then
        print_color $YELLOW "Removing existing .github folder..."
        rm -rf .github
        print_color $GREEN "✓ Existing .github folder removed"
    fi
    
    print_color $YELLOW "Copying .github folder..."
    cp -r "$TEMP_DIR/.github" .
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✓ .github folder copied successfully"
    else
        print_color $RED "✗ Failed to copy .github folder"
        exit 1
    fi
}

# Function to move prompts to user data folder
move_prompts_to_user_data() {
    print_color $YELLOW "Moving prompts to user data folder..."
    
    # Create user prompts directory if it doesn't exist
    mkdir -p "$USER_PROMPTS_DIR"
    
    # Copy all files from .github/prompts to user prompts directory
    if [ -d ".github/prompts" ]; then
        cp -r .github/prompts/* "$USER_PROMPTS_DIR/" 2>/dev/null || true
        
        if [ $? -eq 0 ]; then
            print_color $GREEN "✓ Prompts moved to user data folder: $USER_PROMPTS_DIR"
        else
            print_color $YELLOW "⚠ Some files may not have been copied (this is normal if some already exist)"
        fi
        
        # List what was copied
        echo
        print_color $BLUE "Files available in user prompts folder:"
        ls -la "$USER_PROMPTS_DIR" | grep -E '\.(md|instructions)$' || print_color $YELLOW "No prompt files found"
    else
        print_color $RED "✗ .github/prompts folder not found"
        exit 1
    fi
}

# Function to cleanup temporary files
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_color $YELLOW "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
        print_color $GREEN "✓ Cleanup completed"
    fi
}

# Function to show completion message
show_completion() {
    echo
    print_color $GREEN "=================================================="
    print_color $GREEN "  Installation completed successfully!"
    print_color $GREEN "=================================================="
    echo
    print_color $BLUE "What was installed:"
    echo "• Core instruction templates in .github/instructions/"
    echo "• Specialized prompts for development workflows"
    echo "• Comprehensive README with usage guidelines"
    echo
    print_color $BLUE "Next steps:"
    echo "1. Review the README.md for detailed usage instructions"
    echo "2. Customize the instruction files for your project"
    echo "3. Configure VS Code to use the prompts (see README)"
    echo "4. Start using GitHub Copilot with your new instructions!"
    echo
    print_color $YELLOW "Pro tip: Run 'cat README.md' to see the full documentation"
    echo
}

# Function to show error and cleanup
error_exit() {
    local error_message=$1
    print_color $RED "Error: $error_message"
    cleanup
    exit 1
}

# Main installation function
main() {
    # Check if running in a piped environment and warn about interactivity
    if [ ! -t 0 ]; then
        print_color $YELLOW "Notice: Script is running in a piped environment (e.g., curl | bash)"
        print_color $YELLOW "The script will attempt to use interactive prompts via /dev/tty"
        print_color $YELLOW "If prompts don't work, please download and run the script directly"
        echo
        # Give a moment for user to read the warning
        sleep 2
    fi
    
    # Trap to ensure cleanup on exit
    trap cleanup EXIT
    
    print_header
    
    print_color $BLUE "This installer will set up GitHub Copilot instruction templates in your current directory."
    print_color $BLUE "Current directory: $(pwd)"
    print_color $GREEN "The installation will proceed automatically with sensible defaults."
    echo
    
    # Check if we're in a git repository or appropriate directory
    if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "README.md" ]; then
        print_color $YELLOW "Note: You don't appear to be in a project directory."
        print_color $YELLOW "The installer will create a .github folder with instruction templates here."
        print_color $BLUE "You can always move these files to your project later."
        echo
        if ! ask_yes_no "Continue with installation in this directory?" "y"; then
            print_color $YELLOW "Installation cancelled by user."
            exit 0
        fi
    else
        print_color $GREEN "✓ Project directory detected. Proceeding with installation."
    fi
    
    # Step 1: Check for existing .github folder
    print_step "1" "Checking for existing .github folder"
    
    local delete_existing=false
    if check_github_folder; then
        print_color $YELLOW "Found existing .github folder with content."
        print_color $YELLOW "Contents:"
        ls -la .github/ | head -10
        echo
        if ask_yes_no "Do you want to overwrite the existing .github folder?" "n"; then
            delete_existing=true
            print_color $YELLOW "Will overwrite existing .github folder during installation."
        else
            print_color $BLUE "Installation cancelled. Your existing .github folder will remain unchanged."
            print_color $BLUE "You can manually copy files from the repository if needed:"
            print_color $BLUE "https://github.com/TheSethRose/GitHub-Copilot-Instructions-Template"
            cleanup
            exit 0
        fi
    else
        print_color $GREEN "No existing .github folder found or folder is empty."
    fi
    
    # Step 2: Ask about prompt installation location
    print_step "2" "Choose prompt installation location"
    
    local install_to_userdata=false
    ask_choice "Where would you like to install the prompt files?" \
              "User Data folder (~/.../User/prompts) - Global access" \
              ".github/prompts folder - Project specific" \
              "2"
    
    local choice_result=$?
    if [ $choice_result -eq 0 ]; then
        install_to_userdata=true
        print_color $BLUE "Prompts will be installed to user data folder for global access."
    else
        print_color $BLUE "Prompts will remain in .github/prompts for project-specific use."
    fi
    
    # Step 3: Clone repository
    print_step "3" "Downloading GitHub Copilot instructions template"
    clone_repository
    
    # Step 4: Copy .github folder
    print_step "4" "Installing instruction templates"
    copy_github_folder $delete_existing
    
    # Step 5: Move prompts if requested
    if [ "$install_to_userdata" = true ]; then
        print_step "5" "Moving prompts to user data folder"
        move_prompts_to_user_data
    fi
    
    # Step 6: Show completion message
    show_completion
}

# Check prerequisites
if ! command -v git &> /dev/null; then
    print_color $RED "Error: git is required but not installed."
    exit 1
fi

# Run main function
main "$@"
