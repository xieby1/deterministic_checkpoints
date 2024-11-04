#!/usr/bin/env python3

import os
import shutil
from datetime import datetime
import sys

def find_nix_path(base_path, suffix):
    for item in os.scandir(base_path):
        if item.is_symlink() and item.name.startswith('result'):
            target_path = os.readlink(item.path)
            if target_path.endswith(suffix):
                return os.path.realpath(item.path)
    return None

def backup_files():
    # Create backup directory with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = f"backup_{timestamp}"
    
    # Find checkpoint directory
    checkpoint_path = find_nix_path(os.getcwd(), '3.checkpoints')
    if not checkpoint_path:
        print("Error: Cannot find checkpoint directory")
        sys.exit(1)
    print(f"Found checkpoint path: {checkpoint_path}")
    
    # List of files/directories to backup
    files_to_backup = [
        ("checkpoints", checkpoint_path),
        ("cluster-0-0.json", "cluster-0-0.json"),
        ("checkpoint.lst", "checkpoint.lst")
    ]
    
    try:
        # Create backup directory
        os.makedirs(backup_dir, exist_ok=True)
        
        # Perform backup for each file/directory
        for backup_name, source_path in files_to_backup:
            if os.path.exists(source_path):
                target_path = os.path.join(backup_dir, backup_name)
                
                if os.path.isdir(source_path):
                    # Copy directory
                    shutil.copytree(source_path, target_path, dirs_exist_ok=True)
                else:
                    # Copy file
                    shutil.copy2(source_path, target_path)
                print(f"Backed up: {source_path} -> {target_path}")
            else:
                print(f"Warning: {source_path} does not exist")
        
        print(f"Backup completed! Files saved to: {backup_dir}")
        
    except Exception as e:
        print(f"Error during backup: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    # run dump_result.py first
    os.system("python3 dump_result.py")
    backup_files()