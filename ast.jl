# Abstract syntax tree components

# The 3 main components are :
# - Declaration : Declares a new variable or function
# - Statement : An instruction
# - Expression : A value

# --- Types ---
@enum DeclType t_int t_proc t_void
@enum SymKind sym_local sym_arg sym_global
@enum StmtKind stmt_exp stmt_decl stmt_return stmt_ifelse
@enum ExpKind exp_add exp_mul exp_id exp_int exp_set

# Symbol
# Data about low level variable
mutable struct Sym
    kind
    type
    # sym_global
    id
    # sym_local sym_arg
    position
end

# Declaration
mutable struct Decl
    type
    id
    # For variables
    value
    # For functions
    body
    # For semantic analysis
    locals
end

# Statement
mutable struct Stmt
    kind
    # stmt_exp stmt_return
    exp
    # stmt_decl
    decl
    # stmt_ifelse
    ifbody
    elsebody
end

# Expression
mutable struct Exp
    kind
    type
    # Operators
    left
    right
    # Literals
    value
    # exp_id
    id
    # For semantic analysis
    sym
    # For code gen
    register
end

# --- Constructors ---
function sym_new(kind::SymKind, type::DeclType, id::String, position::Int = 0)
    return Sym(kind, type, id, position)
end

function decl_new(type::DeclType, id::String, value = nothing,
        body::Stmt = nothing, locals::Array{Decl} = [])
    return Decl(type, id, value, body, locals)
end

function stmt_new(kind::StmtKind, exp::Exp = nothing, decl::Decl = nothing,
        ifbody::Stmt = nothing, elsebody::Stmt = nothing)
    return Stmt(kind, exp, decl, ifbody, elsebody)
end

function exp_new(kind::ExpKind, type::DeclType, left = nothing,
        right = nothing, value = nothing, id::String = nothing,
        sym::Sym = nothing, register = nothing)
    return Exp(kind, type, left, right, value, id, sym, register)
end
