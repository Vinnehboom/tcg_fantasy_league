export class Router {
  #routes = [];

  add(method, pattern, handler) {
    this.#routes.push({ method, pattern, handler });

    return this;
  }

  get(pattern, handler) {
    return this.add('GET', pattern, handler);
  }

  post(pattern, handler) {
    return this.add('POST', pattern, handler);
  }

  match(method, pathname) {
    for (const route of this.#routes) {
      if (route.method !== method) continue;

      const found = route.pattern.exec(pathname);
      if (found) return { handler: route.handler, params: found.groups ?? {} };
    }

    return null;
  }
}

export async function readFormBody(request, limitBytes = 1_000_000) {
  const chunks = [];
  let size = 0;

  for await (const chunk of request) {
    size += chunk.length;

    if (size > limitBytes) throw new Error('The submitted form is too large.');

    chunks.push(chunk);
  }

  return new URLSearchParams(Buffer.concat(chunks).toString('utf8'));
}
