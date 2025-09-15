#!/bin/bash

echo "=== DEBUG: Context Window Component ==="

# Test if claude command exists
if command -v claude >/dev/null 2>&1; then
    echo "✅ claude command found at: $(which claude)"
    
    # Test claude /context command
    echo "🔍 Testing claude /context command..."
    context_output=$(claude /context 2>&1)
    exit_code=$?
    
    echo "Exit code: $exit_code"
    echo "Raw output:"
    echo "$context_output"
    echo "---"
    
    if [[ $exit_code -eq 0 ]]; then
        echo "✅ claude /context executed successfully"
        
        # Test our extraction pattern
        echo "🔍 Testing extraction pattern..."
        if [[ "$context_output" =~ [0-9]+k/[0-9]+k.*\([0-9]+%\) ]]; then
            echo "✅ Pattern matches!"
            
            current_tokens="$(echo "$context_output" | grep -o '[0-9]\+k/' | sed 's|/||')"
            max_tokens="$(echo "$context_output" | grep -o '/[0-9]\+k' | sed 's|/||')" 
            percentage="$(echo "$context_output" | grep -o '[0-9]\+%')"
            
            echo "Extracted:"
            echo "  Current: '$current_tokens'"
            echo "  Max: '$max_tokens'"
            echo "  Percentage: '$percentage'"
        else
            echo "❌ Pattern doesn't match"
        fi
    else
        echo "❌ claude /context failed"
    fi
else
    echo "❌ claude command not found"
fi

echo "=== END DEBUG ==="
