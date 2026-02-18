import { useRef, useLayoutEffect } from 'react';
import * as THREE from 'three';
import { Vector3 } from '@shared/schemas';

interface ReciprocalPointsLayerProps {
    points: Vector3[];
    selectedHKL?: [number, number, number];
}

export function ReciprocalPointsLayer({ points }: ReciprocalPointsLayerProps) {
    const meshRef = useRef<THREE.InstancedMesh>(null);
    const count = points.length;

    useLayoutEffect(() => {
        if (!meshRef.current) return;

        const tempObj = new THREE.Object3D();
        const color = new THREE.Color();
        const defaultColor = new THREE.Color('#44aaff');

        for (let i = 0; i < count; i++) {
            const p = points[i];
            tempObj.position.set(p[0], p[1], p[2]);
            // Small points
            tempObj.scale.set(0.15, 0.15, 0.15);
            tempObj.updateMatrix();
            meshRef.current.setMatrixAt(i, tempObj.matrix);

            meshRef.current.setColorAt(i, defaultColor);
        }
        meshRef.current.instanceMatrix.needsUpdate = true;
        if (meshRef.current.instanceColor) meshRef.current.instanceColor.needsUpdate = true;
    }, [points, count]);

    return (
        <instancedMesh ref={meshRef} args={[undefined, undefined, count]}>
            <sphereGeometry args={[1, 8, 8]} />
            <meshBasicMaterial />
        </instancedMesh>
    );
}
