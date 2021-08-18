using JSON


function local_value_numbering(instrs)
    val2vn = Dict()
    var2vn = Dict()
    vn2var = Dict()

    for instr in instrs
        if instr["op"] == "const"
            value = (instr["op"], instr["value"])
            vn = length(val2vn) + 1
            val2vn[value] = vn
            var2vn[instr["dest"]] = vn
            vn2var[vn] = instr["dest"]
        elseif instr["op"] == "id"
            var = instr["args"][1]
            vn = var2vn[var]
            instr["args"][1] = vn2var[vn]
            var2vn[instr["dest"]] = vn
        elseif instr["op"] == "print"
            var = instr["args"][1]
            vn = var2vn[var]
            instr["args"][1] = vn2var[vn]
        else
            vn_a, vn_b = (var2vn[var] for var in instr["args"])
            value = (instr["op"], vn_a, vn_b)

            if value in keys(val2vn)
                vn = val2vn[value]
                var2vn[instr["dest"]] = vn
                instr["args"] = [vn2var[vn]]
                instr["op"] = "id"
            else
                vn = length(val2vn) + 1
                val2vn[value] = vn
                var2vn[instr["dest"]] = vn
                vn2var[vn] = instr["dest"]
                instr["args"] = [vn2var[vn_a], vn2var[vn_b]]
            end
        end
    end

    instrs
end


function trivial_dce(instrs)
    instr_idx = Array(1:length(instrs))
    converged = false

    while !converged
        instr_valid = fill(false, length(instrs))
        unused_var_idx = Dict()
        num_instr = length(instr_idx)

        for idx in instr_idx
            instr = instrs[idx]

            if "args" in keys(instr)
                valid_idx = [unused_var_idx[var] for var in instr["args"]]
                instr_valid[valid_idx] .= true
            end

            if "dest" in keys(instr)
                unused_var_idx[instr["dest"]] = idx
            else
                instr_valid[idx] = true
            end
        end

        instr_idx = [idx for idx in instr_idx if instr_valid[idx]]
        converged = (num_instr == length(instr_idx))
    end

    instrs[instr_idx]
end


function main()
    prog = JSON.parse(join(readlines(stdin)))
    instrs = prog["functions"][1]["instrs"]

    instrs = local_value_numbering(instrs)
    instrs = trivial_dce(instrs)

    prog["functions"][1]["instrs"] = instrs
    JSON.print(prog, 2)
end
    
main()
