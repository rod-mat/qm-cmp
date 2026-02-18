import { useMemo } from 'react';
import * as THREE from 'three';
import { Vector3 } from '@shared/schemas';
import { Line } from '@react-three/drei';

interface EwaldSphereProps {
    radius: number; // k = 2pi / lambda
}

export function EwaldSphere({ radius }: EwaldSphereProps) {
    return (
        <mesh>
            <sphereGeometry args={[radius, 32, 32]} />
            <meshBasicMaterial color="#44ff44" wireframe transparent opacity={0.3} />
        </mesh>
    );
}

interface BeamArrowProps {
    kInDir: Vector3; // normalized direction
    length?: number;
}

export function BeamArrow({ kInDir, length = 5 }: BeamArrowProps) {
    const dir = useMemo(() => new THREE.Vector3(kInDir[0], kInDir[1], kInDir[2]).normalize(), [kInDir]);
    // Arrow should point to origin? Or from origin?
    // Incident beam usually ends at sample (0,0,0).
    // So origin of arrow is -length * dir.
    const origin = useMemo(() => dir.clone().multiplyScalar(-length), [dir, length]);

    return (
        <arrowHelper args={[dir, origin, length, 0xffff00, 1, 0.5]} />
    );
}
