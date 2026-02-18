import React, { useState, useEffect } from 'react';
import CrystalLab from '../scenes/CrystalLab';
import EwaldLab from '../scenes/EwaldLab';
import TBLab from '../scenes/TBLab';
import { cn } from '../utils/cn';

// Simple router
function Router() {
    const [path, setPath] = useState(window.location.pathname);

    useEffect(() => {
        const onPopState = () => setPath(window.location.pathname);
        window.addEventListener('popstate', onPopState);
        return () => window.removeEventListener('popstate', onPopState);
    }, []);

    const navigate = (to: string) => {
        window.history.pushState(null, '', to);
        setPath(to);
    };

    let Component = CrystalLab;
    if (path === '/ewald') Component = EwaldLab;
    if (path === '/tb') Component = TBLab;
    if (path === '/') {
        // Redirect to crystal
        useEffect(() => {
            navigate('/crystal');
        }, []);
        return null;
    }

    return (
        <div className="flex flex-col h-screen w-full bg-black text-white">
            {/* Header */}
            <header className="h-12 border-b border-neutral-800 flex items-center px-4 justify-between bg-neutral-950 flex-shrink-0 z-10">
                <div className="font-bold tracking-tigher flex items-center gap-2">
                    <span className="text-blue-500 text-xl">♦</span> SolidState Studio
                </div>
                <nav className="flex gap-4">
                    <NavLink active={path.startsWith('/crystal')} onClick={() => navigate('/crystal')}>Crystal</NavLink>
                    <NavLink active={path.startsWith('/ewald')} onClick={() => navigate('/ewald')}>Diffraction</NavLink>
                    <NavLink active={path.startsWith('/tb')} onClick={() => navigate('/tb')}>Tight-Binding</NavLink>
                </nav>
            </header>

            {/* Page */}
            <div className="flex-1 overflow-hidden relative">
                <Component />
            </div>
        </div>
    );
}

function NavLink({ active, children, onClick }: { active: boolean, children: React.ReactNode, onClick: () => void }) {
    return (
        <button
            onClick={onClick}
            className={cn(
                "text-sm font-medium px-2 py-1 rounded transition-colors",
                active ? "text-white bg-neutral-800" : "text-neutral-400 hover:text-white"
            )}
        >
            {children}
        </button>
    );
}

export default Router;
