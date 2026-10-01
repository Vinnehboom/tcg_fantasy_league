const apiRoot = 'https://api.notion.com/v1';
const apiVersion = '2022-06-28';
const maxAttempts = 4;
const retryableStatuses = new Set([409, 429, 500, 502, 503, 504]);

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

export class NotionError extends Error {
  constructor(status, payload) {
    super(payload?.message ?? `Notion request failed with status ${status}`);
    this.name = 'NotionError';
    this.status = status;
    this.code = payload?.code;
  }
}

export class NotionClient {
  #token;
  #minIntervalMs;
  #queue = Promise.resolve();

  constructor({ token, requestsPerSecond = 3 }) {
    if (!token) {
      throw new Error('NOTION_TOKEN is not set. Copy .env.example to .env and add your integration token.');
    }

    this.#token = token;
    this.#minIntervalMs = Math.ceil(1000 / requestsPerSecond);
  }

  request(method, path, body) {
    const response = this.#queue.then(() => this.#send(method, path, body));
    const spacer = () => wait(this.#minIntervalMs);

    this.#queue = response.then(spacer, spacer);

    return response;
  }

  async #send(method, path, body, attempt = 1) {
    const response = await fetch(`${apiRoot}${path}`, {
      method,
      headers: {
        Authorization: `Bearer ${this.#token}`,
        'Notion-Version': apiVersion,
        'Content-Type': 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });

    if (response.ok) return response.json();

    const payload = await response.json().catch(() => ({}));

    if (attempt < maxAttempts && retryableStatuses.has(response.status)) {
      await wait(this.#retryDelayMs(response, attempt));
      return this.#send(method, path, body, attempt + 1);
    }

    throw new NotionError(response.status, payload);
  }

  #retryDelayMs(response, attempt) {
    const retryAfter = Number(response.headers.get('retry-after'));

    if (Number.isFinite(retryAfter) && retryAfter > 0) return retryAfter * 1000;

    return this.#minIntervalMs * 2 ** attempt;
  }

  async #collect(method, path, body) {
    const results = [];
    let cursor;

    do {
      const page = await this.request(method, path, { ...body, start_cursor: cursor });
      results.push(...page.results);
      cursor = page.has_more ? page.next_cursor : undefined;
    } while (cursor);

    return results;
  }

  createDatabase(body) {
    return this.request('POST', '/databases', body);
  }

  retrieveDatabase(databaseId) {
    return this.request('GET', `/databases/${databaseId}`);
  }

  queryDatabase(databaseId, body = {}) {
    return this.#collect('POST', `/databases/${databaseId}/query`, body);
  }

  createPage(body) {
    return this.request('POST', '/pages', body);
  }

  updatePage(pageId, body) {
    return this.request('PATCH', `/pages/${pageId}`, body);
  }

  async blockChildren(blockId) {
    const results = [];
    let cursor;

    do {
      const suffix = cursor ? `?start_cursor=${cursor}&page_size=100` : '?page_size=100';
      const page = await this.request('GET', `/blocks/${blockId}/children${suffix}`);

      results.push(...page.results);
      cursor = page.has_more ? page.next_cursor : undefined;
    } while (cursor);

    return results;
  }

  appendBlocks(blockId, children) {
    return this.request('PATCH', `/blocks/${blockId}/children`, { children });
  }

  deleteBlock(blockId) {
    return this.request('DELETE', `/blocks/${blockId}`);
  }
}
