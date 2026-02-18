import React from 'react';
import Plot from 'react-plotly.js';

interface DOSPlotProps {
    E: number[];
    dos: number[];
    height?: number;
}

export function DOSPlot({ E, dos, height = 400 }: DOSPlotProps) {
    return (
        <Plot
            data={[{
                x: dos,
                y: E, // Rotated: DOS on X, Energy on Y to match bands side-by-side
                type: 'scatter' as const,
                mode: 'lines' as const,
                fill: 'tozerox',
                line: { color: 'orange', width: 2 }
            }]}
            layout={{
                title: { text: 'Density of States' },
                width: undefined,
                height: height,
                xaxis: {
                    title: { text: 'DOS (arb. units)' },
                    gridcolor: '#444',
                    showticklabels: false
                },
                yaxis: {
                    title: { text: '' }, // Shared axis usually
                    gridcolor: '#444',
                    showticklabels: false
                },
                paper_bgcolor: 'rgba(0,0,0,0)',
                plot_bgcolor: 'rgba(0,0,0,0)',
                font: { color: '#ccc' },
                margin: { t: 40, r: 20, l: 0, b: 40 }, // Left margin 0 to touch Bands
                dragmode: 'pan',
            }}
            style={{ width: '100%', height: '100%' }}
            config={{
                responsive: true,
                displayModeBar: true,
                scrollZoom: true
            }}
        />
    );
}