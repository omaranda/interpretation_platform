import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Call Center Platform',
  description: 'Professional call center management system',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
