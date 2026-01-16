import { describe, it, expect } from 'vitest'
import { cn } from '../lib/utils'

describe('cn (className utility)', () => {
  it('combina clases simples', () => {
    const result = cn('class1', 'class2')
    expect(result).toBe('class1 class2')
  })

  it('maneja clases condicionales', () => {
    const isActive = true
    const isDisabled = false

    const result = cn(
      'base-class',
      isActive && 'active',
      isDisabled && 'disabled'
    )

    expect(result).toBe('base-class active')
    expect(result).not.toContain('disabled')
  })

  it('fusiona clases de Tailwind correctamente', () => {
    // twMerge deberia resolver conflictos
    const result = cn('px-4 py-2', 'px-6')
    expect(result).toBe('py-2 px-6')
  })

  it('maneja arrays de clases', () => {
    const result = cn(['class1', 'class2'], 'class3')
    expect(result).toBe('class1 class2 class3')
  })

  it('ignora valores falsy', () => {
    const result = cn('class1', null, undefined, false, '', 'class2')
    expect(result).toBe('class1 class2')
  })

  it('maneja objetos de clases', () => {
    const result = cn({
      'active': true,
      'disabled': false,
      'highlighted': true,
    })

    expect(result).toContain('active')
    expect(result).toContain('highlighted')
    expect(result).not.toContain('disabled')
  })

  it('combina multiples tipos de inputs', () => {
    const result = cn(
      'base',
      ['array-class'],
      { 'object-class': true },
      true && 'conditional'
    )

    expect(result).toContain('base')
    expect(result).toContain('array-class')
    expect(result).toContain('object-class')
    expect(result).toContain('conditional')
  })

  it('resuelve conflictos de colores de Tailwind', () => {
    const result = cn('bg-red-500', 'bg-blue-500')
    expect(result).toBe('bg-blue-500')
  })

  it('resuelve conflictos de spacing', () => {
    const result = cn('m-4', 'm-8')
    expect(result).toBe('m-8')
  })

  it('mantiene clases no conflictivas', () => {
    const result = cn('text-white', 'bg-black', 'p-4', 'rounded-lg')
    expect(result).toBe('text-white bg-black p-4 rounded-lg')
  })
})
