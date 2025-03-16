// app/layout.tsx
import { Inter } from "next/font/google";
import "/styles/stylesheet.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "My App",
  description: "A description of my app"
};

export default function RootLayout({ children }) {
  return (
    <>
      <head></head>
      <body className={inter.className}>{children}</body>
    </>
  );
}
