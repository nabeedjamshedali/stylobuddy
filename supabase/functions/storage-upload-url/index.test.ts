import { assertEquals } from "jsr:@std/assert@1";
import { handleRequest } from "./index.ts";

function postRequest(body: unknown, authHeader?: string): Request {
  const headers = new Headers({ "content-type": "application/json" });
  if (authHeader) headers.set("Authorization", authHeader);
  return new Request("https://example.com/storage-upload-url", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

Deno.test(
  "F15_A17_handler a request with a valid token returns 200 with a signed URL whose path is uid/itemId.jpg",
  async () => {
    const response = await handleRequest(postRequest({ itemId: "item-1" }, "Bearer good-token"), {
      verify: () => Promise.resolve("uid-123"),
      sign: (path) =>
        Promise.resolve({ uploadUrl: `https://signed.example/${path}?x`, path }),
    });

    assertEquals(response.status, 200);
    const data = await response.json();
    assertEquals(data.path, "uid-123/item-1.jpg");
    assertEquals(data.uploadUrl, "https://signed.example/uid-123/item-1.jpg?x");
  },
);

Deno.test(
  "F15_A18_handler a request with a missing/invalid token returns 401 and never calls sign()",
  async () => {
    let signCalled = false;
    const response = await handleRequest(postRequest({ itemId: "item-1" }), {
      verify: () => Promise.resolve(null),
      sign: (path) => {
        signCalled = true;
        return Promise.resolve({ uploadUrl: "should-not-happen", path });
      },
    });

    assertEquals(response.status, 401);
    assertEquals(signCalled, false);
  },
);

Deno.test(
  "F15_A20_handler the signed path's uid segment always comes from the verified token, never from the request body",
  async () => {
    let capturedPath = "";
    await handleRequest(
      postRequest({ itemId: "item-1", uid: "attacker-uid" }, "Bearer good-token"),
      {
        verify: () => Promise.resolve("real-uid-from-token"),
        sign: (path) => {
          capturedPath = path;
          return Promise.resolve({ uploadUrl: `https://signed.example/${path}`, path });
        },
      },
    );

    assertEquals(capturedPath, "real-uid-from-token/item-1.jpg");
  },
);

Deno.test(
  "F15_edge_handler a missing itemId in the request body returns 400, not a signed URL for an empty item id",
  async () => {
    const response = await handleRequest(postRequest({}, "Bearer good-token"), {
      verify: () => Promise.resolve("uid-123"),
      sign: (): Promise<never> => {
        throw new Error("sign() must not be called when itemId is missing");
      },
    });

    assertEquals(response.status, 400);
  },
);
