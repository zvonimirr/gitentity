#!/bin/bash
# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
# Global variables
CONFIG_FILE="$HOME/.gitentity"

# Functions
function error_exit
{
    echo -e "${RED}$1${NC}" 1>&2
    exit 1
}

function warning_message
{
    echo -e "${YELLOW}$1${NC}"
}

function success_message
{
    echo -e "${GREEN}$1${NC}"
}

function print_usage
{
    echo -e "${GREEN}gitentity.sh${NC} - A simple script to manage your git identity"
    echo ""
    echo "Usage: gitentity.sh [command]"
    echo ""
    echo "Commands:"
    echo "  -h, --help: Print this help"
    echo "  -g, --get: Get your git identity"
    echo "  -s, --set: Set your git identity"
    echo "  -r, --remove: Remove a git identity from the config file"
    echo "  -l, --list: List all git identities in the config file"
    echo "  -a, --add: Add a git identity to the config file. You can provide a name and email as arguments"
    echo "  -c, --clear: Remove the config file"
    exit 0
}

# Check if git is installed
if ! command -v git >/dev/null 2>&1; then
    error_exit "git is not installed. Please install git."
fi

# Get global variables from gitconfig
global_user_name=$(git config --global user.name)
global_user_email=$(git config --global user.email)

# Check if the config file exists
if [ ! -f $CONFIG_FILE ]; then
    warning_message "The config database does not exist. Creating it..."
    echo -e "$global_user_name,$global_user_email\n" > $CONFIG_FILE
fi

# Check the parameter
if [ $# -eq 0 ]; then
    print_usage
else
    # Commands:
    # Get the git identity
    if [[ "$1" == "-g" || "$1" == "--get" ]]; then
        success_message "Your git identity is:"
        echo "  - Name: $(git config user.name)"
        echo "  - Email: $(git config user.email)"
    # Add a git identity to the file
    elif [[ "$1" == "-a" || "$1" == "--add" ]]; then
        success_message "Adding a git identity..."

        git_name=$2
        git_email=$3

        # If the name and email are not provided, ask the user for it
        if [ -z "$git_name" ] || [ -z "$git_email" ]; then
            read -p "Name: " git_name
            read -p "Email: " git_email
        fi

        # Check if the name and email are not empty
        if [ -z "$git_name" ] || [ -z "$git_email" ]; then
            error_exit "The name and email cannot be empty."
        fi

        # Check if the name and email are already in the config file
        if grep -q "$git_name,$git_email" $CONFIG_FILE; then
            error_exit "$git_name ($git_email) is already in the config file."
        fi

        # Add the name and email to the config file
        echo -e "$git_name,$git_email\n" >> $CONFIG_FILE
        success_message "$git_name ($git_email) has been added to the config file."
    # List all git identities in the config file
    elif [[ "$1" == "-l" || "$1" == "--list" ]]; then
        echo "List of git identities:"
        cat $CONFIG_FILE | while read line; do
            # Check if the line is not empty
            if [ -z "$line" ]; then
                continue
            fi
            # Split the line in name and email
            name=$(echo $line | cut -d',' -f1)
            email=$(echo $line | cut -d',' -f2)
            success_message "  - $name ($email)"
        done
    # Choose a git identity from the config file
    elif [[ "$1" == "-s" || "$1" == "--set" ]]; then
        # Create an array
        declare -a git_identities=()
        # Counter
        counter=1
        while read line; do
            # Check if the line is not empty
            if [ -z "$line" ]; then
                continue
            fi
            # Split the line in name and email
            name=$(echo $line | cut -d',' -f1)
            email=$(echo $line | cut -d',' -f2)
            echo "$counter) $name ($email)"
            # Add the line to the array
            git_identities[$counter]="$name,$email"
            counter=$((counter+1))
        done < $CONFIG_FILE
        # If the array is empty, exit
        if [ ${#git_identities[@]} -eq 0 ]; then
            error_exit "The config file is empty."
        fi
        # Get the user choice
        read -p "Choice: " choice
        # Check if the choice is valid
        if [ $choice -gt $counter ] || [ $choice -lt 1 ]; then
            error_exit "The choice is not valid."
        fi
        success_message "Setting a git identity..."
        # Get the name and email from the array
        name=$(echo ${git_identities[$choice]} | cut -d',' -f1)
        email=$(echo ${git_identities[$choice]} | cut -d',' -f2)
        # Set the git identity
        git config user.name "$name"
        git config user.email "$email"

        success_message "Your git identity has been set to $name ($email)."
    # Remove a git identity from the config file
    elif [[ "$1" == "-r" || "$1" == "--remove" ]]; then
        # Create an array
        declare -a git_identities=()
        # Counter
        counter=1
        # Ask the user to choose a git identity
        echo "Choose a git identity:"
        while read line; do
            # Check if the line is not empty
            if [ -z "$line" ]; then
                continue
            fi
            # Split the line in name and email
            name=$(echo $line | cut -d',' -f1)
            email=$(echo $line | cut -d',' -f2)
            echo "$counter) $name ($email)"
            # Add the line to the array
            git_identities[$counter]="$name,$email"
            counter=$((counter+1))
        done < $CONFIG_FILE
        # If the array is empty, exit
        if [ ${#git_identities[@]} -eq 0 ]; then
            error_exit "The config file is empty."
        fi
        # Get the user choice
        read -p "Choice: " choice
        # Check if the choice is valid
        if [ $choice -gt $counter ] || [ $choice -lt 1 ]; then
            error_exit "The choice is not valid."
        fi
        # If we're trying to delete the last git identity, exit
        if [ ${#git_identities[@]} -eq 1 ]; then
            error_exit "You cannot delete the last git identity."
        fi
        # Get the name and email from the array
        name=$(echo ${git_identities[$choice]} | cut -d',' -f1)
        email=$(echo ${git_identities[$choice]} | cut -d',' -f2)
        # Remove the line from the config file
        sed -i "/$name,$email/d" $CONFIG_FILE
        success_message "$name ($email) has been removed from the config file."
    # Remove all git identities from the config file
    elif [[ "$1" == "-c" || "$1" == "--clear" ]]; then
        rm -rf $CONFIG_FILE
        success_message "The config file has been cleared."
    else
        print_usage
    fi
fi