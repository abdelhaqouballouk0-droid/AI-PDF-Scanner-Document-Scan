import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service | Sharkstack Developments",
  description:
    "Terms of Service covering all Sharkstack Developments applications, on all platforms.",
};

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mb-10">
      <h2 className="mb-3 text-xl font-semibold text-foreground">{title}</h2>
      <div className="space-y-4 text-[15px] leading-relaxed text-foreground/90">
        {children}
      </div>
    </section>
  );
}

export default function TermsOfService() {
  return (
    <article className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-3xl font-bold">Terms of Service</h1>
      <p className="mt-2 text-muted">
        Covering all Sharkstack Developments applications, on all platforms.
      </p>
      <p className="mt-1 text-sm text-muted">Last updated 24 September 2026</p>

      <div className="mt-10 space-y-4 text-[15px] leading-relaxed text-foreground/90">
        <p>
          These Terms of Service (&quot;Terms&quot;) govern your use of the applications provided
          by Sharkstack Developments (&quot;we&quot;, &quot;us&quot;), including AI PDF
          Scanner-Document Scan. By downloading, installing or using any of our applications, you
          agree to these Terms. If you do not agree, please do not use the application.
        </p>
      </div>

      <Section title="Use of the Service">
        <p>
          You may use the application for personal or business document scanning, conversion,
          editing, signing and related productivity purposes, in accordance with these Terms and
          applicable law. You are responsible for the documents you scan, import, edit or share
          through the application, and for making sure you have the right to do so.
        </p>
      </Section>

      <Section title="AI and third-party features">
        <p>
          Certain features (summarising a document, chatting about it, or classifying it, as well
          as converting a file between formats) rely on a third-party or self-hosted service that
          you configure yourself in the application&apos;s Settings. We do not operate these
          services. Your use of a configured AI or conversion service is also subject to that
          service&apos;s own terms, and you are responsible for choosing a service you trust. See
          our{" "}
          <a href="/privacy-policy" className="text-primary hover:underline">
            Privacy Policy
          </a>{" "}
          for details on what is sent to these services and how you can decline to use them.
        </p>
      </Section>

      <Section title="Your content">
        <p>
          You retain all rights to the documents and content you process through the application.
          We do not claim ownership over your documents. Documents you scan or import are stored
          on your own device unless a feature you use explicitly uploads a file to a service you
          have configured, as described in the Privacy Policy.
        </p>
      </Section>

      <Section title="Acceptable use">
        <p>You agree not to use the application to:</p>
        <ul className="list-disc space-y-1 pl-6">
          <li>Violate any applicable law or regulation.</li>
          <li>Infringe the intellectual property or privacy rights of others.</li>
          <li>
            Process, store or transmit unlawful, harmful, or abusive content through the
            application or any service you connect it to.
          </li>
          <li>
            Attempt to reverse engineer, disrupt, or gain unauthorized access to the application
            or its infrastructure.
          </li>
        </ul>
      </Section>

      <Section title="Purchases and subscriptions">
        <p>
          Some applications may offer optional paid features or subscriptions in the future.
          Where offered, pricing and billing terms will be displayed in the application before
          purchase and are processed through the applicable app store (Apple App Store or Google
          Play), subject to that store&apos;s own terms and refund policies.
        </p>
      </Section>

      <Section title="Disclaimer of warranties">
        <p>
          The application is provided &quot;as is&quot; and &quot;as available&quot;, without
          warranties of any kind, express or implied. We do not warrant that the application will
          be uninterrupted, error-free, or that any AI-generated output will be accurate or fit
          for a particular purpose. You should independently verify any important result before
          relying on it.
        </p>
      </Section>

      <Section title="Limitation of liability">
        <p>
          To the maximum extent permitted by law, Sharkstack Developments shall not be liable for
          any indirect, incidental, special, or consequential damages arising out of or related to
          your use of, or inability to use, the application.
        </p>
      </Section>

      <Section title="Changes to these Terms">
        <p>
          We may update these Terms from time to time. Continued use of the application after a
          change becomes effective constitutes acceptance of the revised Terms. If you do not
          agree to a change, your sole recourse is to stop using the application.
        </p>
      </Section>

      <Section title="Contact Us">
        <p>
          If you have any questions about these Terms, please contact us at{" "}
          <a href="mailto:Studentabdelhak@gmail.com" className="text-primary hover:underline">
            Studentabdelhak@gmail.com
          </a>
          .
        </p>
      </Section>
    </article>
  );
}
