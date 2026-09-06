import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';
import { AppProvider } from '@/context/AppContext';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Legal Metrology (Packaged Commodities) Enforcement & Redressal Portal',
  description: 'Automated Legal Metrology Compliance & Enforcement System — Government of India',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.className} bg-[#EEF2F6] text-slate-900 antialiased`}>
        <AppProvider>{children}</AppProvider>
      </body>
    </html>
  );
}
