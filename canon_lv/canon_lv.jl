using JSON


abstract type Value end

struct Constant <: Value
    value::Int
end

struct AddMul <: Value
    opr1::String
    opr2::String
end

struct SubDiv <: Value
    opr1::String
    opr2::String
end

struct Identity <: Value
    ref_var::String
end

struct Print <: Value
    print_var::String
end


function canonlocalvalue(instrs)
    var2canon = Dict()  # variable -> canonical variable
    val2canon = Dict()  # value -> canonical variable
    value_method = Dict(
        "const" => Constant,
        "id" => Identity,
        "print" => Print,
        "add" => AddMul,
        "mul" => AddMul,
        "sub" => SubDiv,
        "div" => SubDiv
    )

    for instr in instrs
        create_value = value_method[instr["op"]]
        value = create_value(instr, var2canon)
        canoninstr(instr, value, var2canon, val2canon)
    end
end

function Constant(instr, var2canon)
    Constant(instr["value"])
end

function AddMul(instr, var2canon)
    opr1, opr2 = (var2canon[var] for var in instr["args"])
    if opr1 > opr2
        AddMul(opr2, opr1)
    else
        AddMul(opr1, opr2)
    end
end

function SubDiv(instr, var2canon)
    opr1, opr2 = (var2canon[var] for var in instr["args"])
    SubDiv(opr1, opr2)
end

function Identity(instr, var2canon)
    var = instr["args"][1]
    Identity(var2canon[var])
end

function Print(instr, var2canon)
    var = instr["args"][1]
    Print(var2canon[var])
end

function canoninstr(instr, value::Constant, var2canon, val2canon)
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

function canoninstr(instr, value::Union{AddMul, SubDiv}, var2canon, val2canon)
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

function canoninstr(instr, value::Identity, var2canon, val2canon)
    instr["args"][1] = value.ref_var
    var2canon[instr["dest"]] = value.ref_var
end

function canoninstr(instr, value::Print, var2canon, val2canon)
    instr["args"][1] = value.print_var
end


function main()
    prog = JSON.parse(join(readlines(stdin)))
    instrs = prog["functions"][1]["instrs"]
    canonlocalvalue(instrs)
    JSON.print(prog, 2)
end
    
main()
