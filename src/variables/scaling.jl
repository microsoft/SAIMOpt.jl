# 

raw"""
    _scaling(l::V, u::V, L::V, U::V) where {T,V<:AbstractVector{T}}

Let ``\mathbf{y} \in [l, u] \subseteq \mathbb{R}^{n}`` be a vector of variables
in the original model and ``\mathbf{Y} \in [L, U] \subseteq \mathbb{R}^{n}``
the corresponding vector in the solver's frame of reference.

Then,

```math
\begin{align*}
  \mathbf{Y} &= \mathbf{L} + (\mathbf{y} - \mathbf{l}) \odot (\mathbf{U} - \mathbf{L}) \odiv (\mathbf{u} - \mathbf{l}) \\
             &= \mathbf{L} - \mathbf{l} \odot (\mathbf{U} - \mathbf{L}) \odiv (\mathbf{u} - \mathbf{l}) + \mathbf{y} \odot (\mathbf{U} - \mathbf{L}) \odiv (\mathbf{u} - \mathbf{l})
\end{align*}
```

Therfore, the linear transformation ``\mathbf{Y} = \mathbf{A} \mathbf{y} + \mathbf{b}`` is given by

```math
\begin{align*}
  \mathbf{A} &= \text{diag}\left(\frac{\mathbf{U} - \mathbf{L}}{\mathbf{u} - \mathbf{l}}\right) \\
  \mathbf{b} &= \mathbf{L} - \mathbf{l} \odot \frac{\mathbf{U} - \mathbf{L}}{\mathbf{u} - \mathbf{l}}
\end{align*}
```

"""
function _scaling(l::V, u::V, L::V, U::V) where {T,V<:AbstractVector{T}}
    v = (U - L) ./ (u - l)
    A = Diagonal(v)
    b = L - l .* v

    return (A, b)
end

function _scaling(info::VariableInfo{T}, vmap::Dict{VI,Int}) where {T}
    n = length(vmap)
    l = zeros(T, n)
    u = zeros(T, n)
    L = Vector{T}(undef, n)
    U = Vector{T}(undef, n)

    for (vi, i) in vmap
        v = info[vi]

        @assert is_bounded(v)

        l[i] = v.lower
        u[i] = v.upper

        if v.type === :binary
            L[i] = zero(T)
            U[i] = one(T)
        else # v.type === :continuous
            L[i] = -one(T)
            U[i] = one(T)
        end
    end

    return _scaling(l, u, L, U)
end
