// Basic handler compatible with API Gateway proxy integration.
export const handler = async (event) => {
  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      message: "Hello from Node.js Lambda!",
      path: event?.path ?? event?.rawPath ?? null,
    }),
  };
};
