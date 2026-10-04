import { jest } from "@jest/globals";
import { createResendSender } from "../services/emailService.js";

describe("createResendSender", () => {
  const mail = { to: "ana@example.com", subject: "Hi", text: "Your code is 123456" };

  it("POSTs to the Resend API with the key and sender", async () => {
    const fetchImpl = jest.fn(async () => ({ ok: true, status: 200 }));
    await createResendSender({ apiKey: "re_key", from: "Clubsy <a@b.c>", fetchImpl }).send(mail);

    const [url, init] = fetchImpl.mock.calls[0];
    expect(url).toBe("https://api.resend.com/emails");
    expect(init.method).toBe("POST");
    expect(init.headers.Authorization).toBe("Bearer re_key");
    expect(JSON.parse(init.body)).toEqual({
      from: "Clubsy <a@b.c>",
      to: ["ana@example.com"],
      subject: "Hi",
      text: "Your code is 123456",
    });
  });

  it("rejects when Resend answers with an error status", async () => {
    const fetchImpl = jest.fn(async () => ({ ok: false, status: 422 }));
    await expect(createResendSender({ apiKey: "k", from: "f", fetchImpl }).send(mail)).rejects.toThrow(
      "422"
    );
  });
});
