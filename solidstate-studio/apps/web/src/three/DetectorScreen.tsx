import { useLayoutEffect, useRef } from 'react';
import * as THREE from 'three';
import { SpotData } from '@shared/schemas';

interface DetectorScreenProps {
    width: number;
    height: number;
    spots: SpotData[];
}

export function DetectorScreen({ width, height, spots }: DetectorScreenProps) {
    const meshRef = useRef<THREE.InstancedMesh>(null);
    const count = spots.length;

    useLayoutEffect(() => {
        if (!meshRef.current) return;

        const tempObj = new THREE.Object3D();
        const color = new THREE.Color();

        for (let i = 0; i < count; i++) {
            const spot = spots[i];
            // uv is from center?
            // "uv" in response is (u,v) coords on plane.
            // Plane geometry is centered at 0,0.
            // So position is (u, v, 0) relative to plane center.
            // But we need to be careful about axes.
            // Usually PlaneGeometry is in XY plane.
            // u -> x, v -> y?

            tempObj.position.set(spot.uv[0], spot.uv[1], 0.1); // slightly in front

            // Scale by intensity?
            const s = 0.5 + Math.min(spot.intensity * 5, 2.0);
            tempObj.scale.set(s, s, s);
            tempObj.updateMatrix();
            meshRef.current.setMatrixAt(i, tempObj.matrix);

            // Color based on intensity or fixed
            const intensityColor = new THREE.Color().setHSL(0.6, 1.0, Math.min(0.2 + spot.intensity, 1.0));
            meshRef.current.setColorAt(i, intensityColor);
        }
        meshRef.current.instanceMatrix.needsUpdate = true;
        if (meshRef.current.instanceColor) meshRef.current.instanceColor.needsUpdate = true;
    }, [spots, count]);

    return (
        <group>
            {/* Screen Body */}
            <mesh>
                <planeGeometry args={[width, height]} />
                <meshBasicMaterial color="#222" side={THREE.DoubleSide} transparent opacity={0.8} />
            </mesh>

            {/* Spots */}
            <instancedMesh ref={meshRef} args={[undefined, undefined, count]}>
                <circleGeometry args={[0.5, 16]} />
                <meshBasicMaterial />
            </instancedMesh>
        </group>
    );
}
