#!/bin/bash

yacc -d -y 1905045.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 1905045.l
echo 'Generated the scanner C file'
g++ -w -c -o l.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -lfl -o test
echo 'All ready, running'
./test test.c test_parse.txt test_error.txt test_log.txt test_i_code.asm test_i_optcode.asm