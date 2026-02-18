import {
import {
        type CrystalBuildRequest, type CrystalBuildResponse,
        type EwaldRequest, type EwaldResponse,
        type TBRequest, type TBResponse
    } from '@shared/schemas'
} from '@shared/schemas'

const API_BASE = import.meta.env.VITE_API_BASE || '/api';

async function postJSON<T>(endpoint: string, body: any): Promise<T> {
    const res = await fetch(`${API_BASE}${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body)
    });

    if (!res.ok) {
        const err = await res.json().catch(() => ({ error: 'Unknown Error' }));
        throw new Error(err.details || err.error || 'Network response was not ok');
    }

    return res.json() as Promise<T>;
}

export const apiClient = {
    buildCrystal: async (req: CrystalBuildRequest): Promise<CrystalBuildResponse> => {
        // Validate request client-side?
        // CrystalBuildRequestSchema.parse(req);
        const data = await postJSON<CrystalBuildResponse>('/crystal/build', req);
        // Validate response?
        // return CrystalBuildResponseSchema.parse(data);
        return data;
    },

    calcEwald: async (req: EwaldRequest): Promise<EwaldResponse> => {
        return postJSON<EwaldResponse>('/diffraction/ewald', req);
    },

    calcTB: async (req: TBRequest): Promise<TBResponse> => {
        return postJSON<TBResponse>('/tb/bands', req);
    },

    health: async (): Promise<{ ok: boolean }> => {
        return postJSON<{ ok: boolean }>('/health', {});
    }
};
