import * as THREE from 'three';
import { Vector3 } from '@shared/schemas';

export function toVec3(v: Vector3 | number[]): THREE.Vector3 {
    return new THREE.Vector3(v[0], v[1], v[2]);
}
