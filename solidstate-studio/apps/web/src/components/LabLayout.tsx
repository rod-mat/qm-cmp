import React, { ReactNode } from 'react';
import { cn } from '@/utils/cn';

interface LabLayoutProps {
    sidebar: ReactNode;
    main: ReactNode; // 3D Canvas
    bottom?: ReactNode; // Plots
    className?: string;
}

export function LabLayout({ sidebar, main, bottom, className }: LabLayoutProps) {
    return (
        <div className={cn("flex h-screen w-full bg-neutral-900 text-neutral-200 overflow-hidden", className)}>
            {/* Sidebar */}
            <aside className="w-80 flex-shrink-0 border-r border-neutral-800 bg-neutral-950 p-4 overflow-y-auto">
                {sidebar}
            </aside>

            {/* Content Area */}
            <div className="flex flex-1 flex-col relative">
                {/* Main 3D View */}
                <main className="flex-1 relative bg-black">
                    {main}
                </main>

                {/* Bottom Panel (optional) */}
                {bottom && (
                    <div className="h-64 border-t border-neutral-800 bg-neutral-900 p-4 overflow-hidden relative">
                        {bottom}
                    </div>
                )}
            </div>
        </div>
    );
}

export function ControlGroup({ title, children }: { title: string, children: ReactNode }) {
    return (
        <div className="mb-6">
            <h3 className="text-sm font-semibold text-neutral-500 uppercase tracking-widest mb-3">{title}</h3>
            <div className="space-y-3">
                {children}
            </div>
        </div>
    );
}

export function Label({ children }: { children: ReactNode }) {
    return <label className="block text-xs font-medium text-neutral-400 mb-1">{children}</label>;
}

export function Input({ ...props }: React.InputHTMLAttributes<HTMLInputElement>) {
    return (
        <input
            className="w-full bg-neutral-800 border border-neutral-700 rounded px-2 py-1 text-sm text-white focus:outline-none focus:border-blue-500"
            {...props}
        />
    );
}

export function Button({ active, ...props }: React.ButtonHTMLAttributes<HTMLButtonElement> & { active?: boolean }) {
    return (
        <button
            className={cn(
                "px-3 py-1 text-sm rounded transition-colors",
                active ? "bg-blue-600 text-white" : "bg-neutral-800 text-neutral-300 hover:bg-neutral-700"
            )}
            {...props}
        />
    );
}
