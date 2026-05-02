#!/bin/bash
set -e

echo "Running syntax tests..."

# Good syntax tests
find test/syntax/good -name "*.mai" | while read -r f; do
    make run ARGS="$f --parse-only" > ./test_log 2>&1 || {
        echo "FAIL: $f should parse"
        exit 1
    }
done

# Bad syntax tests
find syntax/bad -name "*.mai" | while read -r f; do
    make run ARGS="$f --parse-only" > ./test_log 2>&1 && {
        echo "FAIL: $f should fail"
        exit 1
    }
done

echo "All syntax tests passed"
echo "Running type tests..."

# Good type tests
find type/good -name "*.mai" | while read -r f; do
    make run ARGS="$f --type-only" > ./test_log 2>&1 || {
        echo "FAIL: $f should pass"
        exit 1
    }
done

# Bad type tests
find type/bad -name "*.mai" | while read -r f; do
    make run ARGS="$f --type-only" > ./test_log 2>&1 && {
        echo "FAIL: $f should fail"
        exit 1
    }
done