#!/bin/sh

### Initialisations
url=''
file_name=${url##*/}
proxy="--proxy http://proxy.ssn.net:8080"
seg_size=$((50*1024*1024)) ### 50MB
temp_file_path=~/Downloads/cURLed/
file_size=0
file_ext=''
head_file_name=''

#### Functions 

parse_head () {
    echo "Getting file information ...."
    
    head_file_name=$temp_file_path$file_name"_head.txt"
    
    #### downloading head information
    curl $proxy --head $url > $head_file_name
    
    while IFS=":;" read head_name head_value rest; do
        if [ "$head_name" = "Content-Length" ]; then
            file_size=$head_value
            file_size=$((file_size + 1 -1)) ### +1-1 hack for removing the escape sequence at the end of $file_size variable :)
        elif [ "$head_name" = "Content-Type" ]; then
            file_ext=$(echo $head_value | cut -d/ -f2)
        fi
    done < $head_file_name
            
    if [ "$file_size" -eq 0 ]; then
        echo "Error: Download Failed !"
        exit
    else
        echo "\nFile Name : $file_name"
        echo "File Size : $file_size Bytes"
    fi 
}

verify () {
    echo "\nVerifying Downloaded parts ....."
    count=$1
    total_parts=$2
    ver_count=0
    if [ "$count" -eq "$total_parts" ]; then
        loop_count=1
        while [ "$loop_count" -le "$total_parts" ] 
        do
            seg_name=$file_name".part"$loop_count
            curr_seg_size=$seg_size   
            if [ "$loop_count" -eq "$total_parts" ]; then 
                curr_seg_size=$((file_size%seg_size))   ### calc last part size seperately
            fi
            
            if [ -f $temp_file_path$seg_name ] && [ $(wc -c $temp_file_path$seg_name | cut -d\  -f1) -eq "$curr_seg_size" ] ; then 
                ver_count=$((ver_count+1))
            fi
            loop_count=$((loop_count+1))       
        done
        
        if [ "$ver_count" -eq "$total_parts" ]; then
            return 0 ### All parts okay
        else
            return 1 ### Some parts failed
        fi
    else
        return 2  ### download failed
    fi
}

download () {    
    #### downloading the file in segments
    seg_begin=0
    count=1
    total_parts=$(((file_size/(seg_size)+1)))
    while [ "$count" -le "$total_parts" ] 
    do
        seg_name=$file_name".part"$count
                
        curr_seg_size=$seg_size   
        if [ "$((count))" -eq "$total_parts" ]; then 
            curr_seg_size=$((file_size%seg_size))   ### calculate last part size seperately
        fi
        seg_end=$((seg_begin+curr_seg_size-1))
        
        if [ ! -f $temp_file_path$seg_name ] || [ $(wc -c $temp_file_path$seg_name | cut -d\  -f1) != $((curr_seg_size)) ]; then     ### checking for non-existence of the file and if its present then its size
            echo "\nDownloading part ("$((count))"/"$total_parts") of file "$file_name
            curl $proxy --range $seg_begin-$seg_end -o $temp_file_path$seg_name $url
        fi
        
        seg_begin=$((seg_end+1))
        count=$((count+1))
    done 
    
    verify $((count-1)) $total_parts
    ret_value=$?
    
    if [ "$ret_value" -eq 0 ]; then
        #### concatenating all the parts
        cat $temp_file_path$file_name".part"* > $file_name
        
        #### deleting all the temp parts
        rm $temp_file_path$file_name".part"*
        rm $head_file_name
        
        echo "\nDownload Complete !!!"
        echo "File path : "$(pwd)
        echo "File Name : "$file_name
    elif [ "$ret_value" -eq 1 ]; then
        echo "\nERROR: Some parts have not been downloaded correctly"
        echo "\nRetrying Download again ..... ..... ....."
        download
    else
        echo "Error : Download Failed !"
    fi
}

check_arguments () {
    if [ "$1" = "--noproxy" ]; then
        proxy=''
    fi
}

print_usage () {
    echo "\nUsage: \n-------------"
    echo "curled [URL] [OPTION]"
    echo "curled --help"
}

print_help () {
    echo "\nTry \`curled --help\` for more options."
}

print_options () {
    echo "\nOptions: \n-------------"
    echo "--noproxy     -       Doesn't use SSN proxy"
}



#### main

if [ ! -d "$temp_file_path" ]; then
    mkdir $temp_file_path
fi

if [ ! -z "$1" -a "$1" != " " ]; then
    if [ "$1" = '--help' ]; then
        print_usage
        print_options
    else
        check_arguments $2
        url=$1
        file_name=${url##*/}
        if [ -z "$file_name" ]; then
            file_name=$file_size"."$file_ext
        fi
        parse_head
        download
    fi
else
    echo "curled: URL missing"
    print_usage
    print_help
fi
