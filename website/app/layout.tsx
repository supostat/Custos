import "./global.css";
import { RootProvider } from "fumadocs-ui/provider/next";
import { Inter } from "next/font/google";
import type { ReactNode } from "react";
import type { Metadata } from "next";
import { Analytics } from "@vercel/analytics/react";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: {
    template: "%s | Custos",
    default: "Custos - Plugin-based Authentication for Rails",
  },
  description:
    "Custos is a plugin-based authentication library for Ruby on Rails. Modular, secure, and designed for production.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en" className={inter.className} suppressHydrationWarning>
      <body className="flex min-h-screen flex-col">
        <RootProvider>{children}</RootProvider>
        <Analytics />
      </body>
    </html>
  );
}
