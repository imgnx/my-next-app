import "./styles.css";

export default function RootLayout({ children }) {
  return (
    <>
      <head></head>
      <body>{children}</body>
    </>
  );
}
