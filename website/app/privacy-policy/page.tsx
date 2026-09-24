import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy | Sharkstack Developments",
  description:
    "Privacy Policy covering all Sharkstack Developments applications, on all platforms.",
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

export default function PrivacyPolicy() {
  return (
    <article className="mx-auto max-w-3xl px-6 py-16">
      <h1 className="text-3xl font-bold">Privacy Policy</h1>
      <p className="mt-2 text-muted">
        Covering all Sharkstack Developments applications, on all platforms.
      </p>
      <p className="mt-1 text-sm text-muted">Last updated 24 September 2026</p>

      <div className="mt-10 space-y-4 text-[15px] leading-relaxed text-foreground/90">
        <p>
          At Sharkstack Developments we accept that privacy is important to all users. This
          Service is provided by Sharkstack Developments at no cost and is intended for use.
          This policy applies to use all application on all platforms to inform visitors
          regarding policies with the collection, use, and disclosure of Personal Information
          if anyone decided to use Application, or the Services.
        </p>
        <p>
          The terms used in this Privacy Policy have the same meanings as in Terms and
          Conditions, which is accessible at Sharkstack Developments Privacy Policy. If you use
          our Service, then you agree to the collection and use of information in relation to
          this policy. The Personal Information that we collect is used for providing and
          improving the Service.
        </p>
      </div>

      <Section title="Information Collection and Use">
        <p>
          For a better experience, while using our Service, We may require you to provide us
          with certain personally identifiable information. To personalize user experience —
          We may use your Non-Personal Information to understand demographics, customer
          interest, and other trends among our Users.
        </p>
      </Section>

      <Section title="Information we obtain from third-party sources">
        <p>
          Third-Party Social Networks includes Google Play Service, Facebook, Mopub, Admob &amp;
          Skyscanner. You may choose to connect to our Services via your social media account.
          Exactly what information we receive from your social media will depend on your social
          media privacy settings, but it would typically include your basic public profile
          information. Third party service providers. We may receive personal information about
          you from third-party sources.
        </p>
        <p>
          Advertising partners. From time to time, we may also receive personal information
          about you from other third-party sources. For example, if you clicked on an
          advertisement to direct you to one of another services we will be provided with
          information from which ad network and advertising campaign the install originated
          from.
        </p>
      </Section>

      <Section title="Documents and AI features">
        <p>Documents you scan or import are stored on your own device. They are not uploaded to us for storage.</p>
        <p>
          The app&apos;s AI features (summarising a document, chatting about it, or having it
          automatically categorised) are not powered by a service we operate. Instead, you
          configure, in the app&apos;s Settings, the address of an AI service to use — for
          example a provider such as OpenAI, Groq, or OpenRouter, or a model you run yourself
          (e.g. a self-hosted or local Ollama instance). When you use one of these features, the
          extracted text of the relevant document is sent directly from your device to that
          AI service to generate a response. We do not operate, choose, or have access to that
          service, and the text does not pass through or get stored on our own servers.
        </p>
        <p>
          Before any AI feature is used for the first time, the app shows a consent screen
          explaining what is sent and that it goes to the third-party service you have
          configured, with a clear option to accept or decline. If you decline, no document
          text is ever sent to an AI service, and every other feature of the app remains fully
          usable. You can change your choice at any time from Settings.
        </p>
        <p>
          Converting a file between formats, or scanning a page with no readable text layer,
          works the same way: it uses the conversion service address you configure in Settings
          (for example a self-hosted LibreOffice/Gotenberg instance, or a service such as
          CloudConvert). The file is uploaded directly from your device to that configured
          service for processing and is not routed through, or retained by, our own servers.
        </p>
        <p>These features are only ever started by you. If you do not configure or use them, nothing leaves your device.</p>
      </Section>

      <Section title="Log Data">
        <p>
          Our apps collect user analytic data which we use to improve the apps. The data
          contains contextual information about users, for example, coarse level location
          (country, city), device model and Android version.
        </p>
        <p>
          We want to inform you that whenever you use our Service, in a case of an error in the
          app. We collect data and information (through third party products) on your phone
          called Log Data. When you interact with us or use an Application our systems may
          automatically collect your unique User Device number and the dates and times of your
          use. This Log Data may include information such as your device Internet Protocol
          address, device name, operating system version, the configuration of the app when
          utilizing our Service, the time and date of your use of the Service, and other
          statistics.
        </p>
      </Section>

      <Section title="Service Providers">
        <p>We may employ third-party companies and individuals due to the following reasons:</p>
        <ul className="list-disc space-y-1 pl-6">
          <li>To facilitate our Service.</li>
          <li>To provide the Service on our behalf.</li>
          <li>To assist us in analyzing how our Service is used.</li>
        </ul>
        <p>
          We want to inform users of this Service that these third parties have access to your
          Personal Information. The reason is to perform the tasks assigned to them on our
          behalf. However, they are obligated not to disclose or use the information for any
          other purpose.
        </p>
      </Section>

      <Section title="Cookies">
        <p>
          Cookies are files with a small amount of data that are commonly used as anonymous
          unique identifiers. These are sent to your browser from the websites that you visit
          and are stored on your device&apos;s internal memory. We may collect information about
          your use of our Services through the use of cookies, pixels or similar technologies.
          For example, we may use this information to provide or improve our Services, for
          measurement and analytic to better understand how our services function and are used,
          or for internal operations. The app may use third party code and libraries that use
          &quot;cookies&quot; to collect information and improve their services. You have the
          option to either accept or refuse these cookies and know when a cookie is being sent
          to your device. If you choose to refuse our cookies, you may not be able to use some
          portions of this Service.
        </p>
      </Section>

      <Section title="Security">
        <p>
          We value your trust in providing us your Personal Information, thus we are striving to
          use commercially acceptable means of protecting it. We do not collect Personal
          Information, and we employ administrative, physical and electronic measures designed
          to protect your Non-Personal Information from unauthorized access and use. But
          remember that no method of transmission over the internet, or method of electronic
          storage is secure and reliable.
        </p>
      </Section>

      <Section title="Children's Privacy">
        <p>
          Our Service does not address anyone under the age of 13 (&quot;Children&quot;). We do
          not knowingly collect personally identifiable information from children under 13.
        </p>
      </Section>

      <Section title="Changes To This Privacy Policy">
        <p>
          We reserve the right to alter our privacy policy at any time. You must review this
          Policy on a regular basis to keep yourself apprised of any changes. If you do not
          agree to the modification to the policy your sole recourse is immediately stop to use
          all Applications.
        </p>
      </Section>

      <Section title="Contact Us">
        <p>
          If you have any questions or comments about this Policy or our privacy practices, or
          to report any violations of the Policy or abuse of an Application, please contact us
          at{" "}
          <a href="mailto:Studentabdelhak@gmail.com" className="text-primary hover:underline">
            Studentabdelhak@gmail.com
          </a>
          .
        </p>
      </Section>
    </article>
  );
}
