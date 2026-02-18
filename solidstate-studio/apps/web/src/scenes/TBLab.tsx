import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/api/client';
import { LabLayout, ControlGroup, Label, Input, Button } from '@/components/LabLayout';
import { BandPlot } from '@/plots/BandPlot';
import { DOSPlot } from '@/plots/DOSPlot';
import { TBRequest } from '@shared/schemas';

export default function TBLab() {
    const [model, setModel] = useState<string>('2d_honeycomb');
    // Params
    const [t, setT] = useState(-2.7);

    // Kpath
    // Default G-K-M-G for Hex?
    // G(0,0), K(4pi/3a, 0), M(pi/a, pi/sqrt(3)a)? 
    // Simplified for MVP
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
            params: { t: t, eps: 0.0, epsA: 0.0, epsB: 0.0 }
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

    const { data } = useQuery({
        queryKey: ['tb', req],
        queryFn: () => apiClient.calcTB(req),
        staleTime: Infinity
    });

    return (
        <LabLayout
            sidebar={
                <>
                    <h1 className="text-xl font-bold text-white mb-4">Tight-Binding</h1>
                    <ControlGroup title="Model">
                        <select
                            className="w-full bg-neutral-800 p-2 rounded mb-4"
                            value={model}
                            onChange={(e) => setModel(e.target.value)}
                        >
                            <option value="1d_chain">1D Chain</option>
                            <option value="2d_square">2D Square</option>
                            <option value="2d_honeycomb">Graphene (Honeycomb)</option>
                        </select>
                        <Label>Hopping t (eV)</Label>
                        <Input type="number" step="0.1" value={t} onChange={e => setT(parseFloat(e.target.value))} />
                    </ControlGroup>
                </>
            }
            main={
                <div className="flex flex-col h-full bg-neutral-900 p-4 gap-4">
                    {/* Top: Bands */}
                    <div className="flex-1 bg-black rounded border border-neutral-800 p-2">
                        {data && (
                            <BandPlot
                                bands={data.bands}
                                kDist={data.k}
                                labels={data.labels}
                                height={undefined}
                            />
                        )}
                    </div>

                    {/* Bottom: DOS */}
                    <div className="h-1/3 bg-black rounded border border-neutral-800 p-2">
                        {data?.dos && (
                            <DOSPlot
                                E={data.dos.E}
                                dos={data.dos.g}
                                height={undefined}
                            />
                        )}
                    </div>
                </div>
            }
        />
    );
}
