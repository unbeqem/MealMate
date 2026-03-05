// Deno Edge Function — proxies requests to Spoonacular API.
// Reads SPOONACULAR_API_KEY from environment; never exposes it to the client.
// Accepts POST with JSON body: { path: string, params: Record<string, unknown> }
// Returns upstream Spoonacular JSON and status code faithfully (including 402 quota errors).

Deno.serve(async (req: Request) => {
  try {
    const { path, params } = await req.json() as {
      path: string;
      params?: Record<string, unknown>;
    };

    const apiKey = Deno.env.get('SPOONACULAR_API_KEY');
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: 'SPOONACULAR_API_KEY not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const url = new URL(`https://api.spoonacular.com${path}`);
    url.searchParams.set('apiKey', apiKey);

    // Append all caller-supplied params as query string values
    Object.entries(params ?? {}).forEach(([k, v]) =>
      url.searchParams.set(k, String(v))
    );

    const upstream = await fetch(url.toString(), { method: 'GET' });
    const data = await upstream.json();

    // Return upstream status faithfully — 402 (quota exhausted) must reach the Flutter client
    return new Response(JSON.stringify(data), {
      status: upstream.status,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: `Proxy error: ${message}` }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
