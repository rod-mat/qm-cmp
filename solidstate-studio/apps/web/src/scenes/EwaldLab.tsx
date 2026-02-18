import { useState } from 'react';
import { Canvas } from '@react-three/fiber';
import { OrbitControls, PerspectiveCamera } from '@react-three/drei';
import { useQuery, keepPreviousData } from '@tanstack/react-query';
import { apiClient } from '@/api/client';
import { LabLayout, ControlGroup, Label, Input } from '@/components/LabLayout';
import { EwaldSphere, BeamArrow } from '@/three/EwaldMisc';
import { ReciprocalPointsLayer } from '@/three/ReciprocalPointsLayer';
import { DetectorScreen } from '@/three/DetectorScreen';
import { DEFAULT_BG_COLOR } from '@shared/constants';
import { EwaldRequest } from '@shared/schemas';

// Helpers
// import { toVec3 } from '@/three/utils'; // unused

export default function EwaldLab() {
    // We need a Crystal Input. For MVP, hardcode a simple crystal (cubic a=3)
    // In real app, we might persist crystal from CrystalLab.

    // Mock Crystal B matrix for a=3 => B=2pi/3 * I approx 2.09
    const b_val = 2.09;

    // Generate some G points for this basic crystal
    const gPoints = [];
    const gHKL = [];
    for (let h = -3; h <= 3; h++)
        for (let k = -3; k <= 3; k++)
            for (let l = -3; l <= 3; l++) {
                if (h === 0 && k === 0 && l === 0) continue;
                gPoints.push([h * b_val, k * b_val, l * b_val]);
                gHKL.push([h, k, l]);
            }

    const [lambda, setLambda] = useState(1.54);
    const [distance, setDistance] = useState(30.0);

    const req: EwaldRequest = {
        crystal: {
            B: [[b_val, 0, 0], [0, b_val, 0], [0, 0, b_val]],
            gPoints: gPoints as any,
            gHKL: gHKL as any
        },
        beam: {
            lambda: lambda,
            kInDir: [0, 0, -1], // Incident along -Z
            orientation: undefined // Identity
        },
        detector: {
            distance: distance,
            normal: [0, 0, 1], // Detector normal +Z (facing source)
            up: [0, 1, 0],
            width: 80,
            height: 80
        },
        intensity: { model: 'unit' }
    };

    const { data } = useQuery({
        queryKey: ['ewald', req],
        queryFn: () => apiClient.calcEwald(req),
        placeholderData: keepPreviousData
    });

    const kRad = 2 * Math.PI / lambda;

    return (
        <LabLayout
            sidebar={
                <>
                    <h1 className="text-xl font-bold text-white mb-4">Diffraction (Ewald)</h1>
                    <ControlGroup title="Beam">
                        <Label>Wavelength λ (Å)</Label>
                        <Input type="number" step="0.1" value={lambda} onChange={e => setLambda(parseFloat(e.target.value))} />
                        <div className="mt-2 text-xs text-neutral-500">
                            k = {kRad.toFixed(2)} Å⁻¹
                        </div>
                    </ControlGroup>
                    <ControlGroup title="Detector">
                        <Label>Distance (mm?)</Label>
                        <Input type="number" step="1" value={distance} onChange={e => setDistance(parseFloat(e.target.value))} />
                        <div className="mt-2 text-xs text-neutral-500">
                            Spots found: {data?.spots.length || 0}
                        </div>
                    </ControlGroup>
                </>
            }
            main={
                <Canvas>
                    <color attach="background" args={[DEFAULT_BG_COLOR]} />
                    <PerspectiveCamera makeDefault position={[30, 20, 30]} />
                    <OrbitControls target={[0, 0, 0]} />

                    {/* Beam */}
                    <BeamArrow kInDir={req.beam.kInDir} length={15} />

                    {/* Ewald Sphere centered at -k_in */}
                    {/* k_in = k * dir. Sphere center is at -k_in? No.
                        Scattering Triangle: k_out - k_in = Q.
                        Ewald Sphere construction: Draw vector k_in (ending at origin). 
                        Sphere center is at START of k_in. Radius k.
                        If k_in points to origin (0,0,0). Start is -k_in.
                        Sphere center at -k_in.
                     */}
                    <group position={[0, 0, kRad]}>
                        <EwaldSphere radius={kRad} />
                    </group>

                    {/* Reciprocal Lattice (Points) */}
                    {/* Only show points near Ewald sphere? Or all? */}
                    <ReciprocalPointsLayer points={req.crystal.gPoints} />

                    {/* Detector */}
                    {/* Position: distance * normal? No, usually distance along axis.
                        If normal is (0,0,1) and distance 30. Pos (0,0,30).
                    */}
                    <group position={[0, 0, -distance]}>
                        {/* Wait, if beam is -Z. Detector should be at -distance? 
                             Transmission -> Behind sample. Sample at 0. Beam towards -Z. Detector at -Z.
                             Reflection -> +Z.
                             Our tests used +Z?
                             Let's visualize and see.
                         */}
                        <DetectorScreen width={80} height={80} spots={data?.spots || []} />
                    </group>

                </Canvas>
            }
        />
    );
}
