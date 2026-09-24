import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import Link from "next/link";
import Image from "next/image";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "AI PDF Scanner-Document Scan | Sharkstack Developments",
  description:
    "Scan, convert, sign and chat with your documents. Privacy policy and information for AI PDF Scanner-Document Scan, by Sharkstack Developments.",
  icons: {
    icon: "/app-icon.png",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col bg-background text-foreground">
        <header className="border-b border-divider bg-surface">
          <div className="mx-auto flex max-w-4xl items-center justify-between px-6 py-4">
            <Link href="/" className="flex items-center gap-3">
              <Image
                src="/app-icon.png"
                alt="AI PDF Scanner-Document Scan"
                width={36}
                height={36}
                className="rounded-lg"
              />
              <span className="font-semibold text-[15px] sm:text-base">
                AI PDF Scanner-Document Scan
              </span>
            </Link>
            <nav className="flex items-center gap-5 text-sm font-medium text-muted">
              <Link href="/" className="hover:text-primary">
                Home
              </Link>
              <Link href="/privacy-policy" className="hover:text-primary">
                Privacy Policy
              </Link>
              <Link href="/terms-of-service" className="hover:text-primary">
                Terms of Service
              </Link>
            </nav>
          </div>
        </header>

        <main className="flex-1">{children}</main>

        <footer className="border-t border-divider bg-surface">
          <div className="mx-auto flex max-w-4xl flex-col gap-2 px-6 py-8 text-sm text-muted sm:flex-row sm:items-center sm:justify-between">
            <p>&copy; {new Date().getFullYear()} Sharkstack Developments. All rights reserved.</p>
            <div className="flex gap-4">
              <Link href="/privacy-policy" className="hover:text-primary">
                Privacy Policy
              </Link>
              <Link href="/terms-of-service" className="hover:text-primary">
                Terms of Service
              </Link>
              <a href="mailto:Studentabdelhak@gmail.com" className="hover:text-primary">
                Contact
              </a>
            </div>
          </div>
        </footer>
      </body>
    </html>
  );
}
