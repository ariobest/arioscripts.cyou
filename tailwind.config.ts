import type { Config } from "tailwindcss";
const config: Config = { content: ["./app/**/*.{js,ts,jsx,tsx,mdx}", "./components/**/*.{js,ts,jsx,tsx,mdx}"], theme: { extend: { colors: { ink: "#090b10", panel: "#11141c", line: "#242936", accent: "#7c9cff" }, boxShadow: { glow: "0 0 40px rgba(124,156,255,.12)" } } }, plugins: [] };
export default config;