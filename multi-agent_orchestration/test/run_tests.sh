#!/bin/bash
set -e

echo "Running syntax tests..."

# Good syntax tests
while read -r f; do
    if ! make run ARGS="$f --parse-only" > ./test_log 2>&1; then
        echo "FAIL: $f should parse"
        cat test_log
        exit 1
    fi
done < <(find test/syntax/good -name "*.mai")

# Bad syntax tests
while read -r f; do
    if make run ARGS="$f --parse-only" > ./test_log 2>&1; then
        echo "FAIL: $f should fail"
        cat test_log
        exit 1
    fi
done < <(find test/syntax/bad -name "*.mai")

echo "All syntax tests passed"
echo "Running type tests..."

# Good type tests
while read -r f; do
    if ! make run ARGS="$f --type-only" > ./test_log 2>&1; then
        echo "FAIL: $f should parse"
        cat test_log
        exit 1
    fi
done < <(find test/type/good -name "*.mai")

# Bad type tests
while read -r f; do
    if make run ARGS="$f --type-only" > ./test_log 2>&1; then
        echo "FAIL: $f should parse"
        cat test_log
        exit 1
    fi
done < <(find test/type/bad -name "*.mai")
