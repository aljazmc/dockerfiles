#!/bin/bash

IMAGES=$(
    find . -type d | 
    sed "
        /.git/d;
        /^\.$/d;
        /blender$/d;
        /corepack$/d;
        /fluidsynth$/d;
        /godot$/d;
        /heaps$/d;
        /inkscape$/d;
        /wine$/d;
        /x11$/d;
        s/\.\///g;
        s/\//-/g;
    " |
    sort | 
    tr '\n' ' '
)

clean() {

for i in ${IMAGES[@]}; do

    image=$i

    docker image ls aljazmc/$image -q | sort -u | xargs -r docker rmi -f

done

}

publish() {

for i in ${IMAGES[@]}; do

    ## image-spinner is just one level deep
    dir=$(echo $i | sed 's/-/\//g;s/image\//image-/g')
    image=$i
    
    cd $dir
    docker build . -t aljazmc/$image
    docker tag aljazmc/$image aljazmc/$image:latest
    docker push -a aljazmc/$image
    docker image ls aljazmc/$image -q | sort -u | xargs -r docker rmi -f

    cd ..
    if test "$dir" = "image-spinner"; then
        continue
    else
        cd ..
    fi

    ## it's important to be nice
    sleep 30

done

}

if declare -F "$1" > /dev/null; then
    "$1"
else
    echo "Usage: $0 {clean|publish}"
    exit 1
fi
