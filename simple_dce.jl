using JSON


function trivial_dce(prog)
    instrs = prog["functions"][1]["instrs"]
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

    prog["functions"][1]["instrs"] = instrs[instr_idx]
    prog
end


function dead_code_elim()
    json_str = join(readlines(stdin))

    prog = JSON.parse(json_str)
    prog = trivial_dce(prog)

    JSON.print(prog, 2)
end


dead_code_elim()
