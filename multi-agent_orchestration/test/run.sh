
good_syntax_tests=./syntax/good/

for test in "$good_syntax_tests"/*
do
  make run $test
done