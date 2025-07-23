#!/usr/bin/env zsh
# Worktree Wrangler - Multi-project Git worktree manager
# Version: 1.3.4

# Color definitions for beautiful output
local -A COLORS
COLORS[RED]='\033[0;31m'
COLORS[GREEN]='\033[0;32m'
COLORS[YELLOW]='\033[1;33m'
COLORS[BLUE]='\033[0;34m'
COLORS[PURPLE]='\033[0;35m'
COLORS[CYAN]='\033[0;36m'
COLORS[WHITE]='\033[1;37m'
COLORS[BOLD]='\033[1m'
COLORS[DIM]='\033[2m'
COLORS[NC]='\033[0m'  # No Color

# Main worktree wrangler function
w() {
    local VERSION="1.3.4"
    local config_file="$HOME/.local/share/worktree-wrangler/config"
    
    # Load configuration
    local projects_dir="$HOME/development"  # Default
    if [[ -f "$config_file" ]]; then
        while IFS='=' read -r key value; do
            case "$key" in
                projects_dir) projects_dir="$value" ;;
            esac
        done < "$config_file"
    fi
    local worktrees_dir="$projects_dir/worktrees"
    
    # Helper function to get worktree information
    get_worktree_info() {
        local wt_path="$1"
        local branch_name=""
        local status_info=""
        local last_activity=""
        
        if [[ ! -d "$wt_path" ]]; then
            return 1
        fi
        
        # Get branch name
        branch_name=$(cd "$wt_path" && git branch --show-current 2>/dev/null)
        if [[ -z "$branch_name" ]]; then
            branch_name="(detached)"
        fi
        
        # Get git status
        local status_output
        status_output=$(cd "$wt_path" && git status --porcelain 2>/dev/null)
        local ahead_behind
        ahead_behind=$(cd "$wt_path" && git status -b --porcelain 2>/dev/null | head -1)
        
        if [[ -n "$status_output" ]]; then
            local modified=$(echo "$status_output" | wc -l | tr -d ' ')
            status_info="📝 $modified files"
        else
            status_info="✅ clean"
        fi
        
        # Check if ahead/behind
        if [[ "$ahead_behind" == *"ahead"* ]]; then
            local ahead_count=$(echo "$ahead_behind" | sed -n 's/.*ahead \([0-9]\+\).*/\1/p')
            status_info="$status_info, ↑$ahead_count"
        fi
        if [[ "$ahead_behind" == *"behind"* ]]; then
            local behind_count=$(echo "$ahead_behind" | sed -n 's/.*behind \([0-9]\+\).*/\1/p')
            status_info="$status_info, ↓$behind_count"
        fi
        
        # Get last activity (last commit date)
        last_activity=$(cd "$wt_path" && git log -1 --format="%cr" 2>/dev/null)
        if [[ -z "$last_activity" ]]; then
            last_activity="no commits"
        fi
        
        echo "$branch_name|$status_info|$last_activity"
    }

    # Handle special flags
    if [[ "$1" == "--list" ]]; then
        echo -e "${COLORS[CYAN]}${COLORS[BOLD]}🌳 === All Worktrees ===${COLORS[NC]}"
        echo -e "${COLORS[DIM]}Configuration:${COLORS[NC]}"
        echo -e "${COLORS[DIM]}  Projects: ${COLORS[BLUE]}$projects_dir${COLORS[NC]}"
        echo -e "${COLORS[DIM]}  Worktrees: ${COLORS[BLUE]}$worktrees_dir${COLORS[NC]}"
        echo ""
        
        # Check if projects directory exists
        if [[ ! -d "$projects_dir" ]]; then
            echo -e "${COLORS[RED]}❌ Projects directory not found: ${COLORS[BOLD]}$projects_dir${COLORS[NC]}"
            echo ""
            echo -e "${COLORS[YELLOW]}💡 To fix this, set your projects directory:${COLORS[NC]}"
            echo -e "   ${COLORS[GREEN]}w --config projects ~/your/projects/directory${COLORS[NC]}"
            return 1
        fi
        
        local found_any=false
        
        # Check new location
        if [[ -d "$worktrees_dir" ]]; then
            for project in $worktrees_dir/*(/N); do
                project_name=$(basename "$project")
                echo -e "\\n${COLORS[PURPLE]}${COLORS[BOLD]}📁 [$project_name]${COLORS[NC]}"
                local found_worktrees=false
                for wt in $project/*(/N); do
                    local wt_name=$(basename "$wt")
                    local wt_info=$(get_worktree_info "$wt")
                    if [[ -n "$wt_info" ]]; then
                        local branch=$(echo "$wt_info" | cut -d'|' -f1)
                        local git_status=$(echo "$wt_info" | cut -d'|' -f2)
                        local activity=$(echo "$wt_info" | cut -d'|' -f3)
                        printf "  ${COLORS[GREEN]}•${COLORS[NC]} %-20s ${COLORS[CYAN]}(%s)${COLORS[NC]} %s ${COLORS[DIM]}- %s${COLORS[NC]}\\n" "$wt_name" "$branch" "$git_status" "$activity"
                    else
                        echo -e "  ${COLORS[RED]}• $wt_name ${COLORS[YELLOW]}(error reading info)${COLORS[NC]}"
                    fi
                    found_worktrees=true
                    found_any=true
                done
                if [[ "$found_worktrees" == "false" ]]; then
                    echo -e "  ${COLORS[DIM]}(no worktrees)${COLORS[NC]}"
                fi
            done
        fi
        
        # Also check old core-wts location
        if [[ -d "$projects_dir/core-wts" ]]; then
            echo -e "\\n${COLORS[PURPLE]}${COLORS[BOLD]}📁 [core]${COLORS[NC]} ${COLORS[DIM]}(legacy location)${COLORS[NC]}"
            for wt in $projects_dir/core-wts/*(/N); do
                local wt_name=$(basename "$wt")
                local wt_info=$(get_worktree_info "$wt")
                if [[ -n "$wt_info" ]]; then
                    local branch=$(echo "$wt_info" | cut -d'|' -f1)
                    local git_status=$(echo "$wt_info" | cut -d'|' -f2)
                    local activity=$(echo "$wt_info" | cut -d'|' -f3)
                    printf "  ${COLORS[GREEN]}•${COLORS[NC]} %-20s ${COLORS[CYAN]}(%s)${COLORS[NC]} %s ${COLORS[DIM]}- %s${COLORS[NC]}\\n" "$wt_name" "$branch" "$git_status" "$activity"
                else
                    echo -e "  ${COLORS[RED]}• $wt_name ${COLORS[YELLOW]}(error reading info)${COLORS[NC]}"
                fi
                found_any=true
            done
        fi
        
        if [[ "$found_any" == "false" ]]; then
            echo -e "\\n${COLORS[YELLOW]}🌱 No worktrees found.${COLORS[NC]}"
            echo ""
            echo -e "${COLORS[YELLOW]}💡 To create your first worktree:${COLORS[NC]}"
            echo -e "   ${COLORS[GREEN]}w <project> <worktree-name>${COLORS[NC]}"
            echo ""
            echo -e "${COLORS[YELLOW]}💡 Available projects in ${COLORS[BLUE]}$projects_dir${COLORS[YELLOW]}:${COLORS[NC]}"
            for dir in "$projects_dir"/*(/N); do
                if [[ -d "$dir/.git" ]]; then
                    echo -e "   ${COLORS[GREEN]}• ${COLORS[WHITE]}$(basename "$dir")${COLORS[NC]}"
                fi
            done
        fi
        
        return 0
    elif [[ "$1" == "--status" ]]; then
        shift
        local target_project="$1"
        
        echo -e "${COLORS[CYAN]}${COLORS[BOLD]}📊 === Worktree Status ===${COLORS[NC]}"
        
        # Check if projects directory exists
        if [[ ! -d "$projects_dir" ]]; then
            echo "❌ Projects directory not found: $projects_dir"
            return 1
        fi
        
        local found_any=false
        
        # Helper function to show status for a single worktree
        show_worktree_status() {
            local wt_path="$1"
            local wt_name="$2"
            local project_name="$3"
            
            if [[ ! -d "$wt_path" ]]; then
                return 1
            fi
            
            local branch_name
            branch_name=$(cd "$wt_path" && git branch --show-current 2>/dev/null)
            if [[ -z "$branch_name" ]]; then
                branch_name="(detached)"
            fi
            
            local status_output
            status_output=$(cd "$wt_path" && git status --porcelain 2>/dev/null)
            
            if [[ -n "$status_output" ]]; then
                echo -e "\\n${COLORS[PURPLE]}📂 $project_name/$wt_name ${COLORS[CYAN]}($branch_name)${COLORS[NC]}:"
                (cd "$wt_path" && git status --short)
                found_any=true
            fi
        }
        
        # Check new location
        if [[ -d "$worktrees_dir" ]]; then
            for project in $worktrees_dir/*(/N); do
                project_name=$(basename "$project")
                
                # Skip if target_project specified and doesn't match
                if [[ -n "$target_project" && "$project_name" != "$target_project" ]]; then
                    continue
                fi
                
                for wt in $project/*(/N); do
                    show_worktree_status "$wt" "$(basename "$wt")" "$project_name"
                done
            done
        fi
        
        # Also check old core-wts location
        if [[ -d "$projects_dir/core-wts" ]]; then
            if [[ -z "$target_project" || "$target_project" == "core" ]]; then
                for wt in $projects_dir/core-wts/*(/N); do
                    show_worktree_status "$wt" "$(basename "$wt")" "core"
                done
            fi
        fi
        
        if [[ "$found_any" == "false" ]]; then
            if [[ -n "$target_project" ]]; then
                echo -e "\\n${COLORS[GREEN]}✅ All worktrees in '${COLORS[BOLD]}$target_project${COLORS[NC]}${COLORS[GREEN]}' are clean${COLORS[NC]}"
            else
                echo -e "\\n${COLORS[GREEN]}✅ All worktrees are clean${COLORS[NC]}"
            fi
        fi
        
        return 0
    elif [[ "$1" == "--recent" ]]; then
        local recent_file="$HOME/.local/share/worktree-wrangler/recent"
        
        echo -e "${COLORS[CYAN]}${COLORS[BOLD]}⏰ === Recent Worktrees ===${COLORS[NC]}"
        
        if [[ ! -f "$recent_file" ]]; then
            echo -e "\\n${COLORS[YELLOW]}🕰️  No recent worktrees found.${COLORS[NC]}"
            echo -e "${COLORS[YELLOW]}💡 Start using worktrees to see them here!${COLORS[NC]}"
            echo ""
            echo -e "${COLORS[DIM]}Try: ${COLORS[GREEN]}w <project> <worktree>${COLORS[DIM]} to switch to a worktree${COLORS[NC]}"
            echo -e "${COLORS[DIM]}Then run: ${COLORS[GREEN]}w --recent${COLORS[DIM]} to see your usage history${COLORS[NC]}"
            return 0
        fi
        
        local count=0
        while IFS='|' read -r timestamp project worktree; do
            if [[ $count -ge 10 ]]; then  # Show last 10
                break
            fi
            
            # Convert timestamp to human readable
            local time_ago
            if command -v date >/dev/null 2>&1; then
                if [[ "$(uname)" == "Darwin" ]]; then
                    time_ago=$(date -r "$timestamp" "+%Y-%m-%d %H:%M" 2>/dev/null)
                else
                    time_ago=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M" 2>/dev/null)
                fi
            fi
            if [[ -z "$time_ago" ]]; then
                time_ago="recently"
            fi
            
            # Check if worktree still exists
            local wt_path=""
            if [[ "$project" == "core" && -d "$projects_dir/core-wts/$worktree" ]]; then
                wt_path="$projects_dir/core-wts/$worktree"
            elif [[ -d "$worktrees_dir/$project/$worktree" ]]; then
                wt_path="$worktrees_dir/$project/$worktree"
            fi
            
            if [[ -n "$wt_path" ]]; then
                local wt_info=$(get_worktree_info "$wt_path")
                if [[ -n "$wt_info" ]]; then
                    local branch=$(echo "$wt_info" | cut -d'|' -f1)
                    local git_status=$(echo "$wt_info" | cut -d'|' -f2)
                    printf "  ${COLORS[GREEN]}•${COLORS[NC]} %-20s ${COLORS[CYAN]}(%s)${COLORS[NC]} %s ${COLORS[DIM]}- %s${COLORS[NC]}\\n" "$project/$worktree" "$branch" "$git_status" "$time_ago"
                else
                    printf "  ${COLORS[GREEN]}•${COLORS[NC]} %-20s ${COLORS[DIM]}- %s${COLORS[NC]}\\n" "$project/$worktree" "$time_ago"
                fi
            else
                printf "  ${COLORS[RED]}•${COLORS[NC]} %-20s ${COLORS[RED]}(deleted)${COLORS[NC]} ${COLORS[DIM]}- %s${COLORS[NC]}\\n" "$project/$worktree" "$time_ago"
            fi
            
            count=$((count + 1))
        done < <(tac "$recent_file" 2>/dev/null)
        
        if [[ $count -eq 0 ]]; then
            echo -e "\\n${COLORS[YELLOW]}🕰️  No recent worktrees found.${COLORS[NC]}"
        fi
        
        return 0
    elif [[ "$1" == "--rm" ]]; then
        shift
        local project="$1"
        local worktree="$2"
        if [[ -z "$project" || -z "$worktree" ]]; then
            echo "Usage: w --rm <project> <worktree>"
            return 1
        fi
        # Check both locations for core
        if [[ "$project" == "core" && -d "$projects_dir/core-wts/$worktree" ]]; then
            (cd "$projects_dir/$project" && git worktree remove "$projects_dir/core-wts/$worktree")
        else
            local wt_path="$worktrees_dir/$project/$worktree"
            if [[ ! -d "$wt_path" ]]; then
                echo "Worktree not found: $wt_path"
                return 1
            fi
            (cd "$projects_dir/$project" && git worktree remove "$wt_path")
        fi
        return $?
    elif [[ "$1" == "--cleanup" ]]; then
        # Check if gh CLI is available
        if ! command -v gh &> /dev/null; then
            echo "Error: GitHub CLI (gh) is not installed or not in PATH"
            echo "Please install it from: https://cli.github.com/"
            return 1
        fi
        
        # Check if gh is authenticated
        if ! gh auth status &> /dev/null; then
            echo "Error: GitHub CLI is not authenticated"
            echo "Please run: gh auth login"
            return 1
        fi
        
        echo "=== Cleaning up merged PR worktrees ==="
        local cleaned_count=0
        local total_checked=0
        
        # Function to clean up a single worktree
        cleanup_worktree() {
            local project="$1"
            local worktree_name="$2"
            local worktree_path="$3"
            
            echo "Checking worktree: $project/$worktree_name"
            total_checked=$((total_checked + 1))
            
            # Get the branch name for this worktree
            local branch_name
            branch_name=$(cd "$worktree_path" && git branch --show-current 2>/dev/null)
            if [[ -z "$branch_name" ]]; then
                echo "  ⚠️  Skipping: Could not determine branch name"
                return 1
            fi
            
            # Check for uncommitted changes
            if [[ -n "$(cd "$worktree_path" && git status --porcelain 2>/dev/null)" ]]; then
                echo "  ⚠️  Skipping: Has uncommitted changes"
                return 1
            fi
            
            # Check if there's an associated PR using robust detection
            local pr_info=""
            
            # Method 1: Try different branch formats
            for branch_format in "$branch_name" "origin/$branch_name" "${branch_name#*/}"; do
                pr_info=$(cd "$projects_dir/$project" && gh pr list --head "$branch_format" --json number,state,headRefName 2>/dev/null)
                if [[ -n "$pr_info" && "$pr_info" != "[]" ]]; then
                    break
                fi
            done
            
            # Method 2: gh pr status from worktree (context-aware)
            if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
                pr_info=$(cd "$worktree_path" && gh pr status --json number,state,headRefName 2>/dev/null)
            fi
            
            # Method 3: List all PRs and filter (most flexible)
            if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
                local all_prs=$(cd "$projects_dir/$project" && gh pr list --json number,state,headRefName 2>/dev/null)
                if [[ -n "$all_prs" && "$all_prs" != "[]" ]]; then
                    # Try exact match first
                    pr_info=$(echo "$all_prs" | jq --arg branch "$branch_name" '.[] | select(.headRefName == $branch)')
                    if [[ -z "$pr_info" || "$pr_info" == "null" ]]; then
                        # Try partial match
                        pr_info=$(echo "$all_prs" | jq --arg branch "$branch_name" '.[] | select(.headRefName | contains($branch))')
                    fi
                    if [[ -z "$pr_info" || "$pr_info" == "null" ]]; then
                        # Try without username prefix
                        local short_branch="${branch_name#*/}"
                        pr_info=$(echo "$all_prs" | jq --arg branch "$short_branch" '.[] | select(.headRefName | contains($branch))')
                    fi
                    if [[ -z "$pr_info" || "$pr_info" == "null" ]]; then
                        pr_info=""
                    fi
                fi
            fi
            
            # Method 4: Commit-based lookup (most reliable)
            if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
                local current_commit=$(cd "$worktree_path" && git rev-parse HEAD 2>/dev/null)
                if [[ -n "$current_commit" ]]; then
                    pr_info=$(cd "$projects_dir/$project" && gh pr list --search "sha:$current_commit" --json number,state,headRefName 2>/dev/null)
                fi
            fi
            
            # Final check
            if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
                echo "  ⚠️  Skipping: No associated PR found"
                return 1
            fi
            
            # Extract PR state using smart parsing
            local pr_state=""
            # Check if it's gh pr status format (has currentBranch)
            if echo "$pr_info" | jq -e '.currentBranch' >/dev/null 2>&1; then
                pr_state=$(echo "$pr_info" | jq -r '.currentBranch.state')
            # Check if it's an array
            elif echo "$pr_info" | jq -e '.[0]' >/dev/null 2>&1; then
                pr_state=$(echo "$pr_info" | jq -r '.[0].state')
            # Check if it's a single object
            elif echo "$pr_info" | jq -e '.state' >/dev/null 2>&1; then
                pr_state=$(echo "$pr_info" | jq -r '.state')
            fi
            if [[ "$pr_state" != "MERGED" ]]; then
                echo "  ⚠️  Skipping: PR is not merged (state: $pr_state)"
                return 1
            fi
            
            # Check for unpushed commits
            local unpushed_commits
            unpushed_commits=$(cd "$worktree_path" && git log @{upstream}..HEAD --oneline 2>/dev/null)
            if [[ -n "$unpushed_commits" ]]; then
                echo "  ⚠️  Skipping: Has unpushed commits"
                return 1
            fi
            
            # All checks passed - remove the worktree
            echo "  ✅ Removing worktree (PR merged, no unpushed commits)"
            if (cd "$projects_dir/$project" && git worktree remove "$worktree_path" 2>/dev/null); then
                cleaned_count=$((cleaned_count + 1))
                echo "  ✅ Successfully removed"
            else
                echo "  ❌ Failed to remove worktree"
            fi
        }
        
        # Check all projects
        for project_dir in "$projects_dir"/*(/N); do
            if [[ ! -d "$project_dir/.git" ]]; then
                continue
            fi
            
            local project_name=$(basename "$project_dir")
            echo "\\nChecking project: $project_name"
            
            # Check new worktrees location
            if [[ -d "$worktrees_dir/$project_name" ]]; then
                for wt_dir in "$worktrees_dir/$project_name"/*(/N); do
                    local wt_name=$(basename "$wt_dir")
                    cleanup_worktree "$project_name" "$wt_name" "$wt_dir"
                done
            fi
            
            # Check legacy location for core project
            if [[ "$project_name" == "core" && -d "$projects_dir/core-wts" ]]; then
                for wt_dir in "$projects_dir/core-wts"/*(/N); do
                    local wt_name=$(basename "$wt_dir")
                    cleanup_worktree "$project_name" "$wt_name" "$wt_dir"
                done
            fi
        done
        
        echo "\\n=== Cleanup Summary ==="
        echo "Worktrees checked: $total_checked"
        echo "Worktrees cleaned: $cleaned_count"
        return 0
    elif [[ "$1" == "--copy-pr-link" ]]; then
        shift
        
        # Check if gh CLI is available
        if ! command -v gh &> /dev/null; then
            echo -e "${COLORS[RED]}❌ Error: GitHub CLI (gh) is not installed or not in PATH${COLORS[NC]}"
            echo "Please install it from: https://cli.github.com/"
            return 1
        fi
        
        # Check if gh is authenticated
        if ! gh auth status &> /dev/null; then
            echo -e "${COLORS[RED]}❌ Error: GitHub CLI is not authenticated${COLORS[NC]}"
            echo "Please run: gh auth login"
            return 1
        fi
        
        local target_project="$1"
        local target_worktree="$2"
        local wt_path=""
        local project_path=""
        
        if [[ -n "$target_project" && -n "$target_worktree" ]]; then
            # Specific worktree provided - use same logic as --rm command
            
            # Check if project exists
            if [[ ! -d "$projects_dir/$target_project" ]]; then
                echo -e "${COLORS[RED]}❌ Project not found: $projects_dir/$target_project${COLORS[NC]}"
                echo ""
                echo "Available projects in $projects_dir:"
                for dir in "$projects_dir"/*(/N); do
                    if [[ -d "$dir/.git" ]]; then
                        echo "  • $(basename "$dir")"
                    fi
                done
                return 1
            fi
            
            project_path="$projects_dir/$target_project"
            
            # Check both locations for core
            if [[ "$target_project" == "core" && -d "$projects_dir/core-wts/$target_worktree" ]]; then
                wt_path="$projects_dir/core-wts/$target_worktree"
            elif [[ -d "$worktrees_dir/$target_project/$target_worktree" ]]; then
                wt_path="$worktrees_dir/$target_project/$target_worktree"
            else
                echo -e "${COLORS[RED]}❌ Worktree not found: $target_project/$target_worktree${COLORS[NC]}"
                return 1
            fi
        else
            # No arguments - use current working directory
            wt_path="$PWD"
            
            # Check if current directory is a git worktree
            if [[ ! -e "$wt_path/.git" ]]; then
                echo -e "${COLORS[YELLOW]}⚠️  Warning: Current directory is not a git worktree${COLORS[NC]}"
                echo -e "${COLORS[DIM]}Will attempt to find PR from current git repository${COLORS[NC]}"
                
                # Try to find if we're in a git repository at all
                if ! git rev-parse --git-dir >/dev/null 2>&1; then
                    echo -e "${COLORS[RED]}❌ Current directory is not in a git repository${COLORS[NC]}"
                    echo ""
                    echo -e "${COLORS[YELLOW]}💡 Usage:${COLORS[NC]}"
                    echo "  • Run from a git repository: ${COLORS[GREEN]}w --copy-pr-link${COLORS[NC]}"
                    echo "  • Or specify worktree: ${COLORS[GREEN]}w --copy-pr-link <project> <worktree>${COLORS[NC]}"
                    return 1
                fi
            fi
            
            # Find the project directory by looking for the main repo
            # Try to find the main git directory from worktree or regular repo
            local git_dir
            git_dir=$(cd "$wt_path" && git rev-parse --git-common-dir 2>/dev/null)
            if [[ -n "$git_dir" && -d "$git_dir" ]]; then
                # Get the parent directory of .git as the project path
                project_path=$(dirname "$git_dir")
            else
                # If git-common-dir fails, try regular git-dir (for regular repos)
                git_dir=$(cd "$wt_path" && git rev-parse --git-dir 2>/dev/null)
                if [[ -n "$git_dir" ]]; then
                    if [[ "$git_dir" == ".git" ]]; then
                        # Regular repo, use current directory as project path
                        project_path="$wt_path"
                    else
                        # Absolute path to .git directory
                        project_path=$(dirname "$git_dir")
                    fi
                else
                    echo -e "${COLORS[RED]}❌ Could not determine project directory${COLORS[NC]}"
                    return 1
                fi
            fi
        fi
        
        echo -e "${COLORS[CYAN]}${COLORS[BOLD]}🔗 === Copying PR Link ===${COLORS[NC]}"
        echo -e "${COLORS[DIM]}Working directory: $wt_path${COLORS[NC]}"
        
        # Get the branch name for this worktree
        local branch_name
        branch_name=$(cd "$wt_path" && git branch --show-current 2>/dev/null)
        if [[ -z "$branch_name" ]]; then
            echo -e "${COLORS[RED]}❌ Could not determine branch name${COLORS[NC]}"
            return 1
        fi
        
        echo -e "${COLORS[DIM]}Branch: $branch_name${COLORS[NC]}"
        
        # Detect PR using robust detection logic (reusing from --cleanup)
        local pr_info=""
        
        # Method 1: Try different branch formats
        for branch_format in "$branch_name" "origin/$branch_name" "${branch_name#*/}"; do
            pr_info=$(cd "$project_path" && gh pr list --head "$branch_format" --json number,state,headRefName,title,url 2>/dev/null)
            if [[ -n "$pr_info" && "$pr_info" != "[]" ]]; then
                break
            fi
        done
        
        # Method 2: gh pr status from worktree (context-aware)
        if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
            pr_info=$(cd "$wt_path" && gh pr status --json number,state,headRefName,title,url 2>/dev/null)
        fi
        
        # Method 3: List all PRs and filter (most flexible)
        if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
            local all_prs=$(cd "$project_path" && gh pr list --json number,state,headRefName,title,url 2>/dev/null)
            if [[ -n "$all_prs" && "$all_prs" != "[]" ]]; then
                # Try exact match first
                pr_info=$(echo "$all_prs" | jq --arg branch "$branch_name" '.[] | select(.headRefName == $branch)')
                if [[ -z "$pr_info" || "$pr_info" == "null" ]]; then
                    # Try partial match
                    pr_info=$(echo "$all_prs" | jq --arg branch "$branch_name" '.[] | select(.headRefName | contains($branch))')
                fi
                if [[ -z "$pr_info" || "$pr_info" == "null" ]]; then
                    # Try without username prefix
                    local short_branch="${branch_name#*/}"
                    pr_info=$(echo "$all_prs" | jq --arg branch "$short_branch" '.[] | select(.headRefName | contains($branch))')
                fi
                if [[ -z "$pr_info" || "$pr_info" == "null" ]]; then
                    pr_info=""
                fi
            fi
        fi
        
        # Method 4: Commit-based lookup (most reliable)
        if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
            local current_commit=$(cd "$wt_path" && git rev-parse HEAD 2>/dev/null)
            if [[ -n "$current_commit" ]]; then
                pr_info=$(cd "$project_path" && gh pr list --search "sha:$current_commit" --json number,state,headRefName,title,url 2>/dev/null)
            fi
        fi
        
        # Check if PR was found
        if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
            echo -e "${COLORS[RED]}❌ No PR found for branch: $branch_name${COLORS[NC]}"
            echo ""
            echo -e "${COLORS[YELLOW]}💡 Make sure you have created a PR for this branch${COLORS[NC]}"
            return 1
        fi
        
        # Extract PR information using smart parsing
        local pr_number=""
        local pr_title=""
        local pr_url=""
        
        # Check if it's gh pr status format (has currentBranch)
        if echo "$pr_info" | jq -e '.currentBranch' >/dev/null 2>&1; then
            pr_number=$(echo "$pr_info" | jq -r '.currentBranch.number')
            pr_title=$(echo "$pr_info" | jq -r '.currentBranch.title')
            pr_url=$(echo "$pr_info" | jq -r '.currentBranch.url')
        # Check if it's an array
        elif echo "$pr_info" | jq -e '.[0]' >/dev/null 2>&1; then
            pr_number=$(echo "$pr_info" | jq -r '.[0].number')
            pr_title=$(echo "$pr_info" | jq -r '.[0].title')
            pr_url=$(echo "$pr_info" | jq -r '.[0].url')
        # Check if it's a single object
        elif echo "$pr_info" | jq -e '.number' >/dev/null 2>&1; then
            pr_number=$(echo "$pr_info" | jq -r '.number')
            pr_title=$(echo "$pr_info" | jq -r '.title')
            pr_url=$(echo "$pr_info" | jq -r '.url')
        fi
        
        if [[ -z "$pr_number" || "$pr_number" == "null" ]]; then
            echo -e "${COLORS[RED]}❌ Could not extract PR information${COLORS[NC]}"
            return 1
        fi
        
        echo -e "${COLORS[GREEN]}✅ Found PR #$pr_number${COLORS[NC]}"
        echo -e "${COLORS[DIM]}Title: $pr_title${COLORS[NC]}"
        
        # Get PR diff to calculate size and determine emoji
        echo -e "${COLORS[DIM]}Calculating diff size...${COLORS[NC]}"
        local pr_diff
        pr_diff=$(cd "$project_path" && gh pr diff "$pr_number" 2>/dev/null)
        
        if [[ -z "$pr_diff" ]]; then
            echo -e "${COLORS[YELLOW]}⚠️  Could not get PR diff, using default emoji${COLORS[NC]}"
            local emoji="🐕"  # Default to dog
        else
            # Count lines that start with + or - (but not +++ or ---)
            local added_lines=$(echo "$pr_diff" | grep "^+" | grep -v "^+++" | wc -l | tr -d ' ')
            local removed_lines=$(echo "$pr_diff" | grep "^-" | grep -v "^---" | wc -l | tr -d ' ')
            local total_changes=$((added_lines + removed_lines))
            
            echo -e "${COLORS[DIM]}Diff size: +$added_lines -$removed_lines (total: $total_changes lines)${COLORS[NC]}"
            
            # Select emoji based on diff size
            local emoji
            if [[ $total_changes -lt 50 ]]; then
                emoji="🐜"  # ant
            elif [[ $total_changes -lt 150 ]]; then
                emoji="🐭"  # mouse
            elif [[ $total_changes -lt 600 ]]; then
                emoji="🐕"  # dog
            elif [[ $total_changes -lt 2000 ]]; then
                emoji="🦁"  # lion
            else
                emoji="🐋"  # whale
            fi
        fi
        
        # Format the markdown link
        local formatted_link="$emoji [$pr_title]($pr_url)"
        
        echo -e "${COLORS[GREEN]}📋 Formatted link:${COLORS[NC]} $formatted_link"
        
        # Copy to clipboard with cross-platform support
        if command -v pbcopy &> /dev/null; then
            echo -n "$formatted_link" | pbcopy
            echo -e "${COLORS[GREEN]}✅ Copied to clipboard!${COLORS[NC]}"
        elif command -v xclip &> /dev/null; then
            echo -n "$formatted_link" | xclip -selection clipboard
            echo -e "${COLORS[GREEN]}✅ Copied to clipboard!${COLORS[NC]}"
        elif command -v wl-copy &> /dev/null; then
            echo -n "$formatted_link" | wl-copy
            echo -e "${COLORS[GREEN]}✅ Copied to clipboard!${COLORS[NC]}"
        else
            echo -e "${COLORS[YELLOW]}⚠️  No clipboard utility found${COLORS[NC]}"
            echo -e "${COLORS[YELLOW]}Please install pbcopy (macOS), xclip (Linux), or wl-clipboard (Wayland)${COLORS[NC]}"
            echo ""
            echo -e "${COLORS[CYAN]}You can manually copy this link:${COLORS[NC]}"
            echo "$formatted_link"
            return 1
        fi
        
        return 0
    elif [[ "$1" == "--version" ]]; then
        echo -e "${COLORS[PURPLE]}${COLORS[BOLD]}🚀 Worktree Wrangler${COLORS[NC]} ${COLORS[GREEN]}v$VERSION${COLORS[NC]}"
        return 0
    elif [[ "$1" == "--update" ]]; then
        echo "=== Updating Worktree Wrangler ==="
        
        # Check for required tools
        if ! command -v curl &> /dev/null; then
            echo "Error: curl is required for updates"
            return 1
        fi
        
        # Get current version
        echo "Current version: $VERSION"
        
        # Determine installation location
        local install_dir="$HOME/.local/share/worktree-wrangler"
        local script_file="$install_dir/worktree-wrangler.zsh"
        
        # Download latest version
        echo "Downloading latest version..."
        local temp_file=$(mktemp)
        if ! curl -sSL "https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/worktree-wrangler.zsh" -o "$temp_file"; then
            echo "Error: Failed to download latest version"
            rm -f "$temp_file"
            return 1
        fi
        
        # Extract version from downloaded file
        local latest_version
        latest_version=$(grep "^# Version:" "$temp_file" | sed 's/# Version: //')
        if [[ -z "$latest_version" ]]; then
            echo "Error: Could not determine latest version"
            rm -f "$temp_file"
            return 1
        fi
        
        echo "Latest version: $latest_version"
        
        # Compare versions
        if [[ "$VERSION" == "$latest_version" ]]; then
            echo "✅ Already up to date!"
            rm -f "$temp_file"
            return 0
        fi
        
        # Create backup of current script
        if [[ -f "$script_file" ]]; then
            echo "Creating backup of current script..."
            cp "$script_file" "$script_file.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Replace script file
        mkdir -p "$install_dir"
        mv "$temp_file" "$script_file"
        
        echo "✅ Successfully updated to version $latest_version"
        echo "Please restart your terminal or run: source ~/.zshrc"
        return 0
    elif [[ "$1" == "--config" ]]; then
        shift
        local action="$1"
        
        if [[ -z "$action" ]]; then
            echo "Usage: w --config <action>"
            echo "Actions:"
            echo "  projects <path>    Set projects directory"
            echo "  list              Show current configuration"
            echo "  reset             Reset to defaults"
            return 1
        fi
        
        case "$action" in
            projects)
                local new_path="$2"
                if [[ -z "$new_path" ]]; then
                    echo "Usage: w --config projects <path>"
                    return 1
                fi
                
                # Expand tilde and resolve path
                new_path="${new_path/#\~/$HOME}"
                new_path=$(realpath "$new_path" 2>/dev/null || echo "$new_path")
                
                if [[ ! -d "$new_path" ]]; then
                    echo "Error: Directory does not exist: $new_path"
                    return 1
                fi
                
                # Create config directory if it doesn't exist
                mkdir -p "$(dirname "$config_file")"
                
                # Write configuration
                echo "projects_dir=$new_path" > "$config_file"
                echo "✅ Set projects directory to: $new_path"
                echo "Worktrees will be created in: $new_path/worktrees"
                ;;
            list)
                echo "=== Configuration ==="
                echo "Projects directory: $projects_dir"
                echo "Worktrees directory: $worktrees_dir"
                echo "Config file: $config_file"
                if [[ -f "$config_file" ]]; then
                    echo "✅ Config file exists"
                else
                    echo "⚠️  Using default configuration (no config file)"
                fi
                ;;
            reset)
                if [[ -f "$config_file" ]]; then
                    rm "$config_file"
                    echo "✅ Configuration reset to defaults"
                    echo "Projects directory: $HOME/development"
                else
                    echo "⚠️  No configuration file to reset"
                fi
                ;;
            *)
                echo "Unknown action: $action"
                echo "Available actions: projects, list, reset"
                return 1
                ;;
        esac
        return 0
    fi
    
    # Normal usage: w <project> <worktree> [command...]
    local project="$1"
    local worktree="$2"
    
    if [[ -z "$project" || -z "$worktree" ]]; then
        echo "Usage: w <project> <worktree> [command...]"
        echo "       w --list"
        echo "       w --status [project]"
        echo "       w --recent"
        echo "       w --rm <project> <worktree>"
        echo "       w --cleanup"
        echo "       w --copy-pr-link [project] [worktree]"
        echo "       w --version"
        echo "       w --update"
        echo "       w --config <action>"
        return 1
    fi
    
    shift 2
    local command=("$@")
    
    # Check if projects directory exists
    if [[ ! -d "$projects_dir" ]]; then
        echo "❌ Projects directory not found: $projects_dir"
        echo ""
        echo "💡 To fix this, set your projects directory:"
        echo "   w --config projects ~/your/projects/directory"
        echo ""
        echo "💡 Or check current configuration:"
        echo "   w --config list"
        return 1
    fi
    
    # Check if project exists
    if [[ ! -d "$projects_dir/$project" ]]; then
        echo "Project not found: $projects_dir/$project"
        echo ""
        echo "Available projects in $projects_dir:"
        for dir in "$projects_dir"/*(/N); do
            if [[ -d "$dir/.git" ]]; then
                echo "  • $(basename "$dir")"
            fi
        done
        return 1
    fi
    
    # Determine worktree path - check multiple locations
    local wt_path=""
    if [[ "$project" == "core" ]]; then
        # For core, check old location first
        if [[ -d "$projects_dir/core-wts/$worktree" ]]; then
            wt_path="$projects_dir/core-wts/$worktree"
        elif [[ -d "$worktrees_dir/$project/$worktree" ]]; then
            wt_path="$worktrees_dir/$project/$worktree"
        fi
    else
        # For other projects, check new location
        if [[ -d "$worktrees_dir/$project/$worktree" ]]; then
            wt_path="$worktrees_dir/$project/$worktree"
        fi
    fi
    
    # If worktree doesn't exist, create it
    if [[ -z "$wt_path" || ! -d "$wt_path" ]]; then
        echo -e "${COLORS[YELLOW]}🌱 Creating new worktree: ${COLORS[BOLD]}$worktree${COLORS[NC]}"
        
        # Ensure worktrees directory exists
        mkdir -p "$worktrees_dir/$project"
        
        # Determine branch name (use current username prefix)
        local branch_name="$USER/$worktree"
        
        # Create the worktree in new location
        wt_path="$worktrees_dir/$project/$worktree"
        (cd "$projects_dir/$project" && git worktree add "$wt_path" -b "$branch_name") || {
            echo -e "${COLORS[RED]}❌ Failed to create worktree${COLORS[NC]}"
            return 1
        }
        echo -e "${COLORS[GREEN]}✅ Worktree created successfully!${COLORS[NC]}"
    fi
    
    # Helper function to track recent worktree usage
    track_recent_usage() {
        local project="$1"
        local worktree="$2"
        local recent_file="$HOME/.local/share/worktree-wrangler/recent"
        local timestamp=$(date +%s)
        
        # Create directory if it doesn't exist
        mkdir -p "$(dirname "$recent_file")"
        
        # Remove any existing entry for this worktree
        if [[ -f "$recent_file" ]]; then
            grep -v "|$project|$worktree$" "$recent_file" > "${recent_file}.tmp" 2>/dev/null || true
            mv "${recent_file}.tmp" "$recent_file" 2>/dev/null || true
        fi
        
        # Add new entry at the end
        echo "$timestamp|$project|$worktree" >> "$recent_file"
        
        # Keep only last 50 entries
        if [[ -f "$recent_file" ]]; then
            tail -50 "$recent_file" > "${recent_file}.tmp" 2>/dev/null || true
            mv "${recent_file}.tmp" "$recent_file" 2>/dev/null || true
        fi
    }
    
    # Track this worktree usage
    track_recent_usage "$project" "$worktree"
    
    # Execute based on number of arguments
    if [[ ${#command[@]} -eq 0 ]]; then
        # No command specified - just cd to the worktree
        cd "$wt_path"
    else
        # Command specified - run it in the worktree without cd'ing
        local old_pwd="$PWD"
        cd "$wt_path"
        eval "${command[@]}"
        local exit_code=$?
        cd "$old_pwd"
        return $exit_code
    fi
}