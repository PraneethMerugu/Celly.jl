# [Topology](@id corecpm-topology)

The **topology** of a CPM simulation defines two things:

1. **Neighbourhood** — which lattice sites are considered neighbours of a given site
   (and therefore eligible copy sources/targets).
2. **Boundary conditions** — what happens when a copy attempt reaches the edge of the grid.

Topology is passed as the `topology` keyword argument to [`CPMProblem`](@ref):

```julia
prob = CPMProblem(sys, counts, (200, 200);
    tspan    = (0, 500),
    topology = VonNeumannTopology{2}(),   # ← default
)
```

---

## Topology Reference

| Type | Dimension | Neighbourhood size | Boundary | Notes |
|------|-----------|--------------------|----------|-------|
| `VonNeumannTopology{2}()` | 2D | 4 | Periodic (toroidal) | Default; enables 2-colouring |
| `MooreTopology{2}()` | 2D | 8 | Periodic (toroidal) | Enables 4-colouring |
| `NoFluxVonNeumannTopology{2}()` | 2D | 4 | Rigid walls (no-flux) | Cells cannot cross boundary |
| `NoFluxMooreTopology{2}()` | 2D | 8 | Rigid walls (no-flux) | — |
| `VonNeumannTopology{3}()` | 3D | 6 | Periodic | Extends to 3D naturally |
| `MooreTopology{3}()` | 3D | 26 | Periodic | Dense neighbourhood |
| `ExtendedVonNeumannTopology{2,2}()` | 2D | radius-2 VN | Periodic | Larger interaction range |
| `ExtendedMooreTopology{2,2}()` | 2D | radius-2 Moore | Periodic | Requires `SparseLotteryMetropolis` or `ParallelMetropolis` |

The two type parameters of `ExtendedVonNeumannTopology{D,R}` and
`ExtendedMooreTopology{D,R}` are the spatial dimension $D$ and the radius $R$.

---

## Choosing a Topology

### Connectivity and Cell Shape

**Von Neumann** neighbourhoods (4-connected in 2D, 6-connected in 3D) allow only
orthogonal copies. Cells therefore tend to be more rectilinear at coarse resolution.

**Moore** neighbourhoods (8-connected in 2D, 26-connected in 3D) include diagonal
directions, producing smoother, more rounded cell boundaries — often a better match for
biological cells in imaging data.

### Boundary Conditions

**Periodic** (toroidal) boundaries remove edge effects and are the standard choice for
bulk tissue simulations where the boundary is not biologically meaningful.

**No-flux** (rigid wall) boundaries prevent cell IDs from being copied across the grid
edge. Use these when modelling a confined tissue, a well plate, or a wound-healing assay
where the physical boundary matters.

### Extended Topologies

`ExtendedVonNeumann` and `ExtendedMoore` topologies increase the interaction radius
beyond nearest neighbours. This is useful for modelling long-range protrusions
(lamellipodia, filopodia) or for smoothing numerical artefacts in coarse grids.

> [!WARNING]
> Extended topologies have neighbourhood sizes that grow as $O(R^d)$. A radius-2 Moore
> topology in 2D has 24 neighbours per site instead of 8, significantly increasing the
> cost of each copy attempt.

---

## Effect on Checkerboard Colouring

`CheckerboardMetropolis` partitions the lattice into independent colour classes so that
sites of the same colour can be updated simultaneously without write conflicts.
The number of colours required depends on the neighbourhood:

| Topology | Colours required |
|----------|-----------------|
| `VonNeumannTopology{2}` | 2 (black/white) |
| `MooreTopology{2}` | 4 (2×2 tile) |
| `VonNeumannTopology{3}` | 2 |
| `MooreTopology{3}` | 8 (2×2×2 tile) |
| `ExtendedVonNeumannTopology{2,2}` | Not directly supported — use `ParallelMetropolis` |
| `ExtendedMooreTopology{2,2}` | Not directly supported — use `ParallelMetropolis` |

More colours means fewer sites updated per colour-class pass, but each pass is fully
parallel. For standard 2D/3D topologies the checkerboard algorithm is always optimal.

> [!TIP]
> If you are using an extended topology and need high throughput, use
> `ParallelMetropolis` or `SparseLotteryMetropolis`. These handle arbitrary neighbourhoods
> via a stochastic conflict-resolution lottery.
