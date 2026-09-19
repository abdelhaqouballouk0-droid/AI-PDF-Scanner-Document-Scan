import Image from "next/image";
import Link from "next/link";

const features = [
  {
    title: "Scan documents",
    description: "Automatic edge detection and multi-page capture, turned into a clean PDF instantly.",
  },
  {
    title: "PDF toolkit",
    description: "Merge, split, compress, protect, rotate, reorganize and convert your PDFs on the go.",
  },
  {
    title: "Text recognition (OCR)",
    description: "Turn scanned pages and images into searchable, copyable text — fully on-device.",
  },
  {
    title: "E-signature",
    description: "Draw a signature once and stamp it onto any document in a single tap.",
  },
  {
    title: "AI assistant",
    description: "Summarize, chat with, or automatically classify your documents.",
  },
  {
    title: "Your files stay yours",
    description: "Scanned documents live on your device. Nothing is uploaded unless a feature you use requires it.",
  },
];

export default function Home() {
  return (
    <div>
      <section className="mx-auto flex max-w-4xl flex-col items-center gap-6 px-6 py-20 text-center">
        <Image
          src="/app-icon.png"
          alt="AI PDF Scanner-Document Scan"
          width={96}
          height={96}
          className="rounded-2xl shadow-lg shadow-primary/20"
        />
        <h1 className="text-3xl font-bold sm:text-4xl">AI PDF Scanner-Document Scan</h1>
        <p className="max-w-2xl text-muted">
          Scan, convert, edit, sign and chat with your documents — built by Sharkstack Developments.
        </p>
        <Link
          href="/privacy-policy"
          className="mt-2 rounded-full bg-primary px-6 py-2.5 text-sm font-semibold text-white transition hover:bg-primary-dark"
        >
          Read our Privacy Policy
        </Link>
      </section>

      <section className="mx-auto max-w-4xl px-6 pb-20">
        <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature) => (
            <div
              key={feature.title}
              className="rounded-2xl border border-divider bg-surface p-6 shadow-sm"
            >
              <h2 className="mb-2 font-semibold text-foreground">{feature.title}</h2>
              <p className="text-sm text-muted">{feature.description}</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
