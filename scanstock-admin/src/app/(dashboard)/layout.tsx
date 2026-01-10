import { Sidebar } from '@/components/sidebar'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="min-h-screen bg-background">
      {/* Background grid */}
      <div className="fixed inset-0 bg-grid opacity-[0.02] pointer-events-none" />

      <Sidebar />

      <main className="pl-72 min-h-screen">
        <div className="p-8 max-w-7xl">
          {children}
        </div>
      </main>
    </div>
  )
}
