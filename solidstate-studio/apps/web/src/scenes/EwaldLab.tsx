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

    const [angle, setAngle] = useState(0);

    // Rotate G points based on angle (around Y axis)
    const rotatedPointsProps = useMemo(() => {
        const rad = angle * Math.PI / 180;
        const cos = Math.cos(rad);
        const sin = Math.sin(rad);

        // Rotate gPoints
        const rPoints = req.crystal.gPoints.map((p: any) => {
            const x = p[0];
            const z = p[2];
            // Y rotation
            // x' = x cos - z sin
            // z' = x sin + z cos
            return [
                x * cos - z * sin,
                p[1],
                x * sin + z * cos
            ];
        });

        return {
            points: rPoints,
            // We should technically rotate B matrix too but for simple visualization points are enough
        };
    }, [angle, req.crystal.gPoints]);

    // Create a new request with rotated points
    const activeReq = useMemo(() => ({
        ...req,
        crystal: {
            ...req.crystal,
            gPoints: rotatedPointsProps.points
        }
    }), [req, rotatedPointsProps]);

    const { data } = useQuery({
        queryKey: ['ewald', activeReq],
        queryFn: () => apiClient.calcEwald(activeReq),
        placeholderData: keepPreviousData
    });

    const kRad = 2 * Math.PI / lambda;

    return (
        <LabLayout
            sidebar={
                <>
                    <h1 className="text-xl font-bold text-white mb-4">Diffraction (Ewald)</h1>
                    <div className="mb-4 bg-blue-900/30 p-3 rounded text-sm text-blue-200 border border-blue-800">
                        <p><strong>Tip:</strong> Rotate the crystal to satisfy the Bragg condition and find diffraction spots.</p>
                    </div>

                    <ControlGroup title="Crystal Rotation">
                        <Label>Angle Y ({angle.toFixed(0)}°)</Label>
                        <input
                            type="range" min="0" max="180" step="1"
                            value={angle}
                            onChange={e => setAngle(parseFloat(e.target.value))}
                            className="w-full accent-blue-500"
                        />
                    </ControlGroup>

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
                    <BeamArrow kInDir={activeReq.beam.kInDir} length={15} />

                    {/* Ewald Sphere centered at -k_in */}
                    <group position={[0, 0, kRad]}>
                        <EwaldSphere radius={kRad} />
                    </group>

                    {/* Reciprocal Lattice (Points) */}
                    <ReciprocalPointsLayer points={activeReq.crystal.gPoints} />

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
