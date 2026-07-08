# [Penalties](@id corepotts-penalties)

Penalty terms are the building blocks of the Potts Hamiltonian.
Each term models one biophysical constraint; they are summed to give the total energy
$H = \sum_k H_k$.
Copy attempts are accepted or rejected based on the *change* in total energy $\Delta H$.

In PottsToolkit you add penalties to a system via **Components** (e.g. `VolumeComponent`,
`AdhesionComponent`). Each component internally constructs the corresponding CorePotts
penalty object and registers the required trackers.
This page describes the underlying penalty mathematics for reference.

---

## Volume Penalty

**Biological meaning:** Cells resist compression and over-expansion.
The volume penalty drives each cell's area (2D) or volume (3D) towards a target value.

**Formula (classical quadratic):**

$$H_\text{vol} = \sum_{i} \lambda_{V,\tau(i)} \bigl(v_i - V_i^{\rm target}\bigr)^2$$

where $v_i$ is the current area/volume of cell $i$, $V_i^{\rm target}$ is its target,
and $\lambda_{V,\tau(i)}$ is the stiffness for cell type $\tau(i)$.

**PottsToolkit component:**

```julia
VolumeComponent(
    A => (λ = 5.0f0, target = 500),
    B => (λ = 3.0f0, target = 300),
)
```

**When to use:** Always include a volume penalty unless you are specifically studying
unconstrained lattice gas dynamics. Without it cells will spread across the entire grid.

---

## HST Volume Penalty

**Biological meaning:** Same as the volume penalty, but with a stochastically evolving
auxiliary field that restores detailed balance when the target volume changes over time
(e.g. during cell growth).

**Formula (augmented Hamiltonian):**

$$H_\text{HST-vol} = \sum_{i} \lambda_{V,\tau(i)} \bigl(v_i - \phi_i\bigr)^2$$

where $\phi_i$ follows the Ornstein-Uhlenbeck SDE:

$$d\phi_i = -\eta(\phi_i - V_i^{\rm target})\,dt + \sqrt{2\eta T}\,dW_t$$

The auxiliary field $\phi_i$ acts as a "soft" target that fluctuates around
$V_i^{\rm target}$ and relaxes on timescale $1/\eta$.

**PottsToolkit component:**

```julia
HSTVolumeComponent(
    A => (λ = 5.0f0, target = 500);
    eta = 1.0,
)
```

**When to use:** Use `HSTVolumeComponent` instead of `VolumeComponent` whenever
`target_volume` is not fixed — for example when using `LinearGrowthCallback` or when
training with `NeuralPotts`. See [Concepts → HST Penalties](@ref concepts) for the
theoretical justification.

---

## HST Surface Area Penalty

**Biological meaning:** Cells have a preferred perimeter (2D) or surface area (3D) set
by cytoskeletal tension.

**Formula:**

$$H_\text{HST-surf} = \sum_{i} \lambda_{S,\tau(i)} \bigl(s_i - \psi_i\bigr)^2$$

where $s_i$ is the current surface area (number of sites on the cell boundary) and
$\psi_i$ is the HST auxiliary field for surface area.

**PottsToolkit component:**

```julia
SurfaceAreaComponent(A => (λ = 1.0f0, target = 200))
```

> [!NOTE]
> `SurfaceAreaComponent` uses the HST formulation by default.
> The surface area tracker counts boundary contacts with the medium or other cells,
> not geometric perimeter, so `target` should be set accordingly.

---

## Adhesion Penalty

**Biological meaning:** Cells preferentially adhere to cells of the same type (like likes
like) or avoid contact with certain neighbours. The adhesion matrix encodes the energetic
cost of each pair of cell-type interfaces.

**Formula:**

$$H_\text{adh} = \sum_{\langle \mathbf{x}, \mathbf{x}' \rangle}
    J\bigl(\tau(\sigma(\mathbf{x})),\; \tau(\sigma(\mathbf{x}'))\bigr)
    \cdot \mathbf{1}\bigl[\sigma(\mathbf{x}) \neq \sigma(\mathbf{x}')\bigr]$$

The sum runs over all neighbouring pairs $\langle \mathbf{x}, \mathbf{x}' \rangle$.
$J(\tau_1, \tau_2)$ is the adhesion energy between cell types $\tau_1$ and $\tau_2$;
it is symmetric ($J(\tau_1,\tau_2) = J(\tau_2,\tau_1)$).

**PottsToolkit component:**

```julia
AdhesionComponent(
    (A, Medium) => 15.0f0,
    (B, Medium) => 15.0f0,
    (A, A)      => 2.0f0,
    (B, B)      => 2.0f0,
    (A, B)      => 10.0f0,
)
```

**Isotropic flag:** Pass `isotropic=true` to the underlying penalty if you want the
adhesion energy to be averaged over all neighbour directions (useful for anisotropic
grids or when matching analytical results).

**When to use:** The adhesion penalty is what drives cell sorting and tissue organisation.
Low $J$ for same-type pairs relative to cross-type pairs causes cells to cluster;
high $J$ for all pairs relative to medium causes cells to round up.

---

## Focal-Point Spring Penalty

**Biological meaning:** Models a spring-like tether between two cells or between a cell
and a fixed anchor point — relevant for cell–substrate adhesion, cell–cell junctions,
and tissue attachment.

**Formula:**

$$H_\text{fps} = \lambda_\text{fps}\; \bigl|\mathbf{c}_i - \mathbf{r}_0\bigr|^2$$

where $\mathbf{c}_i$ is the centroid of cell $i$ and $\mathbf{r}_0$ is the anchor
(which may be the centroid of another cell).

**When to use:** Tissue confinement, modelling substrate adhesion sites, or anchoring
cells to an epithelium.

---

## HST Focal-Point Spring Penalty

The HST variant of the focal-point spring uses an auxiliary field for the anchor position,
allowing the anchor to diffuse or be driven by an external field without violating detailed
balance.

---

## HST Length Penalty

**Biological meaning:** Cells have a preferred elongation (major-axis length).
This drives cells to adopt rod-like or spindle-shaped morphologies, relevant for muscle
cells, neurons, and migrating mesenchymal cells.

**Formula:**

$$H_\text{len} = \sum_{i} \lambda_{L,\tau(i)} \bigl(\ell_i - \phi_{L,i}\bigr)^2$$

where $\ell_i$ is the major-axis length of cell $i$ (computed from the inertia tensor)
and $\phi_{L,i}$ is the HST auxiliary field for length.

**PottsToolkit component:**

```julia
LengthComponent(A => (λ = 3.0f0, target = 20.0f0); eta = 1.0)
```

> [!TIP]
> Combine `LengthComponent` with `AdhesionComponent` to produce spontaneous alignment
> of elongated cells — a simple model of nematic ordering in epithelial monolayers.

---

## Chemotaxis Penalty

**Biological meaning:** Cells sense a chemical gradient in an external scalar field and
bias their motion up or down the gradient (chemotaxis / chemorepulsion).

**Formula:**

$$\Delta H_\text{chem}(\mathbf{x} \to \mathbf{x}') =
    -\chi_{\tau(\sigma(\mathbf{x}'))}\; \bigl[c(\mathbf{x}') - c(\mathbf{x})\bigr]$$

where $c(\mathbf{x})$ is the chemical concentration at site $\mathbf{x}$ and
$\chi_\tau$ is the chemotactic sensitivity of cell type $\tau$ (negative for
chemorepulsion).

**PottsToolkit component:**

```julia
ChemotaxisComponent(A => 0.5f0, chemical_field = my_field)
```

`chemical_field` should be an array of the same size as the simulation grid containing
the chemical concentrations at each lattice site. It can be updated between MCS steps to
model a dynamic field.

**When to use:** Directed cell migration, wound healing, developmental patterning,
tumour invasion assays.

---

## Quick-Reference Table

| Component | `eta` param | Penalty type | Use when |
|-----------|-------------|--------------|----------|
| `VolumeComponent` | — | Quadratic | Static target volumes |
| `HSTVolumeComponent` | ✓ | HST OU | Dynamic targets / NeuralPotts |
| `SurfaceAreaComponent` | — | HST (internal) | Always for perimeter control |
| `AdhesionComponent` | — | Interface energy | Cell sorting, tissue organisation |
| `LengthComponent` | ✓ | HST OU | Elongated cell shapes |
| `ChemotaxisComponent` | — | Gradient bias | Directed migration |
