import { useMemo } from 'react';
import * as THREE from 'three';
import { Matrix3, Vector3 } from '@shared/schemas';
import { Line } from '@react-three/drei';

interface CellEdgesProps {
    A: Matrix3;
    origin?: Vector3;
}

export function CellEdges({ A, origin = [0, 0, 0] }: CellEdgesProps) {
    const points = useMemo(() => {
        // A rows are a1, a2, a3
        const a1 = new THREE.Vector3(A[0][0], A[0][1], A[0][2]);
        const a2 = new THREE.Vector3(A[1][0], A[1][1], A[1][2]);
        const a3 = new THREE.Vector3(A[2][0], A[2][1], A[2][2]);
        const o = new THREE.Vector3(origin[0], origin[1], origin[2]);

        // 8 corners
        // 000, 100, 010, 001, 110, 101, 011, 111
        // edges:
        // 000-100, 000-010, 000-001
        // 100-110, 100-101
        // 010-110, 010-011
        // 001-101, 001-011
        // 110-111
        // 101-111
        // 011-111

        const corners = [
            o.clone(), // 0
            o.clone().add(a1), // 1
            o.clone().add(a2), // 2
            o.clone().add(a3), // 3
            o.clone().add(a1).add(a2), // 4 (1+2)
            o.clone().add(a1).add(a3), // 5 (1+3)
            o.clone().add(a2).add(a3), // 6 (2+3)
            o.clone().add(a1).add(a2).add(a3) // 7 (1+2+3)
        ];

        const edges = [
            [0, 1], [0, 2], [0, 3],
            [1, 4], [1, 5],
            [2, 4], [2, 6],
            [3, 5], [3, 6],
            [4, 7], [5, 7], [6, 7]
        ];

        // Return array of vector3s for LineSegments
        // Or specific line objects.
        // Let's return pairs for LineSegments
        const segmentPoints = [];
        for (const [i, j] of edges) {
            segmentPoints.push(corners[i]);
            segmentPoints.push(corners[j]);
        }
        return segmentPoints;
    }, [A, origin]);

    return (
        <lineSegments>
            <bufferGeometry>
                <float32BufferAttribute
                    attach="attributes-position"
                    args={[
                        points.flatMap(v => [v.x, v.y, v.z]),
                        3
                    ]}
                />
            </bufferGeometry>
            <lineBasicMaterial color="white" />
        </lineSegments>
    );
}
