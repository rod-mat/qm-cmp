import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/api/client';
import { LabLayout, ControlGroup, Label, Input, Button } from '@/components/LabLayout';
import { BandPlot } from '@/plots/BandPlot';
import { DOSPlot } from '@/plots/DOSPlot';
import { TBRequest } from '@shared/schemas';
import ReactMarkdown from 'react-markdown';
import remarkMath from 'remark-math';
import rehypeKatex from 'rehype-katex';
import 'katex/dist/katex.min.css';

const THEORY_CONTENT: Record<string, string> = {
    '1d_chain': `
### 1D Linear Chain
The simplest model in solid state physics. A single orbital per atom, arranged in a line.

**Hamiltonian:**
$$ H = \\sum_i \\epsilon c_i^\\dagger c_i - t \\sum_{\\langle i,j \\rangle} (c_i^\\dagger c_j + h.c.) $$

**Dispersion Relation:**
$$ E(k) = \\epsilon - 2t \\cos(ka) $$

*   **Bandwidth**: $4t$
*   **Gap**: None (Metallic unless Peierls instability)
`,
    '2d_square': `
### 2D Square Lattice
Atoms arranged in a simple square grid.

**Dispersion:**
$$ E(k_x, k_y) = \\epsilon - 2t (\\cos(k_x a) + \\cos(k_y a)) - 4t' \\cos(k_x a)\\cos(k_y a) $$

**Van Hove Singularities:**
Logarithmic divergence in the Density of States (DOS). With $t' = 0$, it occurs at $E = \\epsilon$.
`,
    '2d_honeycomb': `
### Graphene (Honeycomb Lattice)
Two atoms per unit cell (A and B sublattices).

**Hamiltonian:**
$$ H(k) = \\begin{pmatrix} \\epsilon_A & f(k) \\\\ f^*(k) & \\epsilon_B \\end{pmatrix} $$
where $f(k) = -t (1 + e^{-i k \\cdot a_1} + e^{-i k \\cdot a_2})$

**Dirac Cones:**
At the $K$ points, the dispersion is linear:
$$ E(q) \\approx \\pm v_F |q| $$
This gives Graphene its massless Dirac fermion properties.
`
};

export default function TBLab() {
    const [model, setModel] = useState<string>('2d_honeycomb');
    const [t, setT] = useState(2.7);
    const [tp, setTp] = useState(0.0); // Next-nearest neighbor
    const [eps, setEps] = useState(0.0); // On-site energy
    const [showTheory, setShowTheory] = useState(true);

    // Kpath
    const kPoints = model === '2d_honeycomb'
        ? [
            { label: 'G', k: [0, 0, 0] },
            { label: 'K', k: [4 * Math.PI / 3, 0, 0] },
            { label: 'M', k: [Math.PI, Math.PI / Math.sqrt(3), 0] },
            { label: 'G', k: [0, 0, 0] }
        ]
        : [
            { label: 'G', k: [0, 0, 0] },
            { label: 'X', k: [Math.PI, 0, 0] },
            { label: 'M', k: [Math.PI, Math.PI, 0] },
            { label: 'G', k: [0, 0, 0] }
        ];

    const req: TBRequest = {
        model: {
            lattice: model as any,
            params: {
                t: -t,
                tp: -tp,
                eps: eps,
                epsA: eps,
                epsB: eps
            }
        },
        kpath: {
            points: kPoints as any,
            nPerSegment: 100
        },
        dos: {
            enabled: true,
            nE: 300,
            eta: 0.1
        }
    };

    const { data, isLoading, isError, error } = useQuery({
        queryKey: ['tb', req],
        queryFn: () => apiClient.calcTB(req),
        staleTime: Infinity
    });

    if (isLoading) return <div className="text-white p-8">Loading simulation...</div>;
    if (isError) return <div className="text-red-500 p-8">Error: {error?.message}</div>;

    return (
        <LabLayout
            sidebar={
                <>
                    <h1 className="text-xl font-bold text-white mb-4">Tight-Binding Model</h1>

                    <ControlGroup title="Configuration">
                        <Label>Lattice Type</Label>
                        <select
                            className="w-full bg-neutral-800 p-2 rounded mb-4 text-sm"
                            value={model}
                            onChange={(e) => setModel(e.target.value)}
                        >
                            <option value="1d_chain">1D Chain</option>
                            <option value="2d_square">2D Square</option>
                            <option value="2d_honeycomb">Graphene (Honeycomb)</option>
                        </select>
                        <Label>Hopping Energy t (eV)</Label>
                        <Input type="number" step="0.1" value={t} onChange={e => setT(parseFloat(e.target.value))} />

                        {model === '2d_square' && (
                            <>
                                <Label>Next-Nearest Hopping t' (eV)</Label>
                                <Input type="number" step="0.1" value={tp} onChange={e => setTp(parseFloat(e.target.value))} />
                            </>
                        )}

                        <Label>On-Site Energy ε (eV)</Label>
                        <Input type="number" step="0.1" value={eps} onChange={e => setEps(parseFloat(e.target.value))} />
                    </ControlGroup>

                    <div className="mt-4">
                        <Button active={showTheory} onClick={() => setShowTheory(!showTheory)}>
                            {showTheory ? "Hide Theory" : "Show Theory"}
                        </Button>
                    </div>

                    {showTheory && (
                        <div className="mt-4 p-4 bg-neutral-900 rounded border border-neutral-700 text-sm overflow-y-auto max-h-[50vh] prose prose-invert">
                            <ReactMarkdown
                                remarkPlugins={[remarkMath]}
                                rehypePlugins={[rehypeKatex]}
                                className="prose prose-invert prose-sm"
                            >
                                {THEORY_CONTENT[model]}
                            </ReactMarkdown>
                        </div>
                    )}
                </>
            }
            main={
                <div className="flex flex-col h-full bg-neutral-900 p-4 gap-4 overflow-y-auto">
                    {/* Container for Side-by-Side Plot */}
                    <div className="flex flex-col lg:flex-row h-[600px] w-full gap-2">
                        {/* Left: Bands (75%) */}
                        <div className="flex-[3] bg-white rounded border border-neutral-300 p-2 relative h-full">
                            {data && (
                                <BandPlot
                                    bands={data.bands}
                                    kDist={data.k}
                                    labels={data.labels}
                                    height={undefined}
                                />
                            )}
                        </div>

                        {/* Right: DOS (25%) */}
                        <div className="flex-1 bg-white rounded border border-neutral-300 p-2 relative h-full">
                            {data?.dos && (
                                <DOSPlot
                                    E={data.dos.E}
                                    dos={data.dos.g}
                                    height={undefined}
                                />
                            )}
                        </div>
                    </div>
                </div>
            }
        />
    );
}
