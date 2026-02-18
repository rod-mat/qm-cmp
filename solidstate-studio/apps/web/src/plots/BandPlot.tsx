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
        line: { color: 'blue', width: 2 },
        showlegend: false
    }));

    const tickvals = labels.map(l => kDist[l.atIndex]);
    const ticktext = labels.map(l => l.label);

    return (
        <Plot
            data={traces}
            layout={{
                title: { text: 'Electronic Band Structure' },
                width: undefined, // responsive
                height: height,
                xaxis: {
                    title: { text: 'Wave Vector k' },
                    tickvals: tickvals,
                    ticktext: ticktext,
                    gridcolor: '#444'
                },
                yaxis: {
                    title: { text: 'Energy (eV)' },
                    gridcolor: '#444'
                },
                paper_bgcolor: 'rgba(0,0,0,0)',
                plot_bgcolor: 'rgba(0,0,0,0)',
                font: { color: '#ccc' },
                margin: { t: 40, r: 20, l: 50, b: 40 },
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