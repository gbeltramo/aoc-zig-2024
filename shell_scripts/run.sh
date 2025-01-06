for executable_file in zig-out/bin/puzzle_*
do
    ./${executable_file} 2> /dev/null
done
