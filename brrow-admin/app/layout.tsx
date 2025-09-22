import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Toaster } from "sonner";
import AdminLayout from '../components/AdminLayout';

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Shaiitech Founder Panel | Brrow Admin",
  description: "Comprehensive admin dashboard for Brrow marketplace",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-gray-950 text-gray-100 antialiased`}>
        <AdminLayout>
          {children}
        </AdminLayout>
        <Toaster position="top-right" richColors />
      </body>
    </html>
  );
}