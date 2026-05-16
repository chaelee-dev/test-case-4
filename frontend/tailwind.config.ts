import type { Config } from "tailwindcss";

export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: "#5cb85c",
          hover: "#4cae4c",
        },
        secondary: "#373a3c",
        neutral: {
          bg: "#ffffff",
          text: "#373a3c",
          muted: "#aaaaaa",
        },
        border: "#e5e5e5",
        danger: "#b85c5c",
        warning: "#f0ad4e",
      },
      fontFamily: {
        sans: ['"source sans pro"', "system-ui", "sans-serif"],
        mono: ["ui-monospace", "monospace"],
      },
    },
  },
  plugins: [],
} satisfies Config;
