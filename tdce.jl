using BenchmarkTools
using JSON


function tdce()
    prog = JSON.parse(ARGS[1])
    instrs = prog["functions"][1]["instrs"]

    while true
        num_instrs = length(instrs)

        instrs = solution4(instrs)

        if num_instrs == length(instrs)
            break
        end
    end

    prog["functions"][1]["instrs"] = instrs
    JSON.print(prog, 2)
end

function solution1(instrs)
    used_vars = Set()
    for instr in instrs
        if haskey(instr, "args")
            push!(used_vars, instr["args"]...)
        end
    end

    for (idx, instr) in enumerate(instrs)
        if haskey(instr, "dest") && !(instr["dest"] in used_vars)
            deleteat!(instrs, idx)
        end
    end
    instrs
end

function solution2(instrs)
    var_table = Dict()
    instr_idx = Int[]

    for (idx, instr) in enumerate(instrs)
        if haskey(instr, "dest")
            var = instr["dest"]
            if haskey(var_table, var) && instr["op"] == "const"
                push!(instr_idx, var_table[var])
            end
            var_table[var] = idx
        end

        if haskey(instr, "args")
            for var in instr["args"]
                delete!(var_table, var)
            end
        end
    end

    push!(instr_idx, values(var_table)...)
    instrs[setdiff(begin:end, instr_idx)]
end

function solution3(instrs)
    # A data structure for recording all valid instr: V
    valid_instr_idx = Set()

    # A data structure for recording instr that assigns to variables: R
    unused_var_idx = Dict()

    # For each instr
    for (idx, instr) in enumerate(instrs)
        # If the instr has arguments, add all used variables to V
        if haskey(instr, "args")
            var_idx = [unused_var_idx[var] for var in instr["args"]]
            push!(valid_instr_idx, var_idx...)
        end

        if haskey(instr, "dest")
            # If instr assigns variable, record the instr idx to R
            unused_var_idx[instr["dest"]] = idx
        else
            # Else add to V
            push!(valid_instr_idx, idx)
        end
    end
    
    # Select instr in V
    valid_instr_idx = sort!(collect(valid_instr_idx))
    instrs[valid_instr_idx]
end

function solution4(instrs)
    # A data structure that records whether each instr is valid
    instr_valid = fill(false, length(instrs))

    # A data structure that records the instr idx of a variable
    var_idx = Dict{String, Int}()

    # For each instr
    for (idx, instr) in enumerate(instrs)
        # If instr has arguments, record instr that create the variables as valid
        if "args" in keys(instr)
            valid_idx = [var_idx[var] for var in instr["args"]]
            instr_valid[valid_idx] .= true
        end

        # If instr creates variable, record the variable and the instr idx
        if "dest" in keys(instr)
            var_idx[instr["dest"]] = idx
        else
            # Else set the instr as valid
            instr_valid[idx] = true
        end
    end

    # Select instr that are recorded as valid
    [instr for (valid, instr) in zip(instr_valid, instrs) if valid]
end

tdce()
