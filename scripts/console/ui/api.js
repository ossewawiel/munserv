// Small fetch helpers shared by every section. A failed request never throws into the caller's
// render path silently -- it raises `ApiFailure` so app.js can show the "poll failed" banner
// instead of leaving the page frozen on stale data.

export class ApiFailure extends Error {}

export async function apiGet(path) {
  let res;
  try {
    res = await fetch(path);
  } catch (e) {
    throw new ApiFailure(e.message);
  }
  let data;
  try {
    data = await res.json();
  } catch (e) {
    throw new ApiFailure('bad response from ' + path);
  }
  if (!res.ok || data.ok === false) {
    throw new ApiFailure(data.error || ('request failed: ' + path));
  }
  return data;
}

export async function apiPost(path, body) {
  let res;
  try {
    res = await fetch(path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body || {}),
    });
  } catch (e) {
    throw new ApiFailure(e.message);
  }
  let data;
  try {
    data = await res.json();
  } catch (e) {
    throw new ApiFailure('bad response from ' + path);
  }
  if (!res.ok || data.ok === false) {
    throw new ApiFailure(data.error || ('request failed: ' + path));
  }
  return data;
}

export function timeAgo(epochSeconds) {
  if (!epochSeconds) return 'never';
  const seconds = Math.max(0, Math.round(Date.now() / 1000 - epochSeconds));
  if (seconds < 5) return 'just now';
  if (seconds < 60) return seconds + 's ago';
  const minutes = Math.round(seconds / 60);
  if (minutes < 60) return minutes + 'm ago';
  const hours = Math.round(minutes / 60);
  return hours + 'h ago';
}
