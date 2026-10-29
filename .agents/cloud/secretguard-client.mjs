function safeError(error, secretName, secretValue) {
  const fallback = `secret-guard: request failed for variable '${secretName}'.`;
  try {
    let message = error instanceof Error ? error.message : String(error);
    if (!message.trim()) return fallback;
    let mentionsSecret = false;
    for (const value of [secretValue, secretValue.trim()]) {
      if (value) {
        mentionsSecret ||= message.includes(value);
        message = message.split(value).join('<redacted>');
      }
    }
    message = message.replace(/\b(?:sk|rk|pk|sess|xoxb|xoxp|ghp|gho|github_pat|key|token|secret|api[_-]?key)[-_:=][A-Za-z0-9._~+/=-]{6,}|\b(?:api[_-]?key|access[_-]?token|refresh[_-]?token|id[_-]?token|password|credential|authorization|token|secret)\s*[=:]\s*["']?[A-Za-z0-9._~+/=-]{6,}/gi, '<redacted>');
    message = message.replace(/\bAKIA[A-Z0-9]{16}\b|\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/g, '<redacted>');
    if (/\bBearer\b/i.test(message) || mentionsSecret) return '<error message withheld: it referenced the auth header>';
    return `secret-guard: ${message}`;
  } catch {
    return fallback;
  }
}

export async function invokeSecretGuard({ uri, secretName, method = 'GET', headers = {}, body }) {
  let secret = '';
  try {
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(secretName)) throw new Error('secret-guard: secret variable name is invalid.');
    const rawSecret = process.env[secretName];
    if (typeof rawSecret !== 'string' || !rawSecret.trim()) {
      throw new Error(`secret-guard: variable '${secretName}' is empty or missing.`);
    }
    secret = rawSecret.trim();
    if (/[\u0000-\u001f\u007f]/.test(secret)) {
      throw new Error(`secret-guard: variable '${secretName}' contains a character illegal in an HTTP header.`);
    }
    const bodyText = body === undefined ? '' : JSON.stringify(body);
    if (bodyText.includes(secret)) throw new Error('secret-guard: request contained credential material.');
    const response = await fetch(uri, {
      method,
      headers: { ...headers, Authorization: `Bearer ${secret}` },
      body: body === undefined ? undefined : bodyText,
    });
    if (!response.ok) throw new Error(`secret-guard: HTTP ${response.status}.`);
    const result = await response.json();
    if (JSON.stringify(result)?.includes(secret)) {
      throw new Error('<error message withheld: response contained credential material>');
    }
    return result;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (message === '<error message withheld: response contained credential material>') {
      throw new Error(message);
    }
    throw new Error(safeError(error, secretName, secret));
  }
}
