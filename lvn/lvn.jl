using JSON


function local_value_numbering()
    json_str = join(readlines(stdin))

    prog = JSON.parse(json_str)

    JSON.print(prog, 2)
end

local_value_numbering()
