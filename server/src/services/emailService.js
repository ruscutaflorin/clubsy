import config from "../config.js";

// A sender is `{ send({ to, subject, text }) }` returning a promise.
export function createConsoleSender() {
  return {
    async send({ to, subject, text }) {
      console.log(`[email] to=${to} subject=${subject}\n${text}`);
    },
  };
}

export function createResendSender({ apiKey, from, fetchImpl = fetch }) {
  return {
    async send({ to, subject, text }) {
      const res = await fetchImpl("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ from, to: [to], subject, text }),
      });
      if (!res.ok) {
        throw new Error(`Resend responded with ${res.status}`);
      }
    },
  };
}

let override = null;
let cached = null;

// Tests inject a fake sender; pass null to restore the configured one.
export function setEmailSender(sender) {
  override = sender;
}

export function getEmailSender() {
  if (override) return override;
  if (!cached) {
    cached = config.RESEND_API_KEY
      ? createResendSender({ apiKey: config.RESEND_API_KEY, from: config.EMAIL_FROM })
      : createConsoleSender();
  }
  return cached;
}
