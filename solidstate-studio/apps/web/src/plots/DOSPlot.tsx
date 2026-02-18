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
                fillcolor: 'rgba(128,128,128,0.5)', // Gray fill
                line: { color: 'red', width: 2 } // Red line
            }]}
            layout={{
                title: { text: 'Density of States', font: { color: '#333' } },
                width: undefined,
                height: height,
                xaxis: {
                    title: { text: 'Density of States', font: { color: '#333' } },
                    gridcolor: 'white',
                    showticklabels: true,
                    zeroline: false,
                    color: '#333'
                },
                yaxis: {
                    title: { text: '' }, // Shared axis usually
                    gridcolor: 'white',
                    showticklabels: false,
                    zeroline: true,
                    zerolinecolor: 'white',
                    color: '#333'
                },
                paper_bgcolor: 'white',
                plot_bgcolor: '#e5e5e5', // Light gray background
                font: { color: '#333' },
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