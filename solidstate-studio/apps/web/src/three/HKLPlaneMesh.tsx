import { useMemo } from 'react';
import * as THREE from 'three';
import { Vector3 } from '@shared/schemas';

interface HKLPlaneMeshProps {
    vertices: Vector3[];
    faces: [number, number, number][]; // 0-based indices
    color?: string;
    opacity?: number;
}

export function HKLPlaneMesh({ vertices, faces, color = "orange", opacity = 0.5 }: HKLPlaneMeshProps) {
    const geometry = useMemo(() => {
        const geo = new THREE.BufferGeometry();

        // Flatten vertices
        const verts = new Float32Array(vertices.flatMap(v => [v[0], v[1], v[2]]));

        // Flatten faces
        const indices = faces.flatMap(f => [f[0], f[1], f[2]]);

        geo.setAttribute('position', new THREE.BufferAttribute(verts, 3));
        geo.setIndex(indices);
        geo.computeVertexNormals();

        return geo;
    }, [vertices, faces]);

    return (
        <mesh geometry={geometry}>
            <meshStandardMaterial
                color={color}
                transparent
                opacity={opacity}
                side={THREE.DoubleSide}
                depthWrite={false} // usually good for transparent planes inside other stuff
            />
        </mesh>
    );
}
