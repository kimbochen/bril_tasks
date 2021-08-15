import JSON

function get_instrs()
    prog = JSON.parse(ARGS[1])
    instrs = prog["functions"][1]["instrs"]
    JSON.print(instrs, 2)
    instrs
end

function count_const_ops(instrs)
    const_ops = [instr for instr in instrs if instr["op"] == "const"]
    length(const_ops)
end

function run_tsfm()
    instrs = get_instrs()
    n_const_ops = count_const_ops(instrs)
    println("$(n_const_ops) constant operations")
end

run_tsfm()
