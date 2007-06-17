#!/bin/sh
cat /tmp/books-export/books-export.xml | tr "\r" " " | tr "\n" " " | tr "\t" " " > /tmp/books-export/books-export-nnl.xml

mv /tmp/books-export/books-export-nnl.xml /tmp/books-export/books-export.xml

java -jar tab-delimited.jar "$1"
