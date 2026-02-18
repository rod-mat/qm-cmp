
import { z } from 'zod';

// --- Basic Types ---
export const Vector3Schema = z.tuple([z.number(), z.number(), z.number()]);
export type Vector3 = z.infer<typeof Vector3Schema>;

// Matrix3 is 3x3 array of number arrays (row-major or just 3 rows)
export const Matrix3Schema = z.tuple([Vector3Schema, Vector3Schema, Vector3Schema]);
export type Matrix3 = z.infer<typeof Matrix3Schema>;

// --- Crystal Builder ---

export const LatticeParamsSchema = z.object({
  kind: z.enum(['sc', 'bcc', 'fcc', 'hex', 'custom']),
  a: z.number().positive(),
  b: z.number().positive().optional(),
  c: z.number().positive().optional(),
  alpha: z.number().optional(),
  beta: z.number().optional(),
  gamma: z.number().optional(),
  A: Matrix3Schema.optional() // Required if kind === 'custom'
});

export const BasisAtomSchema = z.object({
  element: z.string(),
  frac: Vector3Schema,
  magmom: z.number().optional()
});

export const ReciprocalParamsSchema = z.object({
  gMax: z.number().positive().default(8.0)
});

export const PlaneSchema = z.object({
  h: z.number().int(),
  k: z.number().int(),
  l: z.number().int(),
  offset: z.number().optional(),
  size: z.number().positive().optional()
});

export type PlaneParams = z.infer<typeof PlaneSchema>;

export const CrystalBuildRequestSchema = z.object({
  lattice: LatticeParamsSchema,
  basis: z.array(BasisAtomSchema),
  supercell: z.tuple([z.number().int().min(1), z.number().int().min(1), z.number().int().min(1)]).default([1, 1, 1]),
  reciprocal: ReciprocalParamsSchema.optional(),
  planes: z.array(PlaneSchema).default([])
});

export type CrystalBuildRequest = z.infer<typeof CrystalBuildRequestSchema>;

// --- Crystal Response ---
export const CrystalBuildResponseSchema = z.object({
  real: z.object({
    A: Matrix3Schema,
    origin: Vector3Schema
  }),
  recip: z.object({
    B: Matrix3Schema,
    gPoints: z.array(Vector3Schema),
    gHKL: z.array(z.tuple([z.number().int(), z.number().int(), z.number().int()]))
  }),
  atoms: z.object({
    positions: z.array(Vector3Schema),
    elements: z.array(z.string()),
    frac: z.array(Vector3Schema)
  }),
  planes: z.array(z.object({
    hkl: z.tuple([z.number().int(), z.number().int(), z.number().int()]),
    normal: Vector3Schema,
    mesh: z.object({
      vertices: z.array(Vector3Schema),
      faces: z.array(z.tuple([z.number().int(), z.number().int(), z.number().int()]))
    })
  })).optional(),
  meta: z.object({
    requestHash: z.string(),
    warnings: z.array(z.string())
  })
});

export type CrystalBuildResponse = z.infer<typeof CrystalBuildResponseSchema>;


// --- Ewald ---

export const EwaldRequestSchema = z.object({
  crystal: z.object({
    B: Matrix3Schema,
    gPoints: z.array(Vector3Schema),
    gHKL: z.array(z.tuple([z.number().int(), z.number().int(), z.number().int()]))
  }),
  beam: z.object({
    lambda: z.number().positive(),
    kInDir: Vector3Schema,
    orientation: Matrix3Schema.optional()
  }),
  detector: z.object({
    distance: z.number().positive(),
    normal: Vector3Schema,
    up: Vector3Schema,
    width: z.number().positive(),
    height: z.number().positive()
  }),
  intensity: z.object({
    model: z.enum(['unit', 'structureFactorLite']),
    sigma: z.number().positive().optional()
  })
});

export type EwaldRequest = z.infer<typeof EwaldRequestSchema>;

export const SpotSchema = z.object({
  hkl: z.tuple([z.number().int(), z.number().int(), z.number().int()]),
  Q: Vector3Schema,
  kOutDir: Vector3Schema,
  uv: z.tuple([z.number(), z.number()]),
  intensity: z.number()
});

export type SpotData = z.infer<typeof SpotSchema>;

export const EwaldResponseSchema = z.object({
  spots: z.array(SpotSchema),
  meta: z.object({
    requestHash: z.string(),
    nTested: z.number().int()
  })
});

export type EwaldResponse = z.infer<typeof EwaldResponseSchema>;


// --- Tight Binding ---

export const TBModelSchema = z.object({
  lattice: z.enum(['1d_chain', '2d_square', '2d_honeycomb']),
  params: z.record(z.string(), z.number())
});

export const KPointSchema = z.object({
  label: z.string(),
  k: Vector3Schema
});

export const TBRequestSchema = z.object({
  model: TBModelSchema,
  kpath: z.object({
    points: z.array(KPointSchema),
    nPerSegment: z.number().int().min(10).max(800).default(200)
  }),
  dos: z.object({
    enabled: z.boolean().default(true),
    nE: z.number().int().min(200).max(4000).default(1200),
    eta: z.number().positive().default(0.03),
    eMin: z.number().optional(),
    eMax: z.number().optional()
  })
});

export type TBRequest = z.infer<typeof TBRequestSchema>;

export const TBResponseSchema = z.object({
  k: z.array(z.number()),
  labels: z.array(z.object({
    atIndex: z.number().int(),
    label: z.string()
  })),
  bands: z.array(z.array(z.number())), // bands[bandIndex][kIndex]
  dos: z.object({
    E: z.array(z.number()),
    g: z.array(z.number())
  }).optional(),
  meta: z.object({
    requestHash: z.string()
  })
});

export type TBResponse = z.infer<typeof TBResponseSchema>;
