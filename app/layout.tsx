import type { Metadata } from "next";
import "./globals.css";
import Navbar from "@/components/navbar";
export const metadata: Metadata = { title: "Ario Scripts — Scripts worth sharing", description: "Discover, publish and share scripts with the Ario community.", metadataBase: new URL("https://arioscripts.cyou") };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="en"><body><Navbar/><main className="min-h-[80vh]">{children}</main><footer className="border-t border-line mt-24"><div className="max-w-7xl mx-auto px-5 py-8 flex flex-col sm:flex-row gap-3 justify-between text-sm muted"><span>© {new Date().getFullYear()} Ario Scripts</span><span>Built for creators. Share responsibly.</span></div></footer></body></html> }