import { useRef, useLayoutEffect } from 'react';
import * as THREE from 'three';
import { Vector3 } from '@shared/schemas';
import { ELEMENT_COLORS } from '@shared/constants';

interface AtomsLayerProps {
    positions: Vector3[];
    elements: string[];
    onSelect?: (index: number) => void;
}

export function AtomsLayer({ positions, elements, onSelect }: AtomsLayerProps) {
    const meshRef = useRef<THREE.InstancedMesh>(null);
    const count = positions.length;

    useLayoutEffect(() => {
        if (!meshRef.current) return;

        const tempObj = new THREE.Object3D();
        const color = new THREE.Color();

        for (let i = 0; i < count; i++) {
            const pos = positions[i];
            tempObj.position.set(pos[0], pos[1], pos[2]);
            const el = elements[i];

            // Scale based on element? For MVP uniform size
            tempObj.scale.set(0.4, 0.4, 0.4);
            tempObj.updateMatrix();

            meshRef.current.setMatrixAt(i, tempObj.matrix);

            // Color
            const cStr = ELEMENT_COLORS[el] || ELEMENT_COLORS['XX'];
            color.set(cStr);
            meshRef.current.setColorAt(i, color);
        }
        meshRef.current.instanceMatrix.needsUpdate = true;
        if (meshRef.current.instanceColor) meshRef.current.instanceColor.needsUpdate = true;
    }, [positions, elements, count]);

    return (
        <instancedMesh
            ref={meshRef}
            args={[undefined, undefined, count]}
            onClick={(e) => {
                e.stopPropagation();
                if (onSelect && e.instanceId !== undefined) onSelect(e.instanceId);
            }}
        >
            <sphereGeometry args={[1, 16, 16]} />
            <meshStandardMaterial />
        </instancedMesh>
    );
}
