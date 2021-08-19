using JSON


abstract type Value end

struct Constant <: Value
    value::Int
end

struct MathOp <: Value
    op::String
    opd1::String
    opd2::String
end


function canonicalizelocalvalue(instrs)
    math_ops = ["add", "sub", "mul", "div"]
    var2canon = Dict()  # variable -> canonical variable
    val2canon = Dict()  # value -> canonical variable

    for instr in instrs
        value = if instr["op"] == "const"
            Constant(instr)
        elseif instr["op"] in math_ops
            MathOp(instr, var2canon)
        else
            throw("Value for op $(instr["op"]) not implemented.")
        end

        transform_instr(instr, value, var2canon, val2canon)
    end
end

function Constant(instr)
    Constant(instr["value"])
end

function MathOp(instr, var2canon)
    opd1, opd2 = [var2canon[var] for var in instr["args"]]
    if opd1 > opd2
        MathOp(instr["op"], opd2, opd1)
    else
        MathOp(instr["op"], opd1, opd2)
    end
end

function transform_instr(instr, value::Union{Constant, MathOp}, var2canon, val2canon)
    if value in keys(val2canon)
        var = val2canon[value]

        instr["op"] = "id"
        instr["args"] = [var]
        delete!(instr, "value")

        var2canon[instr["dest"]] = var
    else
        var = instr["dest"]
        var2canon[var] = var
        val2canon[value] = var
    end
    instr
end



function main()
    prog = JSON.parse(join(readlines(stdin)))
    instrs = prog["functions"][1]["instrs"]
    canonicalizelocalvalue(instrs)
    JSON.print(prog, 2)
end
    
main()
