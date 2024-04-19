# SAIMOpt

## Mathematical Formalism

The SAIM optimizer will accept problems in the QUMO format:

```math
\begin{array}{rll}
    \min | \max   & \frac{1}{2} \mathbf{z}' \mathbf{Q}\, \mathbf{z} + \mathbf{z}' \mathbf{\ell} + c & \\
    \textrm{s.t.} & \mathbf{z} = [\mathbf{x}, \mathbf{y}]                             & \\
                  & \mathbf{x} \in \{0, 1\}^{m}                                     & \\
                  & \mathbf{y} \in [-1, 1]^{n}    & \\
\end{array}
```

which can be extended to through basic rescaling of the continuous variables' intervals, as in

```math
y' = 2 \frac{y - l}{u - l} - 1 \in [-1, 1] \text{ for } y \in [l, u]
```

leading to the more general form

```math
\begin{array}{rll}
    \min | \max   & \frac{1}{2} \mathbf{z}' \mathbf{Q}\, \mathbf{z} + \mathbf{z}' \mathbf{\ell} + c & \\
    \textrm{s.t.} &  \mathbf{z} = [\mathbf{x}, \mathbf{y}]                             & \\
                  & \mathbf{x} \in \{0, 1\}^{m}                                     & \\
                  & \mathbf{y} \in [\mathbf{l}, \mathbf{u}] \subset \mathbb{R}^{n}    & \\
\end{array}
```
