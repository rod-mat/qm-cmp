import React from 'react';
import Plot from 'react-plotly.js';

interface BandPlotProps {
    bands: number[][]; // [bandIndex][kIndex]
    kDist: number[];
    labels: { atIndex: number, label: string }[];
    height?: number;
}

export function BandPlot({ bands, kDist, labels, height = 400 }: BandPlotProps) {
    // Construct traces
    const traces = bands.map((band, i) => ({
        x: kDist,
        y: band,
        type: 'scatter' as const,
        mode: 'lines' as const,
        name: `Band ${i}`,
        line: { color: '#1f77b4', width: 2 }, // Matplotlib blue
        showlegend: false
    }));

    const tickvals = labels.map(l => kDist[l.atIndex]);
    const ticktext = labels.map(l => l.label);

    return (
        <Plot
            data={traces}
            layout={{
                title: { text: 'Electronic Band Structure', font: { color: '#333' } },
                width: undefined, // responsive
                height: height,
                xaxis: {
                    title: { text: 'Wave Vector', font: { color: '#333' } },
                    tickvals: tickvals,
                    ticktext: ticktext,
                    gridcolor: 'white',
                    zeroline: false,
                    color: '#333'
                },
                yaxis: {
                    title: { text: 'E-E_fermi (eV)', font: { color: '#333' } },
                    gridcolor: 'white',
                    zeroline: true,
                    zerolinecolor: 'white',
                    color: '#333'
                },
                paper_bgcolor: 'white',
                plot_bgcolor: '#e5e5e5', // Light gray background like ggplot
                font: { color: '#333' },
                margin: { t: 40, r: 0, l: 60, b: 40 }, // Right margin 0 to touch DOS
                dragmode: 'pan', // Default to pan
            }}
            style={{ width: '100%', height: '100%' }}
            config={{
                responsive: true,
                displayModeBar: true,
                scrollZoom: true,
                modeBarButtonsToAdd: ['zoom2d', 'pan2d', 'zoomIn2d', 'zoomOut2d', 'autoScale2d', 'resetScale2d']
            }}
        />
    );
}