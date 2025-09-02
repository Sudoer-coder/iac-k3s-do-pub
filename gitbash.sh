#!/bin/bash


# Show git status
git status

# Ask for the files to add
read -p "Enter files to add (or . for all): " files

# Add files
git add $files

# Ask for the commit message
read -p "Enter commit message: " message

# Commit changes
git commit -m "$message"

# Push to main branch
git push origin main

echo "Git push completed!"


