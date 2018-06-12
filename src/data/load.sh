#!/bin/bash

for file in *.yaml
do
    id=$(echo "$file" | cut -f 1 -d '.')
    echo $id
    curl -X POST -F "file=@$file" localhost:8000/org/$id
done; # file
