import React, { useState, useEffect } from 'react';
import { Canvas } from '@react-three/fiber';
import { OrbitControls, PerspectiveCamera } from '@react-three/drei';
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/api/client';
import { LabLayout, ControlGroup, Label, Input, Button } from '@/components/LabLayout';
import { AtomsLayer } from '@/three/AtomsLayer';
import { CellEdges } from '@/three/CellEdges';
import { ReciprocalPointsLayer } from '@/three/ReciprocalPointsLayer';
import { HKLPlaneMesh } from '@/three/HKLPlaneMesh';
import { DEFAULT_CAMERA_POSITION, DEFAULT_BG_COLOR } from '@shared/constants';
import { CrystalBuildRequest, PlaneParams } from '@shared/schemas';

// Defaults
const DEFAULT_REQ: CrystalBuildRequest = {
    lattice: { kind: 'sc', a: 3.0 },
    basis: [{ element: 'Po', frac: [0, 0, 0] }],
    supercell: [1, 1, 1],
    reciprocal: { gMax: 6.0 },
    planes: []
};

// Simple presets import (would be dynamic in real app)
import latticePresets from '@presets/lattices.json';

export default function CrystalLab() {
    // State
    const [req, setReq] = useState<CrystalBuildRequest>(DEFAULT_REQ);
    const [showRecip, setShowRecip] = useState(false);
    const [showPlanes, setShowPlanes] = useState(true);

    // Query
    const { data, isLoading, error } = useQuery({
        queryKey: ['crystal', req],
        queryFn: () => apiClient.buildCrystal(req),
        staleTime: Infinity,
        retry: false
    });

    // Handlers
    const updateLattice = (key: string, val: any) => {
        setReq(prev => ({ ...prev, lattice: { ...prev.lattice, [key]: val } }));
    };

    const addPlane = (h: number, k: number, l: number) => {
        setReq(prev => ({
            ...prev,
            planes: [...prev.planes, { h, k, l, size: 8, offset: 0 }]
        }));
    };

    const removePlane = (idx: number) => {
        setReq(prev => ({
            ...prev,
            planes: prev.planes.filter((_, i) => i !== idx)
        }));
    };

    return (
        <LabLayout
            sidebar={
                <>
                    <div className="mb-4">
                        <h1 className="text-xl font-bold text-white">Crystal Builder</h1>
                        <p className="text-xs text-neutral-500">Construct crystals & view reciprocal space.</p>
                    </div>

                    <ControlGroup title="Lattice">
                        <div className="flex gap-2 mb-2">
                            {['sc', 'bcc', 'fcc', 'hex'].map(k => (
                                <Button
                                    key={k}
                                    active={req.lattice.kind === k}
                                    onClick={() => updateLattice('kind', k)}
                                >
                                    {k.toUpperCase()}
                                </Button>
                            ))}
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                            <div>
                                <Label>a (Å)</Label>
                                <Input
                                    type="number" step="0.1"
                                    value={req.lattice.a}
                                    onChange={(e) => updateLattice('a', parseFloat(e.target.value))}
                                />
                            </div>
                            {req.lattice.kind === 'hex' && (
                                <div>
                                    <Label>c (Å)</Label>
                                    <Input
                                        type="number" step="0.1"
                                        value={req.lattice.c || 5.0}
                                        onChange={(e) => updateLattice('c', parseFloat(e.target.value))}
                                    />
                                </div>
                            )}
                        </div>
                    </ControlGroup>

                    <ControlGroup title="View Options">
                        <div className="space-y-2">
                            <label className="flex items-center gap-2 cursor-pointer">
                                <input type="checkbox" checked={showRecip} onChange={(e) => setShowRecip(e.target.checked)} />
                                <span className="text-sm">Show Reciprocal Points</span>
                            </label>
                            <label className="flex items-center gap-2 cursor-pointer">
                                <input type="checkbox" checked={showPlanes} onChange={(e) => setShowPlanes(e.target.checked)} />
                                <span className="text-sm">Show Planes</span>
                            </label>
                        </div>
                    </ControlGroup>

                    <ControlGroup title="Planes (hkl)">
                        <div className="flex gap-1 mb-2">
                            <Input placeholder="h" id="inp_h" className="w-8" defaultValue="1" />
                            <Input placeholder="k" id="inp_k" className="w-8" defaultValue="0" />
                            <Input placeholder="l" id="inp_l" className="w-8" defaultValue="0" />
                            <Button onClick={() => {
                                const h = parseInt((document.getElementById('inp_h') as HTMLInputElement).value);
                                const k = parseInt((document.getElementById('inp_k') as HTMLInputElement).value);
                                const l = parseInt((document.getElementById('inp_l') as HTMLInputElement).value);
                                addPlane(h, k, l);
                            }}>Add</Button>
                        </div>
                        <div className="space-y-1">
                            {req.planes.map((p, i) => (
                                <div key={i} className="flex justify-between items-center text-xs bg-neutral-800 px-2 py-1 rounded">
                                    <span>({p.h} {p.k} {p.l})</span>
                                    <button className="text-red-400 hover:text-white" onClick={() => removePlane(i)}>×</button>
                                </div>
                            ))}
                        </div>
                    </ControlGroup>
                </>
            }
            main={
                <Canvas>
                    <color attach="background" args={[DEFAULT_BG_COLOR]} />
                    <PerspectiveCamera makeDefault position={DEFAULT_CAMERA_POSITION} />
                    <OrbitControls />
                    <ambientLight intensity={0.5} />
                    <directionalLight position={[10, 10, 10]} intensity={1} />
                    <gridHelper args={[20, 20, 0x333333, 0x222222]} />

                    {data && (
                        <>
                            {/* Real Space */}
                            <group>
                                <AtomsLayer
                                    positions={data.atoms.positions}
                                    elements={data.atoms.elements}
                                />
                                <CellEdges A={data.real.A} origin={data.real.origin} />

                                {showPlanes && data.planes?.map((p, i) => (
                                    <HKLPlaneMesh
                                        key={i}
                                        vertices={p.mesh.vertices}
                                        faces={p.mesh.faces}
                                        opacity={0.3}
                                        color={i % 2 === 0 ? "orange" : "cyan"}
                                    />
                                ))}
                            </group>

                            {/* Reciprocal Space (Superimposed with different scale/color implies weirdness unless handled? 
                               Usually recip lattice is in inverse units. 1/A vs A.
                               Visualizing overlap is confusing unless scale is comparable.
                               For MVP, we just render them. 
                             */}
                            {showRecip && (
                                <ReciprocalPointsLayer points={data.recip.gPoints} />
                            )}
                        </>
                    )}
                </Canvas>
            }
        />
    );
}
