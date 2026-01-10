import Link from 'next/link'
import Image from 'next/image'
import { ArrowLeft } from 'lucide-react'

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center p-8">
      <div className="text-center space-y-6">
        <Image
          src="/logo.png"
          alt="ScanStock"
          width={160}
          height={160}
          className="w-40 h-40 object-contain mx-auto"
        />

        <div>
          <h1 className="text-6xl font-bold font-mono text-primary mb-2">404</h1>
          <h2 className="text-xl font-semibold mb-2">Página no encontrada</h2>
          <p className="text-muted-foreground max-w-md">
            La página que buscas no existe o ha sido movida.
          </p>
        </div>

        <Link
          href="/dashboard"
          className="inline-flex items-center gap-2 px-6 py-3 rounded-lg bg-primary text-primary-foreground font-medium hover:bg-primary/90 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Volver al Dashboard
        </Link>
      </div>
    </div>
  )
}
