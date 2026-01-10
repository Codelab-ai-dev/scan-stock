'use client'

import Link from 'next/link'
import Image from 'next/image'
import { useState } from 'react'
import { cn } from '@/lib/utils'
import {
  ScanBarcode,
  Package,
  ShoppingCart,
  Users,
  BarChart3,
  Smartphone,
  Shield,
  Zap,
  Check,
  ArrowRight,
  ChevronRight,
  Menu,
  X,
  Star,
  Download,
  Play,
} from 'lucide-react'

export default function LandingPage() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <div className="min-h-screen bg-background overflow-hidden">
      {/* Background effects */}
      <div className="fixed inset-0 bg-grid opacity-[0.02] pointer-events-none" />
      <div className="fixed inset-0 bg-gradient-to-b from-primary/5 via-transparent to-transparent pointer-events-none" />

      {/* Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 border-b border-border/50 bg-background/80 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-20">
            {/* Logo */}
            <Link href="/" className="flex items-center gap-2">
              <Image
                src="/logo.png"
                alt="ScanStock"
                width={72}
                height={72}
                className="w-[72px] h-[72px] object-contain"
              />
              <span className="font-bold text-2xl">ScanStock</span>
            </Link>

            {/* Desktop Nav */}
            <div className="hidden md:flex items-center gap-8">
              <a href="#features" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
                Características
              </a>
              <a href="#pricing" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
                Precios
              </a>
              <a href="#testimonials" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
                Testimonios
              </a>
            </div>

            {/* CTA Buttons */}
            <div className="hidden md:flex items-center gap-3">
              <Link
                href="/login"
                className="px-4 py-2 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
              >
                Iniciar Sesión
              </Link>
              <Link
                href="/download"
                className="px-5 py-2.5 rounded-lg bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90 transition-all shadow-lg shadow-primary/20"
              >
                Descargar App
              </Link>
            </div>

            {/* Mobile menu button */}
            <button
              className="md:hidden p-2 rounded-lg hover:bg-accent"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="md:hidden border-t border-border bg-background/95 backdrop-blur-xl">
            <div className="px-4 py-4 space-y-3">
              <a href="#features" className="block px-3 py-2 rounded-lg hover:bg-accent text-sm">
                Características
              </a>
              <a href="#pricing" className="block px-3 py-2 rounded-lg hover:bg-accent text-sm">
                Precios
              </a>
              <a href="#testimonials" className="block px-3 py-2 rounded-lg hover:bg-accent text-sm">
                Testimonios
              </a>
              <div className="pt-3 border-t border-border space-y-2">
                <Link href="/login" className="block px-3 py-2 rounded-lg hover:bg-accent text-sm">
                  Iniciar Sesión
                </Link>
                <Link
                  href="/download"
                  className="block px-3 py-2.5 rounded-lg bg-primary text-primary-foreground text-sm font-medium text-center"
                >
                  Descargar App
                </Link>
              </div>
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <section className="relative pt-32 pb-20 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            {/* Left content */}
            <div className="space-y-8">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20">
                <Zap className="w-4 h-4 text-primary" />
                <span className="text-sm font-medium text-primary">Nueva versión 2.0 disponible</span>
              </div>

              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold leading-tight">
                Gestiona tu inventario{' '}
                <span className="text-gradient">de forma inteligente</span>
              </h1>

              <p className="text-lg text-muted-foreground max-w-xl">
                ScanStock es la solución completa para el control de inventario y punto de venta.
                Escanea, registra y vende desde tu dispositivo móvil.
              </p>

              <div className="flex flex-col sm:flex-row gap-4">
                <Link
                  href="/download"
                  className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-xl bg-primary text-primary-foreground font-semibold hover:bg-primary/90 transition-all shadow-lg shadow-primary/20 group"
                >
                  <Download className="w-5 h-5" />
                  Descargar Gratis
                  <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
                </Link>
                <button className="inline-flex items-center justify-center gap-2 px-6 py-3.5 rounded-xl border border-border bg-card hover:bg-accent transition-colors group">
                  <Play className="w-5 h-5 text-primary" />
                  Ver Demo
                </button>
              </div>

              {/* Stats */}
              <div className="flex items-center gap-8 pt-4">
                {[
                  { value: '10K+', label: 'Usuarios activos' },
                  { value: '500+', label: 'Negocios' },
                  { value: '4.8', label: 'Rating', icon: Star },
                ].map((stat) => (
                  <div key={stat.label}>
                    <div className="flex items-center gap-1">
                      <span className="text-2xl font-bold font-mono">{stat.value}</span>
                      {stat.icon && <stat.icon className="w-4 h-4 text-amber-500 fill-amber-500" />}
                    </div>
                    <span className="text-sm text-muted-foreground">{stat.label}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* Right - Phone mockup */}
            <div className="relative lg:pl-12">
              <div className="relative mx-auto w-72 sm:w-80">
                {/* Glow effect */}
                <div className="absolute -inset-4 bg-primary/20 rounded-[3rem] blur-3xl opacity-50" />

                {/* Phone frame */}
                <div className="relative bg-card rounded-[2.5rem] border-4 border-border p-2 shadow-2xl">
                  <div className="bg-background rounded-[2rem] overflow-hidden">
                    {/* Status bar */}
                    <div className="h-6 bg-card flex items-center justify-center">
                      <div className="w-20 h-4 bg-border rounded-full" />
                    </div>

                    {/* App content */}
                    <div className="p-4 space-y-4">
                      {/* Header */}
                      <div className="flex items-center justify-between">
                        <div>
                          <p className="text-xs text-muted-foreground">Buenos días</p>
                          <p className="font-semibold">Mi Tienda</p>
                        </div>
                        <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center">
                          <Users className="w-4 h-4 text-primary" />
                        </div>
                      </div>

                      {/* Stats cards */}
                      <div className="grid grid-cols-2 gap-2">
                        <div className="p-3 rounded-xl bg-primary/10 border border-primary/20">
                          <Package className="w-4 h-4 text-primary mb-1" />
                          <p className="text-lg font-bold font-mono">1,234</p>
                          <p className="text-[10px] text-muted-foreground">Productos</p>
                        </div>
                        <div className="p-3 rounded-xl bg-amber-500/10 border border-amber-500/20">
                          <ShoppingCart className="w-4 h-4 text-amber-500 mb-1" />
                          <p className="text-lg font-bold font-mono">$45.2K</p>
                          <p className="text-[10px] text-muted-foreground">Ventas hoy</p>
                        </div>
                      </div>

                      {/* Scan button */}
                      <button className="w-full p-4 rounded-xl bg-primary text-primary-foreground font-medium flex items-center justify-center gap-2">
                        <ScanBarcode className="w-5 h-5" />
                        Escanear Producto
                      </button>

                      {/* Recent items */}
                      <div className="space-y-2">
                        <p className="text-xs text-muted-foreground">Recientes</p>
                        {[1, 2, 3].map((i) => (
                          <div key={i} className="flex items-center gap-3 p-2 rounded-lg bg-card border border-border">
                            <div className="w-8 h-8 rounded-lg bg-muted shimmer" />
                            <div className="flex-1">
                              <div className="h-3 w-24 bg-muted rounded shimmer" />
                              <div className="h-2 w-16 bg-muted rounded mt-1 shimmer" />
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Floating elements */}
                <div className="absolute -left-8 top-20 p-3 rounded-xl bg-card border border-border shadow-xl animate-fade-up">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-green-500/20 flex items-center justify-center">
                      <Check className="w-4 h-4 text-green-500" />
                    </div>
                    <div>
                      <p className="text-xs font-medium">Venta completada</p>
                      <p className="text-[10px] text-muted-foreground">$125.00</p>
                    </div>
                  </div>
                </div>

                <div className="absolute -right-4 bottom-32 p-3 rounded-xl bg-card border border-border shadow-xl animate-fade-up animate-delay-200">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-primary/20 flex items-center justify-center">
                      <ScanBarcode className="w-4 h-4 text-primary" />
                    </div>
                    <div>
                      <p className="text-xs font-medium">Producto escaneado</p>
                      <p className="text-[10px] text-muted-foreground font-mono">SKU-78432</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-24 px-4 sm:px-6 lg:px-8 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-primary/5 to-transparent" />

        <div className="max-w-7xl mx-auto relative">
          <div className="text-center mb-16">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-card border border-border mb-6">
              <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
              <span className="text-sm font-mono text-muted-foreground">CARACTERÍSTICAS</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">
              Todo lo que necesitas para tu negocio
            </h2>
            <p className="text-muted-foreground max-w-2xl mx-auto">
              Herramientas poderosas diseñadas para simplificar la gestión de tu inventario y aumentar tus ventas.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: ScanBarcode,
                title: 'Escaneo Rápido',
                description: 'Escanea códigos de barras y QR instantáneamente con la cámara de tu dispositivo.',
                color: 'primary',
              },
              {
                icon: Package,
                title: 'Control de Inventario',
                description: 'Gestiona stock, categorías, precios y proveedores desde un solo lugar.',
                color: 'green-500',
              },
              {
                icon: ShoppingCart,
                title: 'Punto de Venta',
                description: 'Procesa ventas rápidamente con un POS intuitivo y fácil de usar.',
                color: 'amber-500',
              },
              {
                icon: BarChart3,
                title: 'Reportes y Analytics',
                description: 'Visualiza métricas de ventas, productos más vendidos y tendencias.',
                color: 'violet-500',
              },
              {
                icon: Users,
                title: 'Multi-usuario',
                description: 'Crea cuentas para tu equipo con diferentes niveles de acceso.',
                color: 'blue-500',
              },
              {
                icon: Shield,
                title: 'Seguridad Total',
                description: 'Tus datos están protegidos con encriptación de nivel empresarial.',
                color: 'rose-500',
              },
            ].map((feature, index) => (
              <div
                key={feature.title}
                className={cn(
                  'group p-6 rounded-2xl border border-border bg-card hover:border-primary/30 transition-all duration-300 hover:-translate-y-1',
                  'opacity-0 animate-fade-up'
                )}
                style={{ animationDelay: `${index * 100}ms`, animationFillMode: 'forwards' }}
              >
                <div className={cn(
                  'w-12 h-12 rounded-xl flex items-center justify-center mb-4 transition-colors',
                  `bg-${feature.color}/20 group-hover:bg-${feature.color}/30`
                )}
                style={{
                  backgroundColor: `hsl(var(--${feature.color === 'primary' ? 'primary' : feature.color.split('-')[0]}) / 0.2)`,
                }}
                >
                  <feature.icon
                    className="w-6 h-6"
                    style={{
                      color: feature.color === 'primary'
                        ? 'hsl(var(--primary))'
                        : `var(--tw-${feature.color}, hsl(var(--primary)))`
                    }}
                  />
                </div>
                <h3 className="font-semibold text-lg mb-2">{feature.title}</h3>
                <p className="text-muted-foreground text-sm">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-24 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-card border border-border mb-6">
              <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse" />
              <span className="text-sm font-mono text-muted-foreground">PRECIOS</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">
              Planes para cada necesidad
            </h2>
            <p className="text-muted-foreground max-w-2xl mx-auto">
              Comienza gratis y escala según crece tu negocio.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {[
              {
                name: 'Básico',
                price: 'Gratis',
                description: 'Para emprendedores que inician',
                features: [
                  'Hasta 100 productos',
                  '1 usuario',
                  'Reportes básicos',
                  'Soporte por email',
                ],
                cta: 'Comenzar Gratis',
                popular: false,
              },
              {
                name: 'Pro',
                price: '$29',
                period: '/mes',
                description: 'Para negocios en crecimiento',
                features: [
                  'Productos ilimitados',
                  '5 usuarios',
                  'Analytics avanzados',
                  'Soporte prioritario',
                  'Exportar a Excel',
                  'API Access',
                ],
                cta: 'Comenzar Prueba',
                popular: true,
              },
              {
                name: 'Enterprise',
                price: '$99',
                period: '/mes',
                description: 'Para grandes operaciones',
                features: [
                  'Todo en Pro',
                  'Usuarios ilimitados',
                  'Multi-sucursal',
                  'Soporte 24/7',
                  'Integraciones custom',
                  'SLA garantizado',
                ],
                cta: 'Contactar Ventas',
                popular: false,
              },
            ].map((plan, index) => (
              <div
                key={plan.name}
                className={cn(
                  'relative p-6 rounded-2xl border transition-all duration-300',
                  plan.popular
                    ? 'border-primary bg-card scale-105 shadow-xl shadow-primary/10'
                    : 'border-border bg-card hover:border-primary/30'
                )}
              >
                {plan.popular && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full bg-primary text-primary-foreground text-xs font-medium">
                    Más Popular
                  </div>
                )}

                <div className="text-center mb-6">
                  <h3 className="font-semibold text-lg mb-2">{plan.name}</h3>
                  <div className="flex items-baseline justify-center gap-1">
                    <span className="text-4xl font-bold font-mono">{plan.price}</span>
                    {plan.period && <span className="text-muted-foreground">{plan.period}</span>}
                  </div>
                  <p className="text-sm text-muted-foreground mt-2">{plan.description}</p>
                </div>

                <ul className="space-y-3 mb-6">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex items-center gap-3 text-sm">
                      <Check className="w-4 h-4 text-primary shrink-0" />
                      <span>{feature}</span>
                    </li>
                  ))}
                </ul>

                <button
                  className={cn(
                    'w-full py-3 rounded-xl font-medium transition-all',
                    plan.popular
                      ? 'bg-primary text-primary-foreground hover:bg-primary/90 shadow-lg shadow-primary/20'
                      : 'bg-card border border-border hover:bg-accent'
                  )}
                >
                  {plan.cta}
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section id="testimonials" className="py-24 px-4 sm:px-6 lg:px-8 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-primary/5 to-transparent" />

        <div className="max-w-7xl mx-auto relative">
          <div className="text-center mb-16">
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-card border border-border mb-6">
              <Star className="w-4 h-4 text-amber-500 fill-amber-500" />
              <span className="text-sm font-mono text-muted-foreground">TESTIMONIOS</span>
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">
              Lo que dicen nuestros usuarios
            </h2>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {[
              {
                name: 'María González',
                role: 'Dueña de Tienda',
                content: 'ScanStock transformó la manera en que manejo mi inventario. Ahora todo es más rápido y organizado.',
                avatar: 'MG',
              },
              {
                name: 'Carlos Rodríguez',
                role: 'Gerente de Almacén',
                content: 'El escaneo de productos es increíblemente rápido. Redujimos los errores de inventario en un 90%.',
                avatar: 'CR',
              },
              {
                name: 'Ana Martínez',
                role: 'Emprendedora',
                content: 'La mejor inversión para mi negocio. El soporte es excelente y la app es muy intuitiva.',
                avatar: 'AM',
              },
            ].map((testimonial, index) => (
              <div
                key={testimonial.name}
                className="p-6 rounded-2xl border border-border bg-card"
              >
                <div className="flex items-center gap-1 mb-4">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-4 h-4 text-amber-500 fill-amber-500" />
                  ))}
                </div>
                <p className="text-muted-foreground mb-6">&ldquo;{testimonial.content}&rdquo;</p>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-primary font-medium text-sm">
                    {testimonial.avatar}
                  </div>
                  <div>
                    <p className="font-medium text-sm">{testimonial.name}</p>
                    <p className="text-xs text-muted-foreground">{testimonial.role}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 px-4 sm:px-6 lg:px-8">
        <div className="max-w-4xl mx-auto">
          <div className="relative p-8 sm:p-12 rounded-3xl border border-primary/20 bg-gradient-to-br from-primary/10 via-card to-card overflow-hidden">
            {/* Background pattern */}
            <div className="absolute inset-0 bg-barcode opacity-10" />
            <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-primary/50 to-transparent" />

            <div className="relative text-center">
              <h2 className="text-3xl sm:text-4xl font-bold mb-4">
                ¿Listo para optimizar tu negocio?
              </h2>
              <p className="text-muted-foreground mb-8 max-w-xl mx-auto">
                Únete a miles de negocios que ya usan ScanStock para gestionar su inventario de manera inteligente.
              </p>

              <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                <Link
                  href="/download"
                  className="inline-flex items-center gap-2 px-8 py-4 rounded-xl bg-primary text-primary-foreground font-semibold hover:bg-primary/90 transition-all shadow-lg shadow-primary/20 group"
                >
                  <Download className="w-5 h-5" />
                  Descargar Ahora
                  <ArrowRight className="w-4 h-4 transition-transform group-hover:translate-x-1" />
                </Link>
                <Link
                  href="/login"
                  className="inline-flex items-center gap-2 px-8 py-4 rounded-xl border border-border bg-card hover:bg-accent transition-colors"
                >
                  Acceso Admin
                  <ChevronRight className="w-4 h-4" />
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-12">
            <div className="col-span-2 md:col-span-1">
              <Link href="/" className="flex items-center gap-2 mb-4">
                <Image
                  src="/logo.png"
                  alt="ScanStock"
                  width={72}
                  height={72}
                  className="w-[72px] h-[72px] object-contain"
                />
                <span className="font-bold text-2xl">ScanStock</span>
              </Link>
              <p className="text-sm text-muted-foreground">
                La solución completa para gestión de inventario y punto de venta.
              </p>
            </div>

            <div>
              <h4 className="font-semibold mb-4">Producto</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#features" className="hover:text-foreground transition-colors">Características</a></li>
                <li><a href="#pricing" className="hover:text-foreground transition-colors">Precios</a></li>
                <li><Link href="/download" className="hover:text-foreground transition-colors">Descargar</Link></li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold mb-4">Empresa</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-foreground transition-colors">Acerca de</a></li>
                <li><a href="#" className="hover:text-foreground transition-colors">Blog</a></li>
                <li><a href="#" className="hover:text-foreground transition-colors">Contacto</a></li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold mb-4">Legal</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-foreground transition-colors">Privacidad</a></li>
                <li><a href="#" className="hover:text-foreground transition-colors">Términos</a></li>
              </ul>
            </div>
          </div>

          <div className="pt-8 border-t border-border flex flex-col sm:flex-row items-center justify-between gap-4">
            <p className="text-sm text-muted-foreground">
              © 2024 ScanStock. Todos los derechos reservados.
            </p>
            <p className="text-xs text-muted-foreground font-mono">
              v2.0.0
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}
