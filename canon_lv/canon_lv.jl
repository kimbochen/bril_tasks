using JSON


abstract type Value end

struct Constant <: Value
    value::Int
end

struct MathOp <: Value
    op::String
    opr1::String
    opr2::String
end

struct Identity <: Value
    ref_var::String
end

struct Print <: Value
    print_var::String
end


function canonicalizelocalvalue(instrs)
    math_ops = ["add", "sub", "mul", "div"]
    var2canon = Dict()  # variable -> canonical variable
    val2canon = Dict()  # value -> canonical variable

    for instr in instrs
        value = if instr["op"] == "const"
            Constant(instr)
        elseif instr["op"] == "id"
            Identity(instr, var2canon)
        elseif instr["op"] == "print"
            Print(instr, var2canon)
        elseif instr["op"] in math_ops
            MathOp(instr, var2canon)
        else
            throw("Value for op '$(instr["op"])' not implemented.")
        end

        transform_instr(instr, value, var2canon, val2canon)
    end
end

function Constant(instr)
    Constant(instr["value"])
end

function MathOp(instr, var2canon)
    opr1, opr2 = (var2canon[var] for var in instr["args"])
    if opr1 > opr2
        MathOp(instr["op"], opr2, opr1)
    else
        MathOp(instr["op"], opr1, opr2)
    end
end

function Identity(instr, var2canon)
    var = instr["args"][1]
    Identity(var2canon[var])
end

function Print(instr, var2canon)
    var = instr["args"][1]
    Print(var2canon[var])
end

function transform_instr(instr, value::Constant, var2canon, val2canon)
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
end

function transform_instr(instr, value::MathOp, var2canon, val2canon)
    if value in keys(val2canon)
        var = val2canon[value]
        instr["op"] = "id"
        instr["args"] = [var]
        var2canon[instr["dest"]] = var
    else
        instr["args"] = [value.opr1, value.opr2]
        var = instr["dest"]
        var2canon[var] = var
        val2canon[value] = var
    end
end

function transform_instr(instr, value::Identity, var2canon, val2canon)
    instr["args"][1] = value.ref_var
    var2canon[instr["dest"]] = value.ref_var
end

function transform_instr(instr, value::Print, var2canon, val2canon)
    instr["args"][1] = value.print_var
end


function main()
    prog = JSON.parse(join(readlines(stdin)))
    instrs = prog["functions"][1]["instrs"]
    canonicalizelocalvalue(instrs)
    JSON.print(prog, 2)
end
    
main()
