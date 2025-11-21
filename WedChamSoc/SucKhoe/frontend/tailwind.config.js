/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './lib/**/*.{js,ts,jsx,tsx,mdx}',
    './contexts/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class', // Enable class-based dark mode
  theme: {
    extend: {
      colors: {
        // Primary colors for elderly-friendly design
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          200: '#bae6fd',
          300: '#7dd3fc',
          400: '#38bdf8',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
          800: '#075985',
          900: '#0c4a6e',
        },
        // Secondary colors
        secondary: {
          50: '#f8fafc',
          100: '#f1f5f9',
          200: '#e2e8f0',
          300: '#cbd5e1',
          400: '#94a3b8',
          500: '#64748b',
          600: '#475569',
          700: '#334155',
          800: '#1e293b',
          900: '#0f172a',
        },
        // Health status colors
        health: {
          normal: '#10b981',
          warning: '#f59e0b',
          danger: '#ef4444',
          info: '#3b82f6',
        },
        // Elderly-friendly colors
        elderly: {
          bg: '#fefefe',
          text: '#1f2937',
          'text-light': '#6b7280',
          border: '#e5e7eb',
          'card-bg': '#ffffff',
          'hover-bg': '#f9fafb',
        },
        // Dark mode colors
        dark: {
          bg: '#1e1e1e',
          text: '#ffffff',
          'text-light': '#d1d5db',
          border: '#374151',
          'card-bg': '#2d2d2d',
          'hover-bg': '#374151',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Inter', 'system-ui', 'sans-serif'],
      },
      fontSize: {
        // Larger font sizes for elderly users
        'xs': ['0.75rem', { lineHeight: '1rem' }],
        'sm': ['0.875rem', { lineHeight: '1.25rem' }],
        'base': ['1rem', { lineHeight: '1.5rem' }],
        'lg': ['1.125rem', { lineHeight: '1.75rem' }],
        'xl': ['1.25rem', { lineHeight: '1.75rem' }],
        '2xl': ['1.5rem', { lineHeight: '2rem' }],
        '3xl': ['1.875rem', { lineHeight: '2.25rem' }],
        '4xl': ['2.25rem', { lineHeight: '2.5rem' }],
        '5xl': ['3rem', { lineHeight: '1' }],
        '6xl': ['3.75rem', { lineHeight: '1' }],
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
        '128': '32rem',
      },
      borderRadius: {
        'xl': '1rem',
        '2xl': '1.5rem',
        '3xl': '2rem',
      },
      boxShadow: {
        'soft': '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
        'card': '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
        'card-hover': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
        'slide-down': 'slideDown 0.3s ease-out',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        slideDown: {
          '0%': { transform: 'translateY(-10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
      screens: {
        'xs': '475px',
        '3xl': '1600px',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms')({
      strategy: 'class',
    }),
    require('@tailwindcss/typography'),
    // Custom plugin for elderly-friendly utilities
    function({ addUtilities, theme }) {
      const newUtilities = {
        '.text-elderly': {
          fontSize: theme('fontSize.lg[0]'),
          lineHeight: theme('fontSize.lg[1].lineHeight'),
          color: theme('colors.elderly.text'),
        },
        '.text-elderly-light': {
          fontSize: theme('fontSize.base[0]'),
          lineHeight: theme('fontSize.base[1].lineHeight'),
          color: theme('colors.elderly.text-light'),
        },
        '.btn-elderly': {
          padding: theme('spacing.4') + ' ' + theme('spacing.6'),
          fontSize: theme('fontSize.lg[0]'),
          lineHeight: theme('fontSize.lg[1].lineHeight'),
          fontWeight: theme('fontWeight.medium'),
          borderRadius: theme('borderRadius.lg'),
          transition: 'all 0.2s ease-in-out',
        },
        '.card-elderly': {
          backgroundColor: theme('colors.elderly.card-bg'),
          borderRadius: theme('borderRadius.xl'),
          boxShadow: theme('boxShadow.card'),
          border: '1px solid ' + theme('colors.elderly.border'),
          padding: theme('spacing.6'),
        },
        '.input-elderly': {
          fontSize: theme('fontSize.lg[0]'),
          lineHeight: theme('fontSize.lg[1].lineHeight'),
          padding: theme('spacing.4'),
          borderRadius: theme('borderRadius.lg'),
          border: '2px solid ' + theme('colors.elderly.border'),
          '&:focus': {
            borderColor: theme('colors.primary.500'),
            boxShadow: '0 0 0 3px ' + theme('colors.primary.100'),
          },
        },
      };
      
      addUtilities(newUtilities);
    },
  ],
};
